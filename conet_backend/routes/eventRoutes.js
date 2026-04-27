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
  publishEvent,
  registerEvent,
  removeCohost,
  saveEvent,
  setupOrganizerResources,
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
router.get("/:id/registration-info", getRegistrationInfo);
router.get("/:id/attendees", getEventAttendees);
router.get("/:id/participants/export", exportEventParticipationXlsx);
router.post("/:id/attend", attendEvent);
router.post("/:id/save", saveEvent);
router.post("/:id/organizer-setup", setupOrganizerResources);

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
