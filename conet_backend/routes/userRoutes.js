import express from "express";
import { searchUsers } from "../controllers/userController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

router.use(validateSupabaseToken);

router.get("/search", searchUsers);

export default router;
