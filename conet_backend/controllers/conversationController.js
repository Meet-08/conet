import asyncHandler from "express-async-handler";
import {
  createConversationService,
  getConversationsService,
  getMessagesService,
  markAsReadService,
  searchUsersService,
  sendMessageService,
} from "../services/conversationService.js";

// POST /api/conversations?other_user={userId}
export const createConversation = asyncHandler(async (req, res) => {
  const otherUserId = req.query.other_user;
  const currentUserId = req.user.id;

  if (!otherUserId) {
    res.status(400);
    throw new Error("other_user query parameter is required");
  }

  const conversation = await createConversationService(
    currentUserId,
    otherUserId,
  );

  res.status(201).json({
    success: true,
    conversation,
  });
});

// GET /api/conversations
export const getConversations = asyncHandler(async (req, res) => {
  const currentUserId = req.user.id;
  const conversations = await getConversationsService(currentUserId);

  res.status(200).json(conversations);
});

// GET /api/conversations/:conversationId/messages?limit=20
export const getMessages = asyncHandler(async (req, res) => {
  const { conversationId } = req.params;
  const limit = parseInt(req.query.limit) || 20;

  const messages = await getMessagesService(conversationId, limit);

  res.status(200).json(messages);
});

// POST /api/conversations/:conversationId/messages  { content }
export const sendMessage = asyncHandler(async (req, res) => {
  const { conversationId } = req.params;
  const { content, mediaUrls } = req.body;
  const senderId = req.user.id;

  if (!content) {
    res.status(400);
    throw new Error("content is required");
  }

  const message = await sendMessageService(
    conversationId,
    senderId,
    content,
    mediaUrls,
  );

  res.status(201).json({
    success: true,
    message,
  });
});

// POST /api/conversations/:conversationId/mark_as_read
export const markAsRead = asyncHandler(async (req, res) => {
  const { conversationId } = req.params;
  const currentUserId = req.user.id;

  await markAsReadService(conversationId, currentUserId);

  res.status(200).json({ success: true });
});

// GET /api/conversations/search_users?query=...&limit=3
export const searchUsers = asyncHandler(async (req, res) => {
  const { query } = req.query;
  const limit = parseInt(req.query.limit) || 3;
  const currentUserId = req.user.id;

  if (!query) {
    res.status(400);
    throw new Error("query parameter is required");
  }

  const users = await searchUsersService(query, limit, currentUserId);

  res.status(200).json(users);
});
