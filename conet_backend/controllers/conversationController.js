import asyncHandler from "express-async-handler";
import {
  addGroupMemberService,
  createConversationService,
  createGroupService,
  deleteGroupService,
  demoteGroupMemberService,
  getConversationSharedService,
  getConversationsService,
  getGroupMembersService,
  getMessagesService,
  markAsReadService,
  promoteGroupMemberService,
  removeGroupMemberService,
  searchUsersService,
  sendMessageService,
  updateGroupService,
} from "../services/conversationService.js";

const assertOptionalBoolean = (value, fieldName) => {
  if (value !== undefined && typeof value !== "boolean") {
    const err = new Error(`${fieldName} must be a boolean when provided`);
    err.statusCode = 400;
    throw err;
  }
};

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

  const result = await getMessagesService(
    conversationId,
    { limit, before },
    req.user.id,
  );

  res.status(200).json({
    messages: result.messages,
    next_before: result.nextBefore,
    has_more: result.hasMore,
  });
});

// GET /api/conversations/:conversationId/shared?type=media|post|docs&limit=20&before=ISO_DATETIME
export const getConversationShared = asyncHandler(async (req, res) => {
  const { conversationId } = req.params;
  const { type } = req.query;

  if (!type) {
    res.status(400);
    throw new Error("type query parameter is required");
  }

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

  const result = await getConversationSharedService(
    conversationId,
    req.user.id,
    type,
    { limit, before },
  );

  res.status(200).json({
    items: result.items,
    next_before: result.nextBefore,
    has_more: result.hasMore,
  });
});

// POST /api/conversations/:conversationId/messages  { content, mediaUrls, is_post, post_id }
export const sendMessage = asyncHandler(async (req, res) => {
  const { conversationId } = req.params;
  const { content, mediaUrls, is_post, post_id } = req.body;
  const senderId = req.user.id;

  if (!content && (!mediaUrls || mediaUrls.length === 0) && !is_post) {
    res.status(400);
    throw new Error("content, mediaUrls, or is_post is required");
  }

  const message = await sendMessageService(
    conversationId,
    senderId,
    content,
    mediaUrls,
    is_post,
    post_id,
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
// Body: { name, memberIds: string[], groupImageUrl?, description?, onlyAdminAddMembers?, onlyAdminRemoveMembers?, onlyAdminEditGroup?, onlyAdminSendMessages?, isEvent? }
export const createGroup = asyncHandler(async (req, res) => {
  const currentUserId = req.user.id;
  const {
    name,
    memberIds,
    groupImageUrl,
    description,
    onlyAdminAddMembers,
    onlyAdminRemoveMembers,
    onlyAdminEditGroup,
    onlyAdminSendMessages,
    isEvent,
    is_event,
  } = req.body;

  if (!name) {
    res.status(400);
    throw new Error("name is required");
  }

  if (!Array.isArray(memberIds) || memberIds.length === 0) {
    res.status(400);
    throw new Error("memberIds must be a non-empty array");
  }

  if (description !== undefined && typeof description !== "string") {
    res.status(400);
    throw new Error("description must be a string when provided");
  }

  assertOptionalBoolean(onlyAdminAddMembers, "onlyAdminAddMembers");
  assertOptionalBoolean(onlyAdminRemoveMembers, "onlyAdminRemoveMembers");
  assertOptionalBoolean(onlyAdminEditGroup, "onlyAdminEditGroup");
  assertOptionalBoolean(onlyAdminSendMessages, "onlyAdminSendMessages");

  // Accept both camelCase and snake_case for compatibility.
  const normalizedIsEvent = isEvent ?? is_event;
  assertOptionalBoolean(normalizedIsEvent, "isEvent");

  const group = await createGroupService(currentUserId, {
    name,
    memberIds,
    groupImageUrl,
    description,
    onlyAdminAddMembers,
    onlyAdminRemoveMembers,
    onlyAdminEditGroup,
    onlyAdminSendMessages,
    isEvent: normalizedIsEvent,
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

// POST /api/groups/:groupId/members/:userId/promote
export const promoteGroupMember = asyncHandler(async (req, res) => {
  const { groupId, userId } = req.params;
  const currentUserId = req.user.id;

  const member = await promoteGroupMemberService(
    groupId,
    currentUserId,
    userId,
  );

  res.status(200).json({ success: true, member });
});

// POST /api/groups/:groupId/members/:userId/demote
export const demoteGroupMember = asyncHandler(async (req, res) => {
  const { groupId, userId } = req.params;
  const currentUserId = req.user.id;

  const member = await demoteGroupMemberService(groupId, currentUserId, userId);

  res.status(200).json({ success: true, member });
});

// PATCH /api/groups/:groupId  { name?, description?, groupImageUrl?, onlyAdminAddMembers?, onlyAdminRemoveMembers?, onlyAdminEditGroup?, onlyAdminSendMessages? }
export const updateGroup = asyncHandler(async (req, res) => {
  const { groupId } = req.params;
  const currentUserId = req.user.id;
  const {
    name,
    description,
    groupImageUrl,
    onlyAdminAddMembers,
    onlyAdminRemoveMembers,
    onlyAdminEditGroup,
    onlyAdminSendMessages,
  } = req.body;

  if (description !== undefined && typeof description !== "string") {
    res.status(400);
    throw new Error("description must be a string when provided");
  }

  assertOptionalBoolean(onlyAdminAddMembers, "onlyAdminAddMembers");
  assertOptionalBoolean(onlyAdminRemoveMembers, "onlyAdminRemoveMembers");
  assertOptionalBoolean(onlyAdminEditGroup, "onlyAdminEditGroup");
  assertOptionalBoolean(onlyAdminSendMessages, "onlyAdminSendMessages");

  const group = await updateGroupService(groupId, currentUserId, {
    name,
    description,
    groupImageUrl,
    onlyAdminAddMembers,
    onlyAdminRemoveMembers,
    onlyAdminEditGroup,
    onlyAdminSendMessages,
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
