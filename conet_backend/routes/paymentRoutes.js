import express from "express";
import {
  createOrganizerAccount,
  getOrganizerAccount,
  initiatePayment,
  verifyPaymentWebhook,
} from "../controllers/paymentController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

// All payment routes require a valid Supabase token (except webhook)
router.use(validateSupabaseToken);

// ─── Organizer account management ─────────────────────────────────────────────

// Create or update organizer account details (bank account for Razorpay)
router.post("/organizer-account", createOrganizerAccount);

// Get organizer account details
router.get("/organizer-account", getOrganizerAccount);

// ─── Payment flow ────────────────────────────────────────────────────────────

// Initiate payment for event registration
router.post("/:registrationId/initiate", initiatePayment);

// ─── Webhooks ────────────────────────────────────────────────────────────────

// Verify and process Razorpay payment webhook (no token required)
router.post("/webhook/verify", verifyPaymentWebhook);

export default router;
