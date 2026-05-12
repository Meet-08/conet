/**
 * Integration tests – /api/conversations routes
 *
 * ALL routes in this resource require authentication.
 * Tests verify:
 *  ✓ POST  /api/conversations       – create or retrieve conversation
 *  ✓ GET   /api/conversations       – list all conversations for current user
 *  ✓ GET   /api/conversations/:id/shared
 *  ✓ GET   /api/conversations/:id/messages
 *  ✓ POST  /api/conversations/:id/messages
 *  ✓ POST  /api/conversations/:id/mark_as_read
 *  ✓ GET   /api/conversations/search_users
 *  ✓ Auth required on every route
 *  ✓ Validation rejects bad input
 */

import { beforeEach, describe, expect, it, mock } from "bun:test";
import request from "supertest";
import {
  makeAuthHeader,
  TEST_JWT_SECRET,
  TEST_USER,
  TEST_USER_B,
} from "../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../mocks/prismaMock.js";

mock.module("../../config/queue.js", () => ({
  notificationQueue: {
    add: mock(() => Promise.resolve()),
  },
}));

mock.module("../../config/prisma.js", () => ({ default: prismaMock }));

process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
process.env.NODE_ENV = "test";

import { createApp } from "../../app.js";

const app = createApp();

// ─── Fixtures ──────────────────────────────────────────────────────────────

const CONV_ID = "cccccccc-cccc-cccc-cccc-cccccccccccc";
const MSG_ID = "dddddddd-dddd-dddd-dddd-dddddddddddd";
const POST_MSG_ID = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee";
const MEDIA_MSG_ID = "ffffffff-ffff-ffff-ffff-ffffffffffff";

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

const mockConversation = {
  id: CONV_ID,
  user_one: TEST_USER.id,
  user_two: TEST_USER_B.id,
  type: "direct",
  created_at: new Date(),
  updated_at: new Date(),
  messages_conversations_last_message_idTomessages: null,
  conversation_members: [
    {
      user_id: TEST_USER.id,
      users: {
        id: TEST_USER.id,
        username: "alice",
        email: TEST_USER.email,
        first_name: "Alice",
        last_name: "Smith",
        profile_pic_url: null,
        user_role: "user",
        is_verified: false,
      },
    },
    {
      user_id: TEST_USER_B.id,
      users: mockOtherUser,
    },
  ],
};

const mockMessage = {
  id: MSG_ID,
  conversation_id: CONV_ID,
  sender_id: TEST_USER.id,
  content: "Hello!",
  created_at: new Date(),
  is_read: false,
  media_urls: [],
};

const mockSharedMessage = {
  id: MEDIA_MSG_ID,
  conversation_id: CONV_ID,
  sender_id: TEST_USER_B.id,
  created_at: new Date("2026-01-03T10:00:00.000Z"),
  media_urls: [
    "https://cdn.example.com/photo.jpg",
    "https://cdn.example.com/video.mp4",
    "https://cdn.example.com/manual.pdf",
  ],
};

const mockPostMessage = {
  id: POST_MSG_ID,
  conversation_id: CONV_ID,
  sender_id: TEST_USER.id,
  content: null,
  created_at: new Date("2026-01-02T10:00:00.000Z"),
  is_read: false,
  media_urls: [],
  is_post: true,
  post_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  posts: {
    id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    user: {
      id: TEST_USER.id,
      username: "alice",
      email: TEST_USER.email,
      first_name: "Alice",
      last_name: "Smith",
      profile_pic_url: null,
      user_role: "user",
      is_verified: false,
      user_follows_user_follows_following_idTousers: [],
    },
    content: { ops: [{ insert: "Shared post" }] },
    media_urls: ["https://cdn.example.com/post.jpg"],
    _count: { post_likes: 0, post_comments: 0 },
    post_likes: [],
  },
};

