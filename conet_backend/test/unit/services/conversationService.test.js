/**
 * Unit tests – conversationService.js
 *
 * Coverage targets:
 *  ✓ createConversationService – UUID target, username target, self-message, not found
 *  ✓ getConversationsService   – empty list, populated list, unread count aggregation
 *  ✓ getMessagesService        – returns paged messages, supports cursor pagination
 *  ✓ sendMessageService        – success, not a participant, conversation not found
 *  ✓ markAsReadService         – updates unread messages belonging to other user
 *  ✓ searchUsersService        – returns filtered results, excludes self
 */

import { beforeEach, describe, expect, it, mock } from "bun:test";
import { TEST_USER, TEST_USER_B } from "../../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../../mocks/prismaMock.js";

mock.module("../../../config/prisma.js", () => ({ default: prismaMock }));
mock.module("../../../config/queue.js", () => ({
  notificationQueue: {
    add: mock(() => Promise.resolve({ id: "job-1" })),
  },
}));
mock.module("../../../config/constants.js", () => ({
  USER_SELECT_FIELDS: {
    id: true,
    email: true,
    first_name: true,
    last_name: true,
    username: true,
    profile_pic_url: true,
    user_role: true,
    is_verified: true,
  },
  UUID_REGEX:
    /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/,
}));
mock.module("../../../config/logger.js", () => ({
  default: {
    error: mock(() => undefined),
    info: mock(() => undefined),
  },
}));

import {
  createConversationService,
  getConversationsService,
  getMessagesService,
  markAsReadService,
  searchUsersService,
  sendMessageService,
} from "../../../services/conversationService.js";

// ─── Fixtures ──────────────────────────────────────────────────────────────

const CONV_ID = "cccccccc-cccc-cccc-cccc-cccccccccccc";

const mockOtherUser = {
  id: TEST_USER_B.id,
  email: TEST_USER_B.email,
  username: "bob",
  first_name: "Bob",
  last_name: "Jones",
  profile_pic_url: null,
  user_role: "user",
  is_verified: false,
};

const mockConversationRow = {
  id: CONV_ID,
  user_one: TEST_USER.id,
  user_two: TEST_USER_B.id,
  created_at: new Date("2025-01-01"),
  updated_at: new Date("2025-01-02"),
  messages_conversations_last_message_idTomessages: {
    content: "Hello!",
    media_urls: [],
  },
  conversation_members: [
    {
      user_id: TEST_USER.id,
      users: {
        id: TEST_USER.id,
        username: "alice",
      },
    },
    {
      user_id: TEST_USER_B.id,
      users: mockOtherUser,
    },
  ],
  _count: { unreadMessages: 0 },
};

beforeEach(() => {
  resetPrismaMocks();
});

