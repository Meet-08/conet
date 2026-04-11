import { beforeAll, beforeEach, describe, expect, it, mock } from "bun:test";
import crypto from "crypto";

const prismaMock = {
  event_payments: {
    findFirst: mock(() => Promise.resolve(null)),
    create: mock(() => Promise.resolve({})),
    delete: mock(() => Promise.resolve({})),
    update: mock(() => Promise.resolve({})),
  },
  event_registrations: {
    findUnique: mock(() => Promise.resolve(null)),
    delete: mock(() => Promise.resolve({})),
    update: mock(() => Promise.resolve({})),
    updateMany: mock(() => Promise.resolve({ count: 0 })),
    count: mock(() => Promise.resolve(0)),
  },
  event_team_members: {
    deleteMany: mock(() => Promise.resolve({ count: 0 })),
  },
  event_teams: {
    deleteMany: mock(() => Promise.resolve({ count: 0 })),
  },
  organizer_account_details: {
    findFirst: mock(() => Promise.resolve(null)),
    findUnique: mock(() => Promise.resolve(null)),
    update: mock(() => Promise.resolve({})),
  },
  $transaction: mock((fn) => fn(prismaMock)),
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

let verifyPaymentWebhookService;
let updateKycStatusWebhookService;
let revertRegistrationAfterPaymentFailureService;
let initiatePaymentService;

beforeAll(async () => {
  ({
    initiatePaymentService,
    verifyPaymentWebhookService,
    updateKycStatusWebhookService,
    revertRegistrationAfterPaymentFailureService,
  } = await import("../../../services/paymentService.js?unit-payment-service"));
});

const makeSignature = (rawPayload) =>
  crypto
    .createHmac("sha256", process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(rawPayload)
    .digest("hex");

beforeEach(() => {
  prismaMock.event_payments.findFirst.mockReset();
  prismaMock.event_payments.findFirst.mockResolvedValue(null);
  prismaMock.event_payments.create.mockReset();
  prismaMock.event_payments.create.mockResolvedValue({
    id: "payment-1",
    amount: 499,
    currency: "INR",
  });
  prismaMock.event_payments.delete.mockReset();
  prismaMock.event_payments.delete.mockResolvedValue({ id: "payment-1" });
  prismaMock.event_payments.update.mockReset();
  prismaMock.event_payments.update.mockResolvedValue({
    id: "payment-1",
    payment_status: "completed",
  });

  prismaMock.organizer_account_details.findFirst.mockReset();
  prismaMock.organizer_account_details.findFirst.mockResolvedValue(null);
  prismaMock.organizer_account_details.findUnique.mockReset();
  prismaMock.organizer_account_details.findUnique.mockResolvedValue(null);
  prismaMock.organizer_account_details.update.mockReset();
  prismaMock.organizer_account_details.update.mockResolvedValue({
    id: "organizer-account-1",
    organizer_id: "organizer-1",
    razorpay_account_id: "acc_123",
    verification_status: "verified",
  });

  prismaMock.event_registrations.findUnique.mockReset();
  prismaMock.event_registrations.findUnique.mockResolvedValue(null);
  prismaMock.event_registrations.delete.mockReset();
  prismaMock.event_registrations.delete.mockResolvedValue({
    id: "registration-1",
  });
  prismaMock.event_registrations.update.mockReset();
  prismaMock.event_registrations.update.mockResolvedValue({
    id: "registration-1",
    registration_status: "cancelled",
  });
  prismaMock.event_registrations.updateMany.mockReset();
  prismaMock.event_registrations.updateMany.mockResolvedValue({ count: 1 });
  prismaMock.event_registrations.count.mockReset();
  prismaMock.event_registrations.count.mockResolvedValue(0);

  prismaMock.event_team_members.deleteMany.mockReset();
  prismaMock.event_team_members.deleteMany.mockResolvedValue({ count: 0 });
  prismaMock.event_teams.deleteMany.mockReset();
  prismaMock.event_teams.deleteMany.mockResolvedValue({ count: 0 });

  prismaMock.$transaction.mockReset();
  prismaMock.$transaction.mockImplementation((fn) => fn(prismaMock));

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

  it("marks registration cancelled when webhook reports payment.failed", async () => {
    const rawPayload = JSON.stringify({
      event: "payment.failed",
      payload: {
        payment: {
          entity: {
            id: "pay_failed_123",
            order_id: "order_failed_123",
          },
        },
      },
    });

    prismaMock.event_payments.findFirst.mockResolvedValue({
      id: "payment-1",
      registration_id: "registration-1",
      razorpay_order_id: "order_failed_123",
      payment_status: "pending",
    });

    prismaMock.event_payments.update.mockResolvedValue({
      id: "payment-1",
      payment_status: "failed",
    });

    const result = await verifyPaymentWebhookService(
      JSON.parse(rawPayload),
      {
        "x-razorpay-signature": makeSignature(rawPayload),
      },
      rawPayload,
    );

    expect(prismaMock.event_registrations.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ id: "registration-1" }),
        data: expect.objectContaining({ registration_status: "cancelled" }),
      }),
    );
    expect(result.payment_status).toBe("failed");
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

describe("initiatePaymentService", () => {
  it("creates Razorpay order using event price and INR currency", async () => {
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: "registration-1",
      user_id: "user-1",
      events: {
        id: "event-1",
        title: "Hackathon",
        ticket_price_type: "PAID",
        price: 499,
        organizer_id: "organizer-1",
      },
    });

    const result = await initiatePaymentService("user-1", "registration-1");

    const firstOrderCall = razorpayMock.orders.create.mock.calls[0]?.[0] ?? {};

    expect(firstOrderCall).toEqual(
      expect.objectContaining({
        amount: 49900,
        currency: "INR",
      }),
    );
    expect(firstOrderCall.receipt).toMatch(/^reg_[a-f0-9]{30}$/);
    expect(firstOrderCall.receipt.length).toBeLessThanOrEqual(40);
    expect(prismaMock.event_payments.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          amount: 499,
          currency: "INR",
          event_id: "event-1",
          user_id: "user-1",
        }),
      }),
    );
    expect(result.amount).toBe(499);
    expect(result.currency).toBe("INR");
  });

  it("keeps receipt within Razorpay length limit for UUID registration IDs", async () => {
    const registrationId = "8d3c95a6-fb87-4f60-99fc-4e0b7bcd9f51";

    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: registrationId,
      user_id: "user-1",
      events: {
        id: "event-1",
        title: "Hackathon",
        ticket_price_type: "PAID",
        price: 499,
        organizer_id: "organizer-1",
      },
    });

    await initiatePaymentService("user-1", registrationId);

    const firstOrderCall = razorpayMock.orders.create.mock.calls[0]?.[0] ?? {};
    expect(firstOrderCall.receipt).toMatch(/^reg_[a-f0-9]{30}$/);
    expect(firstOrderCall.receipt.length).toBeLessThanOrEqual(40);
  });

  it("throws when event is free or invalid priced", async () => {
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: "registration-1",
      user_id: "user-1",
      events: {
        id: "event-1",
        title: "Free Event",
        ticket_price_type: "FREE",
        price: null,
        organizer_id: "organizer-1",
      },
    });

    await expect(
      initiatePaymentService("user-1", "registration-1"),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Event is not a paid event",
    });
  });

  it("reuses failed payment row instead of creating a duplicate", async () => {
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: "registration-1",
      user_id: "user-1",
      events: {
        id: "event-1",
        title: "Hackathon",
        ticket_price_type: "PAID",
        price: 499,
        organizer_id: "organizer-1",
      },
    });

    prismaMock.event_payments.findFirst.mockResolvedValue({
      id: "payment-failed-1",
      registration_id: "registration-1",
      payment_status: "failed",
      amount: 499,
      currency: "INR",
    });

    prismaMock.event_payments.update.mockResolvedValue({
      id: "payment-failed-1",
      amount: 499,
      currency: "INR",
      payment_status: "pending",
    });

    const result = await initiatePaymentService("user-1", "registration-1");

    expect(prismaMock.event_payments.create).not.toHaveBeenCalled();
    expect(prismaMock.event_payments.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "payment-failed-1" },
        data: expect.objectContaining({
          payment_status: "pending",
          razorpay_payment_id: null,
          razorpay_signature: null,
        }),
      }),
    );
    expect(result.payment_id).toBe("payment-failed-1");
  });

  it("maps raw Razorpay object errors to readable 400 message", async () => {
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: "registration-1",
      user_id: "user-1",
      events: {
        id: "event-1",
        title: "Hackathon",
        ticket_price_type: "PAID",
        price: 499,
        organizer_id: "organizer-1",
      },
    });

    razorpayMock.orders.create.mockRejectedValueOnce({
      statusCode: 400,
      error: { description: "Receipt already exists" },
    });

    await expect(
      initiatePaymentService("user-1", "registration-1"),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Unable to initiate Razorpay payment: Receipt already exists",
    });
  });
});

