import asyncHandler from "express-async-handler";
import {
  addGroupMemberService,
  createConversationService,
  createGroupService,
  deleteGroupService,
  getConversationsService,
  getGroupMembersService,
  getMessagesService,
  markAsReadService,
  removeGroupMemberService,
  searchUsersService,
  sendMessageService,
  updateGroupService,
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

// GET /api/conversations?type=all|direct|group
export const getConversations = asyncHandler(async (req, res) => {
  const currentUserId = req.user.id;
  const { type = "all", search } = req.query;

  if (!["all", "direct", "group"].includes(type)) {
    res.status(400);
    throw new Error("type must be one of: all, direct, group");
  }

  const conversations = await getConversationsService(
    currentUserId,
    type,
    search,
  );

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

// ─── Group conversations ────────────────────────────────────────────────────────

// POST /api/groups
// Body: { name, memberIds: string[], groupImageUrl? }
export const createGroup = asyncHandler(async (req, res) => {
  const currentUserId = req.user.id;
  const { name, memberIds, groupImageUrl } = req.body;

  if (!name) {
    res.status(400);
    throw new Error("name is required");
  }

  if (!Array.isArray(memberIds) || memberIds.length === 0) {
    res.status(400);
    throw new Error("memberIds must be a non-empty array");
  }

  const group = await createGroupService(currentUserId, {
    name,
    memberIds,
    groupImageUrl,
  });

  res.status(201).json({ success: true, group });
});

// GET /api/groups/:groupId/members
export const getGroupMembers = asyncHandler(async (req, res) => {
  const { groupId } = req.params;
  const currentUserId = req.user.id;

  const members = await getGroupMembersService(groupId, currentUserId);

  res.status(200).json(members);
});

// POST /api/groups/:groupId/members  { userId }
export const addGroupMember = asyncHandler(async (req, res) => {
  const { groupId } = req.params;
  const currentUserId = req.user.id;
  const { userId } = req.body;

  if (!userId) {
    res.status(400);
    throw new Error("userId is required");
  }

  const member = await addGroupMemberService(groupId, currentUserId, userId);

  res.status(201).json({ success: true, member });
});

// DELETE /api/groups/:groupId/members/:userId
export const removeGroupMember = asyncHandler(async (req, res) => {
  const { groupId, userId } = req.params;
  const currentUserId = req.user.id;

  await removeGroupMemberService(groupId, currentUserId, userId);

  res.status(200).json({ success: true });
});

// PATCH /api/groups/:groupId  { name?, groupImageUrl? }
export const updateGroup = asyncHandler(async (req, res) => {
  const { groupId } = req.params;
  const currentUserId = req.user.id;
  const { name, groupImageUrl } = req.body;

  const group = await updateGroupService(groupId, currentUserId, {
    name,
    groupImageUrl,
  });

  res.status(200).json({ success: true, group });
});

// DELETE /api/groups/:groupId
export const deleteGroup = asyncHandler(async (req, res) => {
  const { groupId } = req.params;
  const currentUserId = req.user.id;

  await deleteGroupService(groupId, currentUserId);

  res.status(200).json({ success: true });
});
