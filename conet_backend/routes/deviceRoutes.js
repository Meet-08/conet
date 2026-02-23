import express from "express";
import {
  registerDevice,
  removeDevice,
} from "../controllers/deviceController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

router.post("/register", validateSupabaseToken, registerDevice);
router.delete("/current", validateSupabaseToken, removeDevice);

export default router;