// ─────────────────────────────────────────────────────────────────────────────
describe("createConversationService", () => {
  it("creates a new conversation between two different users", async () => {
    prismaMock.users.findUnique.mockResolvedValue(mockOtherUser);
    // Service uses findFirst+create (upsert can't target partial indexes)
    prismaMock.conversations.findFirst.mockResolvedValue(null);
    prismaMock.conversations.create.mockResolvedValue({
      id: CONV_ID,
      type: "direct",
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      updated_at: new Date(),
      conversation_members: [],
    });

    const result = await createConversationService(
      TEST_USER.id,
      TEST_USER_B.id,
    );

    expect(result.id).toBe(CONV_ID);
    expect(result.other_user).toEqual(mockOtherUser);
    expect(result.unread_count).toBe(0);
  });

  it("throws 400 when trying to create conversation with yourself", async () => {
    await expect(
      createConversationService(TEST_USER.id, TEST_USER.id),
    ).rejects.toMatchObject({
      message: "Cannot create conversation with yourself",
      statusCode: 400,
    });
  });

  it("resolves user by username when a non-UUID identifier is provided", async () => {
    // First findFirst resolves username → UUID; second findFirst checks existing conv
    prismaMock.users.findFirst.mockResolvedValueOnce({ id: TEST_USER_B.id });
    prismaMock.users.findUnique.mockResolvedValue(mockOtherUser);
    prismaMock.conversations.findFirst.mockResolvedValue(null);
    prismaMock.conversations.create.mockResolvedValue({
      id: CONV_ID,
      type: "direct",
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      updated_at: new Date(),
      conversation_members: [],
    });

    const result = await createConversationService(TEST_USER.id, "bob");

    expect(prismaMock.users.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { OR: [{ username: "bob" }, { email: "bob" }] },
      }),
    );
    expect(result.id).toBe(CONV_ID);
  });

  it("throws 404 when username lookup finds no user", async () => {
    prismaMock.users.findFirst.mockResolvedValue(null);

    await expect(
      createConversationService(TEST_USER.id, "ghost"),
    ).rejects.toMatchObject({
      message: "User not found",
      statusCode: 404,
    });
  });

  it("throws 404 when target UUID user does not exist", async () => {
    prismaMock.users.findUnique.mockResolvedValue(null);

    await expect(
      createConversationService(TEST_USER.id, TEST_USER_B.id),
    ).rejects.toMatchObject({
      message: "User not found",
      statusCode: 404,
    });
  });

  it("normalises user pair so user_one < user_two (alphabetical)", async () => {
    // user A > user B alphabetically → pair should be flipped
    const userA = "ffffffff-ffff-ffff-ffff-ffffffffffff";
    const userB = "00000000-0000-0000-0000-000000000001";

    prismaMock.users.findUnique.mockResolvedValue({ id: userA });
    prismaMock.conversations.findFirst.mockResolvedValue(null);
    prismaMock.conversations.create.mockResolvedValue({
      id: CONV_ID,
      type: "direct",
      user_one: userB,
      user_two: userA,
      updated_at: new Date(),
      conversation_members: [],
    });

    await createConversationService(userA, userB);

    // Service now uses create; check data payload contains the normalised pair
    const createCall = prismaMock.conversations.create.mock.calls[0][0];
    expect(createCall.data.user_one).toBe(userB);
    expect(createCall.data.user_two).toBe(userA);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("getConversationsService", () => {
  it("returns an empty array when user has no conversations", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([]);
    prismaMock.messages.groupBy.mockResolvedValue([]);

    const result = await getConversationsService(TEST_USER.id);

    expect(result).toEqual([]);
  });

  it("maps conversation rows and injects unread count", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([mockConversationRow]);
    prismaMock.messages.groupBy.mockResolvedValue([
      { conversation_id: CONV_ID, _count: { id: 3 } },
    ]);

    const result = await getConversationsService(TEST_USER.id);

    expect(result).toHaveLength(1);
    expect(result[0].unread_count).toBe(3);
    expect(result[0].last_message).toBe("Hello!");
  });

  it("sets unread_count to 0 for conversations with no unread messages", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([mockConversationRow]);
    prismaMock.messages.groupBy.mockResolvedValue([]); // no unread entries

    const result = await getConversationsService(TEST_USER.id);

    expect(result[0].unread_count).toBe(0);
  });

  it("returns conversations without messages (empty groups or new conversations)", async () => {
    const emptyConversationRow = {
      id: CONV_ID,
      type: "group",
      name: "New Group",
      group_image_url: null,
      created_by: TEST_USER.id,
      user_one: null,
      user_two: null,
      created_at: new Date("2025-01-01"),
      updated_at: new Date("2025-01-01"),
      messages_conversations_last_message_idTomessages: null, // No messages yet
      conversation_members: [
        {
          user_id: TEST_USER.id,
          users: {
            id: TEST_USER.id,
            username: "alice",
          },
          role: "admin",
        },
      ],
      _count: { unreadMessages: 0 },
    };

    prismaMock.conversations.findMany.mockResolvedValue([emptyConversationRow]);
    prismaMock.messages.groupBy.mockResolvedValue([]);

    const result = await getConversationsService(TEST_USER.id);

    expect(result).toHaveLength(1);
    expect(result[0].id).toBe(CONV_ID);
    expect(result[0].type).toBe("group");
    expect(result[0].name).toBe("New Group");
    expect(result[0].last_message).toBeNull();
    expect(result[0].last_message_media_urls).toEqual([]);
    expect(result[0].unread_count).toBe(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("getMessagesService", () => {
  it("returns mapped messages ordered newest first", async () => {
    const now = new Date();
    prismaMock.messages.findMany.mockResolvedValue([
      {
        id: "msg-1",
        conversation_id: CONV_ID,
        sender_id: TEST_USER.id,
        content: "Hi",
        created_at: now,
        is_read: true,
        media_urls: [],
      },
    ]);

    const result = await getMessagesService(CONV_ID, { limit: 20 });

    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content).toBe("Hi");
    expect(result.messages[0].is_read).toBe(true);
    expect(typeof result.messages[0].created_at).toBe("string"); // ISO string
    expect(result.hasMore).toBe(false);
    expect(result.nextBefore).toBeNull();
  });

  it("passes limit + 1 to Prisma findMany", async () => {
    prismaMock.messages.findMany.mockResolvedValue([]);

    await getMessagesService(CONV_ID, { limit: 5 });

    expect(prismaMock.messages.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ take: 6 }),
    );
  });

  it("applies created_at cursor when before is provided", async () => {
    const before = new Date("2026-02-23T10:00:00.000Z");
    prismaMock.messages.findMany.mockResolvedValue([]);

    await getMessagesService(CONV_ID, { limit: 5, before });

    expect(prismaMock.messages.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          conversation_id: CONV_ID,
          created_at: { lt: before },
        }),
      }),
    );
  });

  it("returns hasMore true and nextBefore from oldest returned item", async () => {
    prismaMock.messages.findMany.mockResolvedValue([
      {
        id: "msg-3",
        conversation_id: CONV_ID,
        sender_id: TEST_USER.id,
        content: "Newest",
        created_at: new Date("2026-02-23T12:00:00.000Z"),
        is_read: true,
        media_urls: [],
      },
      {
        id: "msg-2",
        conversation_id: CONV_ID,
        sender_id: TEST_USER.id,
        content: "Older",
        created_at: new Date("2026-02-23T11:00:00.000Z"),
        is_read: true,
        media_urls: [],
      },
      {
        id: "msg-1",
        conversation_id: CONV_ID,
        sender_id: TEST_USER.id,
        content: "Overflow",
        created_at: new Date("2026-02-23T10:00:00.000Z"),
        is_read: true,
        media_urls: [],
      },
    ]);

    const result = await getMessagesService(CONV_ID, { limit: 2 });

    expect(result.messages).toHaveLength(2);
    expect(result.messages[0].content).toBe("Newest");
    expect(result.messages[1].content).toBe("Older");
    expect(result.hasMore).toBe(true);
    expect(result.nextBefore).toBe("2026-02-23T11:00:00.000Z");
  });

  it("returns hasMore false and null nextBefore when no extra rows", async () => {
    prismaMock.messages.findMany.mockResolvedValue([
      {
        id: "msg-1",
        conversation_id: CONV_ID,
        sender_id: TEST_USER.id,
        content: "Only one",
        created_at: new Date("2026-02-23T09:00:00.000Z"),
        is_read: false,
        media_urls: [],
      },
    ]);

    const result = await getMessagesService(CONV_ID, { limit: 2 });

    expect(result.messages).toHaveLength(1);
    expect(result.hasMore).toBe(false);
    expect(result.nextBefore).toBeNull();
    expect(result.messages[0].created_at).toBe("2026-02-23T09:00:00.000Z");
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("sendMessageService", () => {
  it("creates and returns a new message", async () => {
    const now = new Date();
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });
    prismaMock.messages.create.mockResolvedValue({
      id: "msg-new",
      conversation_id: CONV_ID,
      sender_id: TEST_USER.id,
      content: "Hello!",
      created_at: now,
      is_read: false,
      media_urls: [],
    });

    const result = await sendMessageService(CONV_ID, TEST_USER.id, "Hello!");

    expect(result.content).toBe("Hello!");
    expect(result.sender_id).toBe(TEST_USER.id);
  });

  it("throws 404 when conversation does not exist", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(null);

    await expect(
      sendMessageService(CONV_ID, TEST_USER.id, "hi"),
    ).rejects.toMatchObject({
      message: "Conversation not found",
      statusCode: 404,
    });
  });

  it("throws 403 when sender is not a participant", async () => {
    const outsiderId = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee";
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });

    await expect(
      sendMessageService(CONV_ID, outsiderId, "hack"),
    ).rejects.toMatchObject({
      message: "Not a participant of this conversation",
      statusCode: 403,
    });
  });

  it("accepts an empty content string when media_urls are provided", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });
    prismaMock.messages.create.mockResolvedValue({
      id: "msg-media",
      conversation_id: CONV_ID,
      sender_id: TEST_USER.id,
      content: "",
      created_at: new Date(),
      is_read: false,
      media_urls: ["https://cdn.example.com/image.jpg"],
    });

    const result = await sendMessageService(CONV_ID, TEST_USER.id, "", [
      "https://cdn.example.com/image.jpg",
    ]);

    expect(result.media_urls).toHaveLength(1);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("markAsReadService", () => {
  it("marks messages from the other user as read", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });
    prismaMock.messages.updateMany.mockResolvedValue({ count: 2 });

    const updatedCount = await markAsReadService(CONV_ID, TEST_USER.id);

    expect(updatedCount).toBe(2);
    expect(prismaMock.conversations.findUnique).toHaveBeenCalledWith({
      where: { id: CONV_ID },
      include: { conversation_members: true },
    });

    expect(prismaMock.messages.updateMany).toHaveBeenCalledWith({
      where: {
        conversation_id: CONV_ID,
        sender_id: { not: TEST_USER.id },
        is_read: false,
      },
      data: { is_read: true },
    });
  });

  it("throws 404 when conversation does not exist", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(null);

    await expect(
      markAsReadService(CONV_ID, TEST_USER.id),
    ).rejects.toMatchObject({
      message: "Conversation not found",
      statusCode: 404,
    });
  });

  it("throws 403 when current user is not a conversation participant", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });

    await expect(
      markAsReadService(CONV_ID, "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"),
    ).rejects.toMatchObject({
      message: "Not a participant of this conversation",
      statusCode: 403,
    });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("searchUsersService", () => {
  it("returns users matching the query", async () => {
    prismaMock.users.findMany.mockResolvedValue([mockOtherUser]);

    const result = await searchUsersService("bo", 3, TEST_USER.id);

    expect(result).toHaveLength(1);
    expect(result[0].username).toBe("bob");
  });

  it("excludes the current user from results", async () => {
    prismaMock.users.findMany.mockResolvedValue([]);

    await searchUsersService("alice", 3, TEST_USER.id);

    const call = prismaMock.users.findMany.mock.calls[0][0];
    expect(call.where.AND[0]).toEqual({ id: { not: TEST_USER.id } });
  });

  it("returns empty array when no users match", async () => {
    prismaMock.users.findMany.mockResolvedValue([]);

    const result = await searchUsersService("zzz", 3, TEST_USER.id);

    expect(result).toEqual([]);
  });
});
