import express from "express";
import {
  createConversation,
  getConversations,
  getMessages,
  markAsRead,
  searchUsers,
  sendMessage,
} from "../controllers/conversationController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

// All conversation routes require authentication
router.use(validateSupabaseToken);

// Search must come before /:conversationId to avoid param collision
router.get("/search_users", searchUsers);

router.post("/", createConversation);
router.get("/", getConversations);
router.get("/:conversationId/messages", getMessages);
router.post("/:conversationId/messages", sendMessage);
router.post("/:conversationId/mark_as_read", markAsRead);

export default router;
