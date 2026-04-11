import { describe, expect, it, mock } from "bun:test";
import request from "supertest";
import { TEST_JWT_SECRET } from "../mocks/authMock.js";
import { prismaMock } from "../mocks/prismaMock.js";

mock.module("../../config/prisma.js", () => ({ default: prismaMock }));
mock.module("../../config/queue.js", () => ({
  notificationQueue: {
    add: mock(() => Promise.resolve({ id: "job-1" })),
  },
  connection: {
    quit: mock(() => Promise.resolve()),
  },
}));
mock.module("../../services/paymentService.js", () => ({
  createOrganizerAccountService: mock(() => Promise.resolve({})),
  getOrganizerAccountService: mock(() => Promise.resolve({ id: "acct-1" })),
  initiatePaymentService: mock(() => Promise.resolve({ id: "payment-1" })),
  revertRegistrationAfterPaymentFailureService: mock(() =>
    Promise.resolve({ registration_id: "registration-1", rolled_back: true }),
  ),
  verifyPaymentWebhookService: mock(() =>
    Promise.resolve({ message: "Payment webhook processed" }),
  ),
  updateKycStatusWebhookService: mock(() =>
    Promise.resolve({ message: "KYC webhook processed" }),
  ),
}));

process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
process.env.NODE_ENV = "test";

import { createApp } from "../../app.js";

const app = createApp();

describe("Payment webhook routes", () => {
  it("POST /api/payments/webhook/payment-verification is public", async () => {
    const res = await request(app)
      .post("/api/payments/webhook/payment-verification")
      .send({ event: "payment.captured" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("POST /api/payments/webhook/kyc-status is public", async () => {
    const res = await request(app)
      .post("/api/payments/webhook/kyc-status")
      .send({ event: "account.activated" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("GET /api/payments/organizer-account requires auth", async () => {
    const res = await request(app).get("/api/payments/organizer-account");

    expect(res.status).toBe(401);
    expect(res.body.title).toBe("Unauthorized");
  });

  it("POST /api/payments/:registrationId/revert requires auth", async () => {
    const res = await request(app)
      .post("/api/payments/registration-1/revert")
      .send({ reason: "payment_failed" });

    expect(res.status).toBe(401);
    expect(res.body.title).toBe("Unauthorized");
  });
});