beforeEach(() => {
  resetPrismaMocks();
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/conversations", () => {
  it("201 – creates or retrieves a conversation with a UUID user ID", async () => {
    prismaMock.users.findUnique.mockResolvedValue(mockOtherUser);
    // Service now uses findFirst + create (upsert can't target partial indexes)
    prismaMock.conversations.findFirst.mockResolvedValue(null);
    prismaMock.conversations.create.mockResolvedValue({
      id: CONV_ID,
      type: "direct",
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      updated_at: new Date(),
      conversation_members: [],
    });

    const res = await request(app)
      .post(`/api/conversations?other_user=${TEST_USER_B.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.conversation.id).toBe(CONV_ID);
  });

  it("400 – rejects when other_user query param is missing", async () => {
    const res = await request(app)
      .post("/api/conversations")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });

  it("400 – rejects self-conversation attempt", async () => {
    const res = await request(app)
      .post(`/api/conversations?other_user=${TEST_USER.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });

  it("404 – returns not found when target user does not exist", async () => {
    prismaMock.users.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .post(`/api/conversations?other_user=${TEST_USER_B.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(404);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).post(
      `/api/conversations?other_user=${TEST_USER_B.id}`,
    );

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/conversations", () => {
  it("200 – returns list of conversations for authenticated user", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([mockConversation]);
    prismaMock.messages.groupBy.mockResolvedValue([]);

    const res = await request(app)
      .get("/api/conversations")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it("200 – accepts search query and forwards it to the service", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([mockConversation]);
    prismaMock.messages.groupBy.mockResolvedValue([]);

    const res = await request(app)
      .get("/api/conversations?search=bob")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(prismaMock.conversations.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          AND: expect.any(Array),
        }),
      }),
    );
  });

  it("200 – returns empty array when user has no conversations", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([]);
    prismaMock.messages.groupBy.mockResolvedValue([]);

    const res = await request(app)
      .get("/api/conversations")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).get("/api/conversations");

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/conversations/:conversationId/messages", () => {
  it("200 – returns messages for a conversation", async () => {
    prismaMock.messages.findMany.mockResolvedValue([mockMessage]);

    const res = await request(app)
      .get(`/api/conversations/${CONV_ID}/messages`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.messages)).toBe(true);
    expect(res.body.messages[0].content).toBe("Hello!");
  });

  it("200 – passes limit param to Prisma", async () => {
    prismaMock.messages.findMany.mockResolvedValue([]);

    await request(app)
      .get(`/api/conversations/${CONV_ID}/messages?limit=10`)
      .set("Authorization", makeAuthHeader());

    expect(prismaMock.messages.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ take: 11 }),
    );
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).get(
      `/api/conversations/${CONV_ID}/messages`,
    );

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/conversations/:conversationId/shared", () => {
  it("200 – returns image and video media items", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });
    prismaMock.messages.findMany.mockResolvedValue([mockSharedMessage]);

    const res = await request(app)
      .get(`/api/conversations/${CONV_ID}/shared?type=media`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(2);
    expect(res.body.map((item) => item.url)).toEqual([
      "https://cdn.example.com/photo.jpg",
      "https://cdn.example.com/video.mp4",
    ]);
  });

  it("200 – returns post items with mapped post data", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });
    prismaMock.messages.findMany.mockResolvedValue([mockPostMessage]);

    const res = await request(app)
      .get(`/api/conversations/${CONV_ID}/shared?type=post`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].post.id).toBe("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
  });

  it("200 – returns non image/video media items for docs", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });
    prismaMock.messages.findMany.mockResolvedValue([mockSharedMessage]);

    const res = await request(app)
      .get(`/api/conversations/${CONV_ID}/shared?type=docs`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].url).toBe("https://cdn.example.com/manual.pdf");
  });

  it("400 – rejects missing type query param", async () => {
    const res = await request(app)
      .get(`/api/conversations/${CONV_ID}/shared`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/conversations/:conversationId/messages", () => {
  it("201 – sends a message as a participant", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });
    prismaMock.messages.create.mockResolvedValue(mockMessage);

    const res = await request(app)
      .post(`/api/conversations/${CONV_ID}/messages`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Hello!" });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.message.content).toBe("Hello!");
  });

  it("400 – rejects empty content with no mediaUrls", async () => {
    const res = await request(app)
      .post(`/api/conversations/${CONV_ID}/messages`)
      .set("Authorization", makeAuthHeader())
      .send({});

    expect(res.status).toBe(400);
  });

  it("403 – rejects message from non-participant", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER_B.id, // alice is NOT user_one
      user_two: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", // alice is NOT user_two
      conversation_members: [
        { user_id: TEST_USER_B.id },
        { user_id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee" },
      ],
    });

    const res = await request(app)
      .post(`/api/conversations/${CONV_ID}/messages`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Intrude!" });

    expect(res.status).toBe(403);
  });

  it("403 – rejects group message from non-admin when send messages are restricted", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      type: "group",
      only_admin_send_messages: true,
      conversation_members: [
        { user_id: TEST_USER.id, role: "member" },
        { user_id: TEST_USER_B.id, role: "admin" },
      ],
    });

    const res = await request(app)
      .post(`/api/conversations/${CONV_ID}/messages`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Should not send" });

    expect(res.status).toBe(403);
  });

  it("404 – returns not found when conversation does not exist", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .post(`/api/conversations/${CONV_ID}/messages`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Hello?" });

    expect(res.status).toBe(404);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app)
      .post(`/api/conversations/${CONV_ID}/messages`)
      .send({ content: "Unauthenticated" });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/conversations/:conversationId/mark_as_read", () => {
  it("200 – marks messages as read successfully", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      conversation_members: [
        { user_id: TEST_USER.id },
        { user_id: TEST_USER_B.id },
      ],
    });
    prismaMock.messages.updateMany.mockResolvedValue({ count: 3 });

    const res = await request(app)
      .post(`/api/conversations/${CONV_ID}/mark_as_read`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).post(
      `/api/conversations/${CONV_ID}/mark_as_read`,
    );

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/conversations/search_users", () => {
  it("200 – returns matching users", async () => {
    prismaMock.users.findMany.mockResolvedValue([mockOtherUser]);

    const res = await request(app)
      .get("/api/conversations/search_users?query=bo")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0].username).toBe("bob");
  });

  it("400 – rejects when query param is missing", async () => {
    const res = await request(app)
      .get("/api/conversations/search_users")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).get(
      "/api/conversations/search_users?query=bo",
    );

    expect(res.status).toBe(401);
  });
});
