import asyncHandler from "express-async-handler";
import {
  createOrganizerAccountService,
  getOrganizerAccountService,
  initiatePaymentService,
  verifyPaymentWebhookService,
} from "../services/paymentService.js";

// ─── Create or update organizer account ────────────────────────────────────

export const createOrganizerAccount = asyncHandler(async (req, res) => {
  await createOrganizerAccountService(req.user.id, req.body);
  res.status(201).json({
    success: true,
    message: "Organizer account created/updated successfully",
  });
});

// ─── Get organizer account ────────────────────────────────────────────────

export const getOrganizerAccount = asyncHandler(async (req, res) => {
  const account = await getOrganizerAccountService(req.user.id);
  res.status(200).json({
    success: true,
    account,
  });
});

// ─── Initiate payment for event registration ───────────────────────────────

export const initiatePayment = asyncHandler(async (req, res) => {
  const payment = await initiatePaymentService(
    req.user.id,
    req.params.registrationId,
    req.body,
  );
  res.status(201).json({
    success: true,
    message: "Payment initiated successfully",
    payment,
  });
});

// ─── Verify payment webhook ────────────────────────────────────────────────

export const verifyPaymentWebhook = asyncHandler(async (req, res) => {
  const result = await verifyPaymentWebhookService(req.body, req.headers);
  res.status(200).json({
    success: true,
    message: "Payment webhook processed successfully",
    result,
  });
});
