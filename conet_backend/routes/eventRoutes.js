import express from "express";
import {
  addCohost,
  attendEvent,
  cancelEvent,
  createEvent,
  exportEventParticipationXlsx,
  getEvent,
  getEventAttendees,
  getRegistrationInfo,
  listCohosts,
  listMyEvents,
  listMyOrganizedEvents,
  listPublishedEvents,
  promoteCohost,
  publishEvent,
  registerEvent,
  registerParticipant,
  removeCohost,
  saveEvent,
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
router.post("/:id/register-participant", registerParticipant);
router.get("/:id/registration-info", getRegistrationInfo);
router.get("/:id/attendees", getEventAttendees);
router.get("/:id/participants/export", exportEventParticipationXlsx);
router.post("/:id/attend", attendEvent);
router.post("/:id/save", saveEvent);

// Organizer lifecycle
router.post("/", createEvent);
router.put("/:id", updateEvent);
router.patch("/:id/publish", publishEvent);
router.patch("/:id/cancel", cancelEvent);

// Co-host management
router.get("/:id/cohosts", listCohosts);
router.post("/:id/cohosts", addCohost);
router.patch("/:id/cohosts/:userId/promote", promoteCohost);
router.delete("/:id/cohosts/:userId", removeCohost);

export default router;
