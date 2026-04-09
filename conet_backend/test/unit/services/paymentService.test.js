import { beforeEach, describe, expect, it, mock } from "bun:test";
import crypto from "crypto";

const prismaMock = {
  event_payments: {
    findFirst: mock(() => Promise.resolve(null)),
    update: mock(() => Promise.resolve({})),
  },
  organizer_account_details: {
    findFirst: mock(() => Promise.resolve(null)),
    update: mock(() => Promise.resolve({})),
  },
};

const razorpayMock = {
  accounts: { create: mock(() => Promise.resolve({ id: "acc_1" })) },
  products: { request: mock(() => Promise.resolve({})) },
  contacts: { create: mock(() => Promise.resolve({ id: "cont_1" })) },
  fundAccount: { create: mock(() => Promise.resolve({ id: "fa_1" })) },
  orders: { create: mock(() => Promise.resolve({ id: "order_1" })) },
};

mock.module("../../../config/prisma.js", () => ({ default: prismaMock }));
mock.module("../../../config/razorpay.js", () => ({ default: razorpayMock }));

import {
  updateKycStatusWebhookService,
  verifyPaymentWebhookService,
} from "../../../services/paymentService.js";

const makeSignature = (rawPayload) =>
  crypto
    .createHmac("sha256", process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(rawPayload)
    .digest("hex");

beforeEach(() => {
  prismaMock.event_payments.findFirst.mockReset();
  prismaMock.event_payments.findFirst.mockResolvedValue(null);
  prismaMock.event_payments.update.mockReset();
  prismaMock.event_payments.update.mockResolvedValue({
    id: "payment-1",
    payment_status: "completed",
  });

  prismaMock.organizer_account_details.findFirst.mockReset();
  prismaMock.organizer_account_details.findFirst.mockResolvedValue(null);
  prismaMock.organizer_account_details.update.mockReset();
  prismaMock.organizer_account_details.update.mockResolvedValue({
    id: "organizer-account-1",
    organizer_id: "organizer-1",
    razorpay_account_id: "acc_123",
    verification_status: "verified",
  });

  process.env.RAZORPAY_WEBHOOK_SECRET = "webhook-secret";
});

describe("verifyPaymentWebhookService", () => {
  it("updates payment status to completed for payment.captured events", async () => {
    const rawPayload = JSON.stringify({
      event: "payment.captured",
      payload: {
        payment: {
          entity: {
            id: "pay_123",
            order_id: "order_123",
          },
        },
      },
    });
    const payload = JSON.parse(rawPayload);

    prismaMock.event_payments.findFirst.mockResolvedValue({
      id: "payment-1",
      razorpay_order_id: "order_123",
      payment_status: "pending",
    });

    prismaMock.event_payments.update.mockResolvedValue({
      id: "payment-1",
      payment_status: "completed",
    });

    const result = await verifyPaymentWebhookService(
      payload,
      {
        "x-razorpay-signature": makeSignature(rawPayload),
      },
      rawPayload,
    );

    expect(prismaMock.event_payments.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "payment-1" },
        data: expect.objectContaining({
          razorpay_payment_id: "pay_123",
          payment_status: "completed",
        }),
      }),
    );
    expect(result.payment_status).toBe("completed");
  });

  it("returns ignored response for unsupported events", async () => {
    const rawPayload = JSON.stringify({ event: "order.created" });

    const result = await verifyPaymentWebhookService(
      JSON.parse(rawPayload),
      {
        "x-razorpay-signature": makeSignature(rawPayload),
      },
      rawPayload,
    );

    expect(result).toEqual({
      event: "order.created",
      message: "Event ignored",
    });
    expect(prismaMock.event_payments.findFirst).not.toHaveBeenCalled();
  });

  it("throws 403 for invalid signatures", async () => {
    const rawPayload = JSON.stringify({
      event: "payment.captured",
      payload: {
        payment: {
          entity: {
            id: "pay_123",
            order_id: "order_123",
          },
        },
      },
    });

    await expect(
      verifyPaymentWebhookService(
        JSON.parse(rawPayload),
        {
          "x-razorpay-signature": "invalid-signature",
        },
        rawPayload,
      ),
    ).rejects.toMatchObject({
      message: "Invalid webhook signature",
      statusCode: 403,
    });
  });
});

describe("updateKycStatusWebhookService", () => {
  it("updates organizer verification status from KYC webhook", async () => {
    const rawPayload = JSON.stringify({
      event: "account.activated",
      payload: {
        account: {
          entity: {
            id: "acc_123",
            status: "activated",
          },
        },
      },
    });

    prismaMock.organizer_account_details.findFirst.mockResolvedValue({
      id: "organizer-account-1",
      organizer_id: "organizer-1",
      razorpay_account_id: "acc_123",
      verification_status: "pending",
    });

    const result = await updateKycStatusWebhookService(
      JSON.parse(rawPayload),
      {
        "x-razorpay-signature": makeSignature(rawPayload),
      },
      rawPayload,
    );

    expect(prismaMock.organizer_account_details.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "organizer-account-1" },
        data: expect.objectContaining({ verification_status: "verified" }),
      }),
    );
    expect(result.verification_status).toBe("verified");
  });

  it("returns ignored response when organizer account is missing", async () => {
    const rawPayload = JSON.stringify({
      event: "account.updated",
      payload: {
        account: {
          entity: {
            id: "acc_unknown",
            status: "under_review",
          },
        },
      },
    });

    const result = await updateKycStatusWebhookService(
      JSON.parse(rawPayload),
      {
        "x-razorpay-signature": makeSignature(rawPayload),
      },
      rawPayload,
    );

    expect(result).toEqual({
      event: "account.updated",
      ignored: true,
      message: "Organizer account not found for Razorpay account",
      razorpay_account_id: "acc_unknown",
    });
  });
});
