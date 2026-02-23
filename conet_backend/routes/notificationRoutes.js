import express from "express";
import {
  getNotifications,
  markAsSeen,
} from "../controllers/notificationController.js";
import { validateSupabaseToken } from "../middleware/validateSupabaseToken.js";

const router = express.Router();

router.use(validateSupabaseToken);

router.get("/", getNotifications);
router.post("/mark-seen", markAsSeen);

export default router;
