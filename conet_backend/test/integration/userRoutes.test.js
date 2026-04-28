/**
 * Integration tests – /api/users routes
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

mock.module("../../config/prisma.js", () => ({ default: prismaMock }));

process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
process.env.NODE_ENV = "test";

import { createApp } from "../../app.js";

const app = createApp();

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

beforeEach(() => {
  resetPrismaMocks();
});

describe("GET /api/users/search", () => {
  it("200 - returns matching users for the shared user selector", async () => {
    prismaMock.users.findMany.mockResolvedValue([mockOtherUser]);

    const res = await request(app)
      .get("/api/users/search?query=bo&limit=8")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body).toEqual([mockOtherUser]);
    expect(prismaMock.users.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          AND: expect.arrayContaining([{ id: { not: TEST_USER.id } }]),
        }),
        take: 8,
      }),
    );
  });

  it("400 - rejects missing query", async () => {
    const res = await request(app)
      .get("/api/users/search")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });

  it("400 - rejects blank query", async () => {
    const res = await request(app)
      .get("/api/users/search?query=%20%20")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });

  it("401 - requires authentication", async () => {
    const res = await request(app).get("/api/users/search?query=bo");

    expect(res.status).toBe(401);
  });
});
