/**
 * Integration tests – /api/notifications routes
 *
 * Coverage:
 *  ✓ GET  /api/notifications            – authenticated fetch, limit/cursor parsing
 *  ✓ POST /api/notifications/mark-seen  – authenticated mutation
 *  ✓ Auth guard on both routes
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

process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
process.env.NODE_ENV = "test";

import { createApp } from "../../app.js";

const app = createApp();

beforeEach(() => {
  resetPrismaMocks();
});

describe("GET /api/notifications", () => {
  it("200 – returns notifications payload for authenticated user", async () => {
    prismaMock.notifications.findMany.mockResolvedValue([
      {
        id: "notif-1",
        receiver_id: TEST_USER.id,
        actor_id: "actor-1",
        type: "POST_LIKE",
        is_seen: false,
        created_at: new Date(),
        users_notifications_actor_idTousers: {
          id: "actor-1",
          first_name: "Alice",
          last_name: "Smith",
          username: "alice",
          profile_pic_url: null,
        },
      },
    ]);
    prismaMock.users.findUnique.mockResolvedValue({
      unseen_notification_count: 2,
    });

    const res = await request(app)
      .get("/api/notifications")
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(res.status).toBe(200);
    expect(res.body.notifications).toHaveLength(1);
    expect(res.body.unseenCount).toBe(2);
    expect(prismaMock.notifications.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { receiver_id: TEST_USER.id },
        take: 20,
      }),
    );
  });

  it("200 – parses limit and cursor query params", async () => {
    prismaMock.notifications.findMany.mockResolvedValue([]);
    prismaMock.users.findUnique.mockResolvedValue({
      unseen_notification_count: 0,
    });

    await request(app)
      .get("/api/notifications?limit=5&cursor=cursor-123")
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(prismaMock.notifications.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        take: 5,
        cursor: { id: "cursor-123" },
        skip: 1,
      }),
    );
  });

  it("401 – rejects unauthenticated requests", async () => {
    const res = await request(app).get("/api/notifications");

    expect(res.status).toBe(401);
    expect(prismaMock.notifications.findMany).not.toHaveBeenCalled();
  });
});

describe("POST /api/notifications/mark-seen", () => {
  it("200 – marks notifications as seen for authenticated user", async () => {
    prismaMock.notifications.updateMany.mockResolvedValue({ count: 3 });

    const res = await request(app)
      .post("/api/notifications/mark-seen")
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ message: "Notifications marked as seen" });
    expect(prismaMock.notifications.updateMany).toHaveBeenCalledWith({
      where: {
        receiver_id: TEST_USER.id,
        is_seen: false,
      },
      data: {
        is_seen: true,
      },
    });
  });

  it("401 – rejects unauthenticated requests", async () => {
    const res = await request(app).post("/api/notifications/mark-seen");

    expect(res.status).toBe(401);
    expect(prismaMock.notifications.updateMany).not.toHaveBeenCalled();
  });
});
