import express from "express";
import {
  addCohost,
  cancelEvent,
  createEvent,
  getEvent,
  listCohosts,
  listMyEvents,
  listMyOrganizedEvents,
  listPublishedEvents,
  publishEvent,
  registerEvent,
  removeCohost,
  updateEvent,
} from "../controllers/eventController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

// All event routes require a valid Supabase token
router.use(validateSupabaseToken);

router.get("/", listPublishedEvents);
router.get("/organized", listMyOrganizedEvents);
router.get("/my", listMyEvents);
router.get("/:id", getEvent);
router.post("/:id/register", registerEvent);

// Organizer lifecycle
router.post("/", createEvent);
router.put("/:id", updateEvent);
router.patch("/:id/publish", publishEvent);
router.patch("/:id/cancel", cancelEvent);

// Co-host management
router.get("/:id/cohosts", listCohosts);
router.post("/:id/cohosts", addCohost);
router.delete("/:id/cohosts/:userId", removeCohost);

export default router;
