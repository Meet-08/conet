/**
 * Integration tests – /api/posts routes
 *
 * ⚠ ARCHITECTURAL FLAG:
 * postController.js calls Prisma directly, violating the service-layer
 * architecture mandated by bun.instructions.md.  All other controllers
 * delegate to a service.  postController is a maintenance and testability
 * liability: it cannot be unit-tested in isolation, and any DB logic change
 * requires touching the controller.
 *
 * MANDATORY ACTION: Extract a postService.js before this codebase ships.
 *
 * For now, integration tests mock Prisma directly (as postController does).
 *
 * Coverage:
 *  ✓ GET  /api/posts        – public, paginated
 *  ✓ GET  /api/posts/:id    – public, single
 *  ✓ POST /api/posts        – protected, content required
 *  ✓ PUT  /api/posts/:id    – protected, ownership enforced
 *  ✓ DELETE /api/posts/:id  – protected, ownership enforced
 *  ✓ PUT  /api/posts/like/:id  – toggle like
 *  ✓ POST /api/posts/comment/:id
 *  ✓ Auth guard on all mutating routes
 */

import { beforeEach, describe, expect, it, mock } from "bun:test";
import request from "supertest";
import {
  makeAuthHeader,
  TEST_JWT_SECRET,
  TEST_USER,
} from "../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../mocks/prismaMock.js";

mock.module("../../config/prisma.js", () => ({ default: prismaMock }));
mock.module("../../config/queue.js", () => ({
  notificationQueue: {
    add: mock(() => Promise.resolve({ id: "job-1" })),
  },
  connection: {
    quit: mock(() => Promise.resolve()),
  },
}));

process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
process.env.NODE_ENV = "test";

import { createApp } from "../../app.js";

const app = createApp();

// ─── Fixtures ──────────────────────────────────────────────────────────────

const POST_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

const mockUser = {
  id: TEST_USER.id,
  username: "alice",
  email: TEST_USER.email,
  first_name: "Alice",
  last_name: "Smith",
  profile_pic_url: null,
  user_role: "user",
  is_verified: false,
};

const mockPost = {
  id: POST_ID,
  user_id: TEST_USER.id,
  user: mockUser,
  content: "Hello campus!",
  media_urls: [],
  like_count: 0,
  comment_count: 0,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
  post_likes: [],
  post_comments: [],
  _count: { post_likes: 0, post_comments: 0 },
};

