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

// GET /api/conversations/:conversationId/messages?limit=20&before=ISO_DATETIME
export const getMessages = asyncHandler(async (req, res) => {
  const { conversationId } = req.params;
  const parsedLimit = parseInt(req.query.limit, 10);
  const limit =
    Number.isNaN(parsedLimit) ? 20 : Math.min(Math.max(parsedLimit, 1), 50);

  let before;
  if (req.query.before) {
    before = new Date(req.query.before);
    if (Number.isNaN(before.getTime())) {
      res.status(400);
      throw new Error("before must be a valid ISO datetime");
    }
  }

  const result = await getMessagesService(conversationId, { limit, before });

  res.status(200).json({
    messages: result.messages,
    next_before: result.nextBefore,
    has_more: result.hasMore,
  });
});

// POST /api/conversations/:conversationId/messages  { content, mediaUrls }
export const sendMessage = asyncHandler(async (req, res) => {
  const { conversationId } = req.params;
  const { content, mediaUrls } = req.body;
  const senderId = req.user.id;

  if (!content && (!mediaUrls || mediaUrls.length === 0)) {
    res.status(400);
    throw new Error("content or mediaUrls is required");
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
