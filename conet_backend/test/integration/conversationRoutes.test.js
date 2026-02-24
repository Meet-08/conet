/**
 * Integration tests – /api/conversations routes
 *
 * ALL routes in this resource require authentication.
 * Tests verify:
 *  ✓ POST  /api/conversations       – create or retrieve conversation
 *  ✓ GET   /api/conversations       – list all conversations for current user
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
  created_at: new Date(),
  updated_at: new Date(),
  messages_conversations_last_message_idTomessages: null,
  users_conversations_user_oneTousers: {
    id: TEST_USER.id,
    username: "alice",
    email: TEST_USER.email,
    first_name: "Alice",
    last_name: "Smith",
    profile_pic_url: null,
    user_role: "user",
    is_verified: false,
  },
  users_conversations_user_twoTousers: mockOtherUser,
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

beforeEach(() => {
  resetPrismaMocks();
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/conversations", () => {
  it("201 – creates or retrieves a conversation with a UUID user ID", async () => {
    prismaMock.users.findUnique.mockResolvedValue(mockOtherUser);
    prismaMock.conversations.upsert.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
      updated_at: new Date(),
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
describe("POST /api/conversations/:conversationId/messages", () => {
  it("201 – sends a message as a participant", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: CONV_ID,
      user_one: TEST_USER.id,
      user_two: TEST_USER_B.id,
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
    });

    const res = await request(app)
      .post(`/api/conversations/${CONV_ID}/messages`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Intrude!" });

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