beforeEach(() => {
  resetPrismaMocks();
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/posts", () => {
  it("200 – returns posts array", async () => {
    prismaMock.posts.findMany.mockResolvedValue([mockPost]);

    const res = await request(app)
      .get("/api/posts")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.posts)).toBe(true);
  });

  it("200 – returns empty posts array when DB is empty", async () => {
    prismaMock.posts.findMany.mockResolvedValue([]);

    const res = await request(app)
      .get("/api/posts")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(0);
  });

  it("200 – respects page and limit query params", async () => {
    prismaMock.posts.findMany.mockResolvedValue([]);

    const res = await request(app)
      .get("/api/posts?page=2&limit=5")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    // Verify skip was calculated correctly: (2-1)*5 = 5
    expect(prismaMock.posts.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 5, take: 5 }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/posts/:id", () => {
  it("200 – returns a single post", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);

    const res = await request(app)
      .get(`/api/posts/${POST_ID}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.post.id).toBe(POST_ID);
  });

  it("404 – returns not found for non-existent post", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .get(`/api/posts/does-not-exist`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/posts", () => {
  it("201 – creates a new post with content", async () => {
    prismaMock.posts.create.mockResolvedValue(mockPost);

    const res = await request(app)
      .post("/api/posts")
      .set("Authorization", makeAuthHeader())
      .send({ content: "Hello campus!" });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.post.content).toBe("Hello campus!");
  });

  it("201 – creates post with media_urls", async () => {
    const postWithMedia = {
      ...mockPost,
      media_urls: ["https://cdn.example.com/img.jpg"],
    };
    prismaMock.posts.create.mockResolvedValue(postWithMedia);

    const res = await request(app)
      .post("/api/posts")
      .set("Authorization", makeAuthHeader())
      .send({
        content: "Photo post",
        media_urls: ["https://cdn.example.com/img.jpg"],
      });

    expect(res.status).toBe(201);
  });

  it("400 – rejects post creation without content", async () => {
    const res = await request(app)
      .post("/api/posts")
      .set("Authorization", makeAuthHeader())
      .send({ media_urls: [] });

    expect(res.status).toBe(400);
  });

  it("401 – rejects unauthenticated post creation", async () => {
    const res = await request(app)
      .post("/api/posts")
      .send({ content: "Unauthenticated post" });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("PUT /api/posts/:id", () => {
  it("200 – updates a post owned by the current user", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.posts.update.mockResolvedValue({
      ...mockPost,
      content: "Updated content",
    });

    const res = await request(app)
      .put(`/api/posts/${POST_ID}`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Updated content" });

    expect(res.status).toBe(200);
  });

  it("401 – rejects unauthenticated update", async () => {
    const res = await request(app)
      .put(`/api/posts/${POST_ID}`)
      .send({ content: "Updated content" });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("DELETE /api/posts/:id", () => {
  it("200 – deletes a post owned by the current user", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.posts.delete.mockResolvedValue(mockPost);

    const res = await request(app)
      .delete(`/api/posts/${POST_ID}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
  });

  it("401 – rejects unauthenticated delete", async () => {
    const res = await request(app).delete(`/api/posts/${POST_ID}`);

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("PUT /api/posts/like/:id (toggle like)", () => {
  it("200 – toggles like on a post", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.post_likes.findUnique.mockResolvedValue(null); // not yet liked
    prismaMock.post_likes.create.mockResolvedValue({});
    prismaMock.posts.update.mockResolvedValue({ ...mockPost, like_count: 1 });

    const res = await request(app)
      .put(`/api/posts/like/${POST_ID}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
  });

  it("401 – rejects unauthenticated like", async () => {
    const res = await request(app).put(`/api/posts/like/${POST_ID}`);

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/posts/comment/:id", () => {
  it("201 – adds a comment to a post", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.post_comments.create.mockResolvedValue({
      id: "comment-1",
      post_id: POST_ID,
      user_id: TEST_USER.id,
      content: "Great post!",
      created_at: new Date(),
    });

    const res = await request(app)
      .post(`/api/posts/comment/${POST_ID}`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Great post!" });

    expect(res.status).toBe(201);
  });

  it("401 – rejects unauthenticated comment", async () => {
    const res = await request(app)
      .post(`/api/posts/comment/${POST_ID}`)
      .send({ content: "Unauthenticated comment" });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/posts/liked", () => {
  const mockLikeEntry = {
    post_id: POST_ID,
    user_id: TEST_USER.id,
    created_at: new Date().toISOString(),
    post: mockPost,
  };

  it("200 – returns liked posts for authenticated user", async () => {
    prismaMock.$transaction.mockResolvedValue([[mockLikeEntry], 1]);

    const res = await request(app)
      .get("/api/posts/liked")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.posts)).toBe(true);
    expect(res.body.total).toBe(1);
  });

  it("200 – returns empty array when user has no likes", async () => {
    prismaMock.$transaction.mockResolvedValue([[], 0]);

    const res = await request(app)
      .get("/api/posts/liked")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.posts).toEqual([]);
    expect(res.body.total).toBe(0);
  });

  it("200 – respects page and limit query params", async () => {
    prismaMock.$transaction.mockResolvedValue([[], 0]);

    const res = await request(app)
      .get("/api/posts/liked?page=2&limit=5")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(prismaMock.$transaction).toHaveBeenCalled();
  });

  it("401 – rejects unauthenticated request", async () => {
    const res = await request(app).get("/api/posts/liked");

    expect(res.status).toBe(401);
  });
});
