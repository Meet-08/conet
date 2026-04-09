import crypto from "crypto";
import prisma from "../config/prisma.js";
import razorpay from "../config/razorpay.js";

const VERIFIED_KYC_STATUSES = new Set([
  "activated",
  "verified",
  "approved",
  "live",
  "completed",
]);

const REJECTED_KYC_STATUSES = new Set([
  "rejected",
  "failed",
  "suspended",
  "disabled",
  "needs_clarification",
]);

const SUPPORTED_PAYMENT_EVENTS = new Set([
  "payment.authorized",
  "payment.captured",
  "payment.failed",
]);

const buildStatusError = (message, statusCode) => {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
};

const serializeWebhookPayload = (payload, rawPayload) => {
  if (typeof rawPayload === "string" && rawPayload.length > 0) {
    return rawPayload;
  }

  return JSON.stringify(payload ?? {});
};

const verifyWebhookSignature = (payload, headers, rawPayload) => {
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!webhookSecret) {
    throw buildStatusError("Webhook secret is not configured", 500);
  }

  const signature = headers?.["x-razorpay-signature"];
  if (!signature) {
    throw buildStatusError("Missing webhook signature", 400);
  }

  const message = serializeWebhookPayload(payload, rawPayload);
  const expectedSignature = crypto
    .createHmac("sha256", webhookSecret)
    .update(message)
    .digest("hex");

  const signatureBuffer = Buffer.from(signature, "utf8");
  const expectedBuffer = Buffer.from(expectedSignature, "utf8");

  const isValidSignature =
    signatureBuffer.length === expectedBuffer.length &&
    crypto.timingSafeEqual(signatureBuffer, expectedBuffer);

  if (!isValidSignature) {
    throw buildStatusError("Invalid webhook signature", 403);
  }
};

const mapKycVerificationStatus = (event, accountEntity) => {
  const accountStatus = String(
    accountEntity?.kyc_status ?? accountEntity?.status ?? "",
  ).toLowerCase();

  if (VERIFIED_KYC_STATUSES.has(accountStatus)) {
    return "verified";
  }

  if (REJECTED_KYC_STATUSES.has(accountStatus)) {
    return "rejected";
  }

  const eventName = String(event ?? "").toLowerCase();
  if (
    eventName.includes("activated") ||
    eventName.includes("verified") ||
    eventName.includes("approved")
  ) {
    return "verified";
  }

  if (
    eventName.includes("rejected") ||
    eventName.includes("failed") ||
    eventName.includes("suspended")
  ) {
    return "rejected";
  }

  return "pending";
};

// ─── Organizer Account Management ──────────────────────────────────────────
export const createOrganizerAccountService = async (organizerId, payload) => {
  const requiredFields = [
    "account_holder_name",
    "account_number",
    "ifsc_code",
    "bank_name",
    "pan",
    "email",
    "phone",
    "title",
  ];

  for (const field of requiredFields) {
    if (!payload[field]) {
      const err = new Error(`Missing required field: ${field}`);
      err.statusCode = 400;
      throw err;
    }
  }

  if (!/^[A-Z]{5}[0-9]{4}[A-Z]$/.test(payload.pan.toUpperCase())) {
    throw new Error("Invalid PAN format");
  }

  if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(payload.ifsc_code.toUpperCase())) {
    throw new Error("Invalid IFSC format");
  }

  if (!/^\d{9,18}$/.test(String(payload.account_number))) {
    throw new Error("Invalid account number format");
  }

  const {
    email,
    title,
    account_holder_name,
    street1,
    street2,
    city,
    state,
    postal_code,
    account_number,
    ifsc_code,
    bank_name,
    pan,
    phone,
  } = payload;

  const address = {
    street1: street1 ?? "",
    street2: street2 ?? "",
    city: city ?? "",
    state: state ?? "",
    postal_code: postal_code ?? "",
    country: "IN",
  };

  const razorpayAccount = await razorpay.accounts.create({
    contact_name: account_holder_name,
    email,
    phone,
    legal_business_name: title,
    business_type: "individual",
    type: "route",
    profile: {
      category: "events",
      subcategory: "event_management",
      addresses: {
        registered: {
          street1,
          street2,
          city,
          state,
          postal_code,
          country: "IN",
        },
      },
    },
    legal_info: { pan },
  });

  await razorpay.products.request(razorpayAccount.id, {
    product_name: "route",
  });

  const contact = await razorpay.contacts.create({
    name: account_holder_name,
    email,
    contact: phone,
    type: "vendor",
    reference_id: razorpayAccount.id,
  });

  const fundAccount = await razorpay.fundAccount.create({
    contact_id: contact.id,
    account_type: "bank_account",
    bank_account: {
      name: account_holder_name,
      ifsc: ifsc_code,
      account_number,
    },
  });

  const account = await prisma.organizer_account_details.upsert({
    where: { organizer_id: organizerId },
    update: {
      razorpay_account_id: razorpayAccount.id,
      account_holder_name,
      account_number,
      ifsc_code,
      bank_name,
      pan,
      phone,
      address,
      updated_at: new Date(),
    },
    create: {
      organizer_id: organizerId,
      razorpay_account_id: razorpayAccount.id,
      account_holder_name,
      account_number,
      ifsc_code,
      bank_name,
      pan,
      phone,
      address,
      verification_status: "pending",
    },
  });

  return account;
};

