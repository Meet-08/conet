import express from "express";
import {
  createOrganizerAccount,
  getOrganizerAccount,
  initiatePayment,
  revertRegistrationAfterPaymentFailure,
  updateKycStatusWebhook,
  verifyPaymentWebhook,
} from "../controllers/paymentController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

// ─── Webhooks (public, signature-verified) ─────────────────────────────────

router.post("/webhook/payment-verification", verifyPaymentWebhook);
router.post("/webhook/kyc-status", updateKycStatusWebhook);

// Backward-compatible alias for existing clients.
router.post("/webhook/verify", verifyPaymentWebhook);

// All non-webhook payment routes require a valid Supabase token.
router.use(validateSupabaseToken);

// ─── Organizer account management ─────────────────────────────────────────────

// Create or update organizer account details (bank account for Razorpay)
router.post("/organizer-account", createOrganizerAccount);

// Get organizer account details
router.get("/organizer-account", getOrganizerAccount);

// ─── Payment flow ────────────────────────────────────────────────────────────

// Initiate payment for event registration
router.post("/:registrationId/initiate", initiatePayment);

// Revert registration when payment fails/cancels or checkout cannot be opened
router.post("/:registrationId/revert", revertRegistrationAfterPaymentFailure);

export default router;
