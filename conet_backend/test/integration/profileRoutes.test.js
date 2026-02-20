/**
 * Integration tests – /api/profile routes
 *
 * Strategy: mock the service layer and Prisma.
 * Tests verify that:
 *  - Controllers correctly translate HTTP input → service calls
 *  - HTTP response shape matches the contract
 *  - Auth middleware gates protected routes
 *  - Validation rejects bad payloads before service is called
 *
 * The service layer is separately covered by unit tests, so we mock it
 * here to isolate HTTP behavior.
 */

import { beforeEach, describe, expect, it, mock } from "bun:test";
import request from "supertest";
import {
  makeAuthHeader,
  makeExpiredAuthHeader,
  makeMalformedAuthHeader,
  TEST_JWT_SECRET,
  TEST_USER,
  TEST_USER_B,
} from "../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../mocks/prismaMock.js";

// ── Module mocks (hoisted by Bun before static imports resolve) ──────────────
mock.module("../../config/prisma.js", () => ({ default: prismaMock }));

// ── Must set JWT secret before app boots (middleware reads process.env) ──────
process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
process.env.NODE_ENV = "test";

import { createApp } from "../../app.js";

const app = createApp();

// ─── Fixtures ──────────────────────────────────────────────────────────────

const mockProfile = {
  id: TEST_USER.id,
  email: TEST_USER.email,
  first_name: "Alice",
  last_name: "Smith",
  username: "alice",
  profile_pic_url: null,
  user_role: "user",
  is_verified: false,
  about_me: "Hello",
  banner_image_url: null,
  interests: [],
  social_links: [],
  date_of_birth: null,
  user_academics: [],
  follower_count: 0,
  following_count: 0,
  is_following: false,
};

const mockUserRow = {
  ...mockProfile,
  _count: {
    user_follows_user_follows_following_idTousers: 0,
    user_follows_user_follows_follower_idTousers: 0,
  },
};

beforeEach(() => {
  resetPrismaMocks();
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/profile/:uid", () => {
  it("200 – returns profile for valid user", async () => {
    prismaMock.users.findUnique.mockResolvedValue(mockUserRow);

    const res = await request(app)
      .get(`/api/profile/${TEST_USER.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.profile.id).toBe(TEST_USER.id);
  });

  it("404 – returns not found when user does not exist", async () => {
    prismaMock.users.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .get(`/api/profile/nonexistent-id`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(404);
    expect(res.body.title).toBe("Not Found");
  });

  it("401 – rejects request with no Authorization header", async () => {
    const res = await request(app).get(`/api/profile/${TEST_USER.id}`);

    expect(res.status).toBe(401);
  });

  it("401 – rejects expired token", async () => {
    const res = await request(app)
      .get(`/api/profile/${TEST_USER.id}`)
      .set("Authorization", makeExpiredAuthHeader());

    expect(res.status).toBe(401);
  });

  it("401 – rejects malformed token", async () => {
    const res = await request(app)
      .get(`/api/profile/${TEST_USER.id}`)
      .set("Authorization", makeMalformedAuthHeader());

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/profile/:uid/follow", () => {
  it("200 – successfully follows a user", async () => {
    prismaMock.users.findUnique.mockResolvedValue({ id: TEST_USER_B.id });
    prismaMock.user_follows.upsert.mockResolvedValue({});

    const res = await request(app)
      .post(`/api/profile/${TEST_USER_B.id}/follow`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/followed/i);
  });

  it("400 – rejects self-follow attempt", async () => {
    const res = await request(app)
      .post(`/api/profile/${TEST_USER.id}/follow`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });

  it("404 – returns not found when target user does not exist", async () => {
    prismaMock.users.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .post(`/api/profile/ghost-user/follow`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(404);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).post(
      `/api/profile/${TEST_USER_B.id}/follow`,
    );

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("DELETE /api/profile/:uid/follow", () => {
  it("200 – successfully unfollows a user", async () => {
    prismaMock.user_follows.deleteMany.mockResolvedValue({ count: 1 });

    const res = await request(app)
      .delete(`/api/profile/${TEST_USER_B.id}/follow`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("400 – rejects self-unfollow attempt", async () => {
    const res = await request(app)
      .delete(`/api/profile/${TEST_USER.id}/follow`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("PUT /api/profile/about-me", () => {
  it("200 – updates about_me successfully", async () => {
    prismaMock.users.update.mockResolvedValue({
      ...mockUserRow,
      about_me: "New bio",
    });

    const res = await request(app)
      .put("/api/profile/about-me")
      .set("Authorization", makeAuthHeader())
      .send({ about_me: "New bio" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("400 – rejects when about_me is missing from body", async () => {
    const res = await request(app)
      .put("/api/profile/about-me")
      .set("Authorization", makeAuthHeader())
      .send({});

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("PUT /api/profile/academic-info", () => {
  it("200 – updates academic info with valid payload", async () => {
    prismaMock.user_academics.findFirst.mockResolvedValue(null);
    prismaMock.user_academics.create.mockResolvedValue({});
    prismaMock.users.findUnique.mockResolvedValue(mockUserRow);

    const res = await request(app)
      .put("/api/profile/academic-info")
      .set("Authorization", makeAuthHeader())
      .send({ college_name: "MIT", course: "CS" });

    expect(res.status).toBe(200);
  });

  it("400 – rejects when college_name is missing", async () => {
    const res = await request(app)
      .put("/api/profile/academic-info")
      .set("Authorization", makeAuthHeader())
      .send({ course: "CS" });

    expect(res.status).toBe(400);
  });

  it("400 – rejects when course is missing", async () => {
    const res = await request(app)
      .put("/api/profile/academic-info")
      .set("Authorization", makeAuthHeader())
      .send({ college_name: "MIT" });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /health", () => {
  it("200 – health check is publicly accessible", async () => {
    const res = await request(app).get("/health");

    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("Unknown routes", () => {
  it("404 – returns not found for unregistered paths", async () => {
    const res = await request(app).get("/api/nonexistent-route");

    expect(res.status).toBe(404);
  });
});