export const getOrganizerAccountService = async (organizerId) => {
  const account = await prisma.organizer_account_details.findUnique({
    where: { organizer_id: organizerId },
    include: {
      users: {
        select: {
          id: true,
          email: true,
          first_name: true,
          last_name: true,
        },
      },
    },
  });

  if (!account) {
    const err = new Error("Organizer account not found");
    err.statusCode = 404;
    throw err;
  }

  return account;
};

// ─── Payment Initiation ────────────────────────────────────────────────────
export const initiatePaymentService = async (
  userId,
  registrationId,
  payload,
) => {
  const registration = await prisma.event_registrations.findUnique({
    where: { id: registrationId },
    include: {
      events: {
        select: {
          id: true,
          title: true,
          amount: true,
          currency: true,
          organizer_id: true,
        },
      },
    },
  });

  if (!registration) {
    const err = new Error("Registration not found");
    err.statusCode = 404;
    throw err;
  }

  if (registration.user_id !== userId) {
    const err = new Error("Unauthorized: Registration belongs to another user");
    err.statusCode = 403;
    throw err;
  }

  // Verify event is paid
  if (!registration.events.amount || registration.events.amount <= 0) {
    const err = new Error("Event is not a paid event");
    err.statusCode = 400;
    throw err;
  }

  // Check if payment already exists for this registration
  const existingPayment = await prisma.event_payments.findFirst({
    where: { registration_id: registrationId },
  });

  if (existingPayment) {
    if (existingPayment.payment_status === "pending") {
      return {
        payment_id: existingPayment.id,
        razorpay_order_id: existingPayment.razorpay_order_id,
        amount: Number(existingPayment.amount),
        currency: existingPayment.currency,
        message: "Existing pending payment returned",
      };
    }
    if (existingPayment.payment_status === "completed") {
      const err = new Error("Payment already completed");
      err.statusCode = 400;
      throw err;
    }
  }

  const eventId = registration.events.id;
  const amount = registration.events.amount;
  const currency = registration.events.currency || "INR";
  const organizerAccount = await prisma.organizer_account_details.findUnique({
    where: { organizer_id: registration.events.organizer_id },
  });

  if (!organizerAccount) {
    const err = new Error("Organizer account details not found");
    err.statusCode = 500;
    throw err;
  }

  const razorpayOrder = await razorpay.orders.create({
    amount: amount * 100, // Convert to paise
    currency,
    receipt: `receipt_${registrationId}`,
    transfers: [
      {
        account: organizerAccount.razorpay_account_id,
        amount: amount * 100, // Full amount to organizer for now
        currency,
      },
    ],
  });

  // Create payment record
  const payment = await prisma.event_payments.create({
    data: {
      registration_id: registrationId,
      event_id: eventId,
      user_id: userId,
      amount,
      currency,
      razorpay_order_id: razorpayOrder.id,
      payment_status: "pending",
    },
    include: {
      events: {
        select: {
          id: true,
          title: true,
          amount: true,
          currency: true,
        },
      },
      users: {
        select: {
          id: true,
          email: true,
          first_name: true,
          last_name: true,
        },
      },
    },
  });

  return {
    payment_id: payment.id,
    razorpay_order_id: razorpayOrder.id,
    amount: Number(payment.amount),
    currency: payment.currency,
    razorpay_order_details: {
      id: razorpayOrder.id,
      entity: razorpayOrder.entity,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      status: razorpayOrder.status,
      receipt: razorpayOrder.receipt,
      created_at: razorpayOrder.created_at,
    },
  };
};