describe("revertRegistrationAfterPaymentFailureService", () => {
  it("deletes registration and payment for failed flow", async () => {
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: "registration-1",
      user_id: "user-1",
      event_id: "event-1",
      team_id: null,
      registration_status: "registered",
      event_payments: {
        id: "payment-1",
        payment_status: "pending",
      },
    });

    const result = await revertRegistrationAfterPaymentFailureService(
      "user-1",
      "registration-1",
      "payment_failed",
    );

    expect(prismaMock.$transaction).toHaveBeenCalled();
    expect(prismaMock.event_payments.delete).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "payment-1" },
      }),
    );
    expect(prismaMock.event_registrations.delete).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "registration-1" },
      }),
    );
    expect(result.rolled_back).toBe(true);
    expect(result.registration_deleted).toBe(true);
    expect(result.payment_deleted).toBe(true);
  });

  it("deletes team records when no registrations remain for team", async () => {
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: "registration-1",
      user_id: "user-1",
      event_id: "event-1",
      team_id: "team-1",
      registration_status: "registered",
      event_payments: {
        id: "payment-1",
        payment_status: "failed",
      },
    });

    prismaMock.event_registrations.count.mockResolvedValue(0);

    const result = await revertRegistrationAfterPaymentFailureService(
      "user-1",
      "registration-1",
      "payment_failed",
    );

    expect(prismaMock.event_team_members.deleteMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { team_id: "team-1" },
      }),
    );
    expect(prismaMock.event_teams.deleteMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ id: "team-1", event_id: "event-1" }),
      }),
    );
    expect(result.team_deleted).toBe(true);
  });

  it("throws 409 when payment is already completed", async () => {
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: "registration-1",
      user_id: "user-1",
      registration_status: "registered",
      event_payments: {
        id: "payment-1",
        payment_status: "completed",
      },
    });

    await expect(
      revertRegistrationAfterPaymentFailureService("user-1", "registration-1"),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "Cannot revert registration after successful payment",
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
