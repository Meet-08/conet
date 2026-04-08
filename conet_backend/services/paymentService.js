import prisma from "../config/prisma.js";
import razorpay from "../config/razorpay.js";

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
      razorpayAccountId: razorpayAccount.id,
      razorpayContactId: contact.id,
      razorpayFundAccountId: fundAccount.id,
      account_holder_name,
      account_number,
      ifsc_code,
      bank_name,
      pan,
      phone,
      updated_at: new Date(),
    },
    create: {
      organizer_id: organizerId,
      razorpayAccountId: razorpayAccount.id,
      razorpayContactId: contact.id,
      razorpayFundAccountId: fundAccount.id,
      account_holder_name,
      account_number,
      ifsc_code,
      bank_name,
      pan,
      phone,
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

/**
 * Initiate payment for event registration
 * Creates a Razorpay order and payment record in the database
 *
 * @param {string} userId - The user registering for the event
 * @param {string} registrationId - The event registration ID
 * @param {object} payload - Payment details (usually empty, derived from registration + event)
 *
 * @returns {object} Payment record with Razorpay order details
 *
 * TODO: Validate registration exists and is for a paid event
 * TODO: Get event details to extract amount and currency
 * TODO: Call Razorpay createOrder API with amount, currency, etc.
 * TODO: Create payment record in DB with razorpay_order_id
 * TODO: Return Razorpay order details for frontend to initialize payment form
 * TODO: Handle Razorpay API errors gracefully
 */
export const initiatePaymentService = async (
  userId,
  registrationId,
  payload,
) => {
  // Fetch registration to ensure it exists and user owns it
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

  // TODO: Check if payment already exists for this registration
  // If exists and status is pending, return existing order
  // If exists and status is completed, return error "Payment already completed"

  const eventId = registration.events.id;
  const amount = registration.events.amount;
  const currency = registration.events.currency || "INR";

  // TODO: Call Razorpay createOrder API
  // const razorpayOrder = await callRazorpayCreateOrder({
  //   amount: amount * 100, // Razorpay expects smallest currency unit
  //   currency,
  //   receipt: `reg_${registrationId}`,
  //   description: `Registration for ${registration.events.title}`,
  // });

  // For now, return a placeholder
  const razorpayOrder = {
    id: `order_${Date.now()}`, // TODO: Replace with actual Razorpay order ID
  };

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

  // TODO: Return Razorpay order details for frontend
  // Return minimal info needed by frontend to initialize Razorpay checkout
  return {
    payment_id: payment.id,
    razorpay_order_id: payment.razorpay_order_id,
    amount: Number(payment.amount),
    currency: payment.currency,
    // TODO: Include additional Razorpay order details from API response
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
export const verifyPaymentWebhookService = async (payload, headers) => {
  // TODO: Implement webhook signature verification
  // const isValid = verifyRazorpaySignature(payload, headers["x-razorpay-signature"]);
  // if (!isValid) {
  //   const err = new Error("Invalid webhook signature");
  //   err.statusCode = 403;
  //   throw err;
  // }

  // TODO: Extract from payload:
  // const { id, event } = payload;
  // if (event !== "payment.authorized") {
  //   return { message: "Event not relevant", event };
  // }

  // TODO: Extract payment details:
  // const { razorpay_payment_id, razorpay_order_id } = payload.payload.payment.entity;

  // TODO: Find payment record by razorpay_order_id
  // const payment = await prisma.event_payments.findUnique({
  //   where: { razorpay_order_id },
  // });

  // TODO: Update payment status to "completed"
  // const updatedPayment = await prisma.event_payments.update({
  //   where: { id: payment.id },
  //   data: {
  //     razorpay_payment_id,
  //     razorpay_signature: headers["x-razorpay-signature"],
  //     payment_status: "completed",
  //     updated_at: new Date(),
  //   },
  // });

  // TODO: Update event_registration status if needed
  // Check event_registrations schema to see what status field should be set

  // TODO: Consider sending confirmation notification to user
  // notificationService.createNotification(...)

  // For now, return placeholder
  return {
    message: "Webhook processed",
    // TODO: Return actual webhook processing result
  };
};