// ─── Webhook Verification ────────────────────────────────────────────────

/**
 * Verify and process Razorpay payment webhook
 * Called by Razorpay when payment succeeds/fails
 *
 * @param {object} payload - Webhook payload from Razorpay
 * @param {object} headers - Request headers containing signature
 *
 * @returns {object} Payment update result
 *
 * TODO: Verify webhook signature using RAZORPAY_WEBHOOK_SECRET
 * TODO: Extract payment_id and order_id from payload
 * TODO: Verify payment and order IDs exist in our DB
 * TODO: Update payment_status based on webhook event (payment.authorized)
 * TODO: Update event_registration status if payment is successful
 * TODO: Consider idempotency - handle duplicate webhooks gracefully
 * TODO: Log webhook events for debugging
 * TODO: Handle payment failures (optional refund logic)
 */
export const verifyPaymentWebhookService = async (
  payload,
  headers,
  rawPayload,
) => {
  verifyWebhookSignature(payload, headers, rawPayload);

  const event = payload?.event;
  if (!SUPPORTED_PAYMENT_EVENTS.has(event)) {
    return {
      message: "Event ignored",
      event,
    };
  }

  const paymentEntity = payload?.payload?.payment?.entity;
  const razorpayOrderId = paymentEntity?.order_id;
  const razorpayPaymentId = paymentEntity?.id;

  if (!razorpayOrderId || !razorpayPaymentId) {
    throw buildStatusError("Invalid payment webhook payload", 400);
  }

  const payment = await prisma.event_payments.findFirst({
    where: { razorpay_order_id: razorpayOrderId },
  });

  if (!payment) {
    return {
      message: "Payment not found for Razorpay order",
      event,
      razorpay_order_id: razorpayOrderId,
      ignored: true,
    };
  }

  const paymentStatus = event === "payment.failed" ? "failed" : "completed";
  const signature = headers?.["x-razorpay-signature"];

  const updatedPayment = await prisma.event_payments.update({
    where: { id: payment.id },
    data: {
      razorpay_payment_id: razorpayPaymentId,
      razorpay_signature: signature,
      payment_status: paymentStatus,
      updated_at: new Date(),
    },
  });

  return {
    message: "Payment webhook processed",
    event,
    payment_id: updatedPayment.id,
    payment_status: updatedPayment.payment_status,
    razorpay_order_id: razorpayOrderId,
    razorpay_payment_id: razorpayPaymentId,
  };
};

export const updateKycStatusWebhookService = async (
  payload,
  headers,
  rawPayload,
) => {
  verifyWebhookSignature(payload, headers, rawPayload);

  const event = payload?.event;
  const accountEntity = payload?.payload?.account?.entity;
  const razorpayAccountId = accountEntity?.id;

  if (!razorpayAccountId) {
    throw buildStatusError("Invalid KYC webhook payload", 400);
  }

  const verificationStatus = mapKycVerificationStatus(event, accountEntity);

  const organizerAccount = await prisma.organizer_account_details.findFirst({
    where: { razorpay_account_id: razorpayAccountId },
  });

  if (!organizerAccount) {
    return {
      message: "Organizer account not found for Razorpay account",
      event,
      razorpay_account_id: razorpayAccountId,
      ignored: true,
    };
  }

  const updatedAccount = await prisma.organizer_account_details.update({
    where: { id: organizerAccount.id },
    data: {
      verification_status: verificationStatus,
      updated_at: new Date(),
    },
  });

  return {
    message: "KYC webhook processed",
    event,
    organizer_id: updatedAccount.organizer_id,
    razorpay_account_id: updatedAccount.razorpay_account_id,
    verification_status: updatedAccount.verification_status,
  };
};
