/**
 * Integration tests – /api/reports routes
 *
 * Covers:
 *  ✓ POST   /api/reports              – create report
 *  ✓ GET    /api/reports/mine         – current user reports
 *  ✓ GET    /api/reports/admin        – admin report inbox
 *  ✓ GET    /api/reports/:id          – report detail access control
 *  ✓ PATCH  /api/reports/:id/review   – admin review flow
 *  ✓ Validation and duplicate report handling
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

const REPORT_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const TARGET_ID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const REPORTED_AT = new Date("2026-04-29T10:00:00.000Z");

const reporterUser = {
  id: TEST_USER.id,
  email: TEST_USER.email,
  first_name: "Alice",
  last_name: "Smith",
  username: "alice",
  profile_pic_url: null,
  user_role: "user",
  is_verified: false,
};

const reviewerUser = {
  id: TEST_USER_B.id,
  email: TEST_USER_B.email,
  first_name: "Bob",
  last_name: "Jones",
  username: "bob",
  profile_pic_url: null,
  user_role: "admin",
  is_verified: true,
};

const makeReportRow = (overrides = {}) => ({
  id: REPORT_ID,
  reporter_id: TEST_USER.id,
  target_id: TARGET_ID,
  target_type: "post",
  reason: "spam",
  description: "Repeated spam content",
  status: "pending",
  reviewed_by: null,
  reviewed_at: null,
  created_at: REPORTED_AT,
  updated_at: REPORTED_AT,
  users_reports_reporter_idTousers: reporterUser,
  users_reports_reviewed_byTousers: null,
  ...overrides,
});

beforeEach(() => {
  resetPrismaMocks();
});

describe("POST /api/reports", () => {
  it("201 – creates a report for the authenticated user", async () => {
    prismaMock.reports.findUnique.mockResolvedValue(null);
    prismaMock.reports.create.mockResolvedValue(makeReportRow());

    const res = await request(app)
      .post("/api/reports")
      .set("Authorization", makeAuthHeader(TEST_USER))
      .send({
        target_id: TARGET_ID,
        target_type: "post",
        reason: "spam",
        description: "Repeated spam content",
      });

    expect(res.status).toBe(201);
    expect(res.body.report.id).toBe(REPORT_ID);
    expect(res.body.report.reporter.id).toBe(TEST_USER.id);
    expect(prismaMock.reports.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: {
          reporter_id: TEST_USER.id,
          target_id: TARGET_ID,
          target_type: "post",
          reason: "spam",
          description: "Repeated spam content",
        },
      }),
    );
  });

  it("409 – rejects duplicate reports for the same target", async () => {
    prismaMock.reports.findUnique.mockResolvedValue(makeReportRow());

    const res = await request(app)
      .post("/api/reports")
      .set("Authorization", makeAuthHeader(TEST_USER))
      .send({
        target_id: TARGET_ID,
        target_type: "post",
        reason: "spam",
      });

    expect(res.status).toBe(409);
    expect(prismaMock.reports.create).not.toHaveBeenCalled();
  });

  it("400 – validates required report fields", async () => {
    const res = await request(app)
      .post("/api/reports")
      .set("Authorization", makeAuthHeader(TEST_USER))
      .send({
        target_id: TARGET_ID,
        reason: "spam",
      });

    expect(res.status).toBe(400);
    expect(prismaMock.reports.create).not.toHaveBeenCalled();
  });
});

describe("GET /api/reports/mine", () => {
  it("200 – returns the current user's reports", async () => {
    prismaMock.reports.findMany.mockResolvedValue([makeReportRow()]);
    prismaMock.reports.count.mockResolvedValue(1);

    const res = await request(app)
      .get("/api/reports/mine")
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(res.status).toBe(200);
    expect(res.body.reports).toHaveLength(1);
    expect(res.body.total).toBe(1);
    expect(prismaMock.reports.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { reporter_id: TEST_USER.id },
        take: 20,
        skip: 0,
      }),
    );
  });
});

describe("GET /api/reports/admin", () => {
  it("200 – allows admins to list all reports", async () => {
    prismaMock.users.findUnique.mockResolvedValue({
      id: TEST_USER.id,
      user_role: "admin",
    });
    prismaMock.reports.findMany.mockResolvedValue([makeReportRow()]);
    prismaMock.reports.count.mockResolvedValue(1);

    const res = await request(app)
      .get("/api/reports/admin")
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(res.status).toBe(200);
    expect(res.body.reports).toHaveLength(1);
    expect(prismaMock.reports.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {},
        take: 20,
        skip: 0,
      }),
    );
  });

  it("403 – rejects non-admin report inbox access", async () => {
    prismaMock.users.findUnique.mockResolvedValue({
      id: TEST_USER.id,
      user_role: "user",
    });

    const res = await request(app)
      .get("/api/reports/admin")
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(res.status).toBe(403);
    expect(prismaMock.reports.findMany).not.toHaveBeenCalled();
  });
});

describe("GET /api/reports/:id", () => {
  it("200 – allows the reporter to fetch their own report", async () => {
    prismaMock.reports.findUnique.mockResolvedValue(makeReportRow());

    const res = await request(app)
      .get(`/api/reports/${REPORT_ID}`)
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(res.status).toBe(200);
    expect(res.body.report.id).toBe(REPORT_ID);
  });

  it("403 – blocks non-owners who are not admins", async () => {
    prismaMock.reports.findUnique.mockResolvedValue(
      makeReportRow({
        reporter_id: TEST_USER_B.id,
        users_reports_reporter_idTousers: reviewerUser,
      }),
    );
    prismaMock.users.findUnique.mockResolvedValue({
      id: TEST_USER.id,
      user_role: "user",
    });

    const res = await request(app)
      .get(`/api/reports/${REPORT_ID}`)
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(res.status).toBe(403);
  });
});

describe("PATCH /api/reports/:id/review", () => {
  it("200 – lets admins review a report", async () => {
    prismaMock.users.findUnique.mockResolvedValue({
      id: TEST_USER.id,
      user_role: "admin",
    });
    prismaMock.reports.findUnique.mockResolvedValue(makeReportRow());
    prismaMock.reports.update.mockResolvedValue(
      makeReportRow({
        status: "resolved",
        reviewed_by: TEST_USER.id,
        reviewed_at: new Date("2026-04-29T11:00:00.000Z"),
        users_reports_reviewed_byTousers: reviewerUser,
      }),
    );

    const res = await request(app)
      .patch(`/api/reports/${REPORT_ID}/review`)
      .set("Authorization", makeAuthHeader(TEST_USER))
      .send({ status: "resolved" });

    expect(res.status).toBe(200);
    expect(res.body.report.status).toBe("resolved");
    expect(prismaMock.reports.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: REPORT_ID },
        data: expect.objectContaining({
          status: "resolved",
          reviewed_by: TEST_USER.id,
        }),
      }),
    );
  });

  it("400 – rejects invalid review status values", async () => {
    const res = await request(app)
      .patch(`/api/reports/${REPORT_ID}/review`)
      .set("Authorization", makeAuthHeader(TEST_USER))
      .send({ status: "pending" });

    expect(res.status).toBe(400);
    expect(prismaMock.reports.update).not.toHaveBeenCalled();
  });
});
