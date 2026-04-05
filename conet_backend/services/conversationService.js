import { USER_SELECT_FIELDS, UUID_REGEX } from "../config/constants.js";
import logger from "../config/logger.js";
import prisma from "../config/prisma.js";
import notificationService from "./notificationService.js";

// ─── Private helpers ──────────────────────────────────────────────────────────

/**
 * Normalize conversation pair so user_one < user_two (alphabetical UUID sort).
 * This ensures the partial unique index (WHERE type='direct') works correctly.
 */
const normalizePair = (userA, userB) => {
  return userA.localeCompare(userB) <= 0 ?
      { user_one: userA, user_two: userB }
    : { user_one: userB, user_two: userA };
};

/** Map a raw Prisma direct-conversation row into the API shape. */
const mapDirectConversation = (row, currentUserId) => {
  const otherMember = row.conversation_members?.find(
    (m) => m.user_id !== currentUserId,
  );

  return {
    id: row.id,
    type: "direct",
    other_user: otherMember?.users ?? null,
    last_message:
      row.messages_conversations_last_message_idTomessages?.content ?? null,
    last_message_media_urls:
      row.messages_conversations_last_message_idTomessages?.media_urls ?? [],
    updated_at:
      row.updated_at?.toISOString() ?? row.created_at?.toISOString() ?? null,
    unread_count: row._count?.unreadMessages ?? 0,
  };
};

/** Map a raw Prisma group-conversation row into the API shape. */
const mapGroupConversation = (row, currentUserId) => {
  const members = (row.conversation_members ?? []).map((m) => ({
    ...m.users,
    role: m.role ?? "member",
  }));

  const selfMember = row.conversation_members?.find(
    (m) => m.user_id === currentUserId,
  );

  return {
    id: row.id,
    type: "group",
    name: row.name ?? null,
    group_image_url: row.group_image_url ?? null,
    created_by: row.created_by ?? null,
    current_user_role: selfMember?.role ?? "member",
    members,
    last_message:
      row.messages_conversations_last_message_idTomessages?.content ?? null,
    last_message_media_urls:
      row.messages_conversations_last_message_idTomessages?.media_urls ?? [],
    updated_at:
      row.updated_at?.toISOString() ?? row.created_at?.toISOString() ?? null,
    unread_count: row._count?.unreadMessages ?? 0,
  };
};

/** Route to the correct mapper based on conversation type. */
const mapConversation = (row, currentUserId) => {
  if (row.type === "group") return mapGroupConversation(row, currentUserId);
  return mapDirectConversation(row, currentUserId);
};

// ─── Direct conversation ──────────────────────────────────────────────────────

/**
 * Create or retrieve a 1-to-1 direct conversation.
 * otherUserId may be a UUID, username, or email.
 */
export const createConversationService = async (currentUserId, otherUserId) => {
  let targetUserId = otherUserId;

  if (!UUID_REGEX.test(otherUserId)) {
    const user = await prisma.users.findFirst({
      where: {
        OR: [{ username: otherUserId }, { email: otherUserId }],
      },
      select: { id: true },
    });

    if (!user) {
      const err = new Error("User not found");
      err.statusCode = 404;
      throw err;
    }

    targetUserId = user.id;
  }

  if (currentUserId === targetUserId) {
    const err = new Error("Cannot create conversation with yourself");
    err.statusCode = 400;
    throw err;
  }

  const pair = normalizePair(currentUserId, targetUserId);

  const otherUser = await prisma.users.findUnique({
    where: { id: targetUserId },
    select: USER_SELECT_FIELDS,
  });

  if (!otherUser) {
    const err = new Error("User not found");
    err.statusCode = 404;
    throw err;
  }

  // Prisma upsert cannot target a partial unique index, so use findFirst + create.
  const existing = await prisma.conversations.findFirst({
    where: { type: "direct", user_one: pair.user_one, user_two: pair.user_two },
    select: { id: true, updated_at: true },
  });

  if (existing) {
    return {
      id: existing.id,
      type: "direct",
      other_user: otherUser,
      last_message: null,
      last_message_media_urls: [],
      updated_at: existing.updated_at?.toISOString() ?? null,
      unread_count: 0,
    };
  }

  const conversation = await prisma.conversations.create({
    data: {
      type: "direct",
      user_one: pair.user_one,
      user_two: pair.user_two,
      conversation_members: {
        create: [{ user_id: pair.user_one }, { user_id: pair.user_two }],
      },
    },
  });

  return {
    id: conversation.id,
    type: "direct",
    other_user: otherUser,
    last_message: null,
    last_message_media_urls: [],
    updated_at: conversation.updated_at?.toISOString() ?? null,
    unread_count: 0,
  };
};

// ─── Group conversation ───────────────────────────────────────────────────────

/**
 * Create a new group conversation.
 *
 * @param {string}   currentUserId      – creator (automatically assigned admin role)
 * @param {object}   data
 * @param {string}   data.name          – required
 * @param {string[]} data.memberIds     – additional member UUIDs (creator added automatically)
 * @param {string}   [data.groupImageUrl]
 */
export const createGroupService = async (
  currentUserId,
  { name, memberIds = [], groupImageUrl } = {},
) => {
  if (!name || name.trim().length === 0) {
    const err = new Error("Group name is required");
    err.statusCode = 400;
    throw err;
  }

  const allMemberIds = [...new Set([currentUserId, ...memberIds])];

  if (allMemberIds.length < 2) {
    const err = new Error("A group requires at least one other member");
    err.statusCode = 400;
    throw err;
  }

  const existingUsers = await prisma.users.findMany({
    where: { id: { in: allMemberIds } },
    select: { id: true },
  });

  if (existingUsers.length !== allMemberIds.length) {
    const err = new Error("One or more users not found");
    err.statusCode = 404;
    throw err;
  }

  const group = await prisma.conversations.create({
    data: {
      type: "group",
      name: name.trim(),
      group_image_url: groupImageUrl ?? null,
      created_by: currentUserId,
      conversation_members: {
        create: allMemberIds.map((userId) => ({
          user_id: userId,
          role: userId === currentUserId ? "admin" : "member",
        })),
      },
    },
    include: {
      conversation_members: {
        include: { users: { select: USER_SELECT_FIELDS } },
      },
    },
  });

  group._count = { unreadMessages: 0 };
  return mapGroupConversation(group, currentUserId);
};

// ─── List conversations ───────────────────────────────────────────────────────

/**
 * Get all conversations for a user.
 *
 * @param {string} currentUserId
 * @param {"all"|"direct"|"group"} [type="all"] – filter by conversation type
 */
export const getConversationsService = async (currentUserId, type = "all") => {
  const typeFilter =
    type === "all" ? {} : { type: type === "group" ? "group" : "direct" };

  const rows = await prisma.conversations.findMany({
    where: {
      conversation_members: {
        some: { user_id: currentUserId },
      },
      ...typeFilter,
    },
    include: {
      conversation_members: {
        include: {
          users: { select: USER_SELECT_FIELDS },
        },
      },
      messages_conversations_last_message_idTomessages: {
        select: { content: true, media_urls: true },
      },
    },
    orderBy: { updated_at: "desc" },
  });

  // Batch-compute unread counts per conversation
  const conversationIds = rows.map((r) => r.id);
  const unreadCounts = await prisma.messages.groupBy({
    by: ["conversation_id"],
    where: {
      conversation_id: { in: conversationIds },
      sender_id: { not: currentUserId },
      is_read: false,
    },
    _count: { id: true },
  });

  const unreadMap = Object.fromEntries(
    unreadCounts.map((uc) => [uc.conversation_id, uc._count.id]),
  );

  return rows.map((row) => {
    row._count = { unreadMessages: unreadMap[row.id] ?? 0 };
    return mapConversation(row, currentUserId);
  });
};

// ─── Get messages for a conversation ────────────────────────────────────────

export const getMessagesService = async (
  conversationId,
  { limit = 20, before } = {},
) => {
  const where = {
    conversation_id: conversationId,
    ...(before ? { created_at: { lt: before } } : {}),
  };

  const rows = await prisma.messages.findMany({
    where,
    orderBy: { created_at: "desc" },
    take: limit + 1,
  });

  const hasMore = rows.length > limit;
  const messages = hasMore ? rows.slice(0, limit) : rows;

  const mappedMessages = messages.map((m) => ({
    id: m.id,
    conversation_id: m.conversation_id,
    sender_id: m.sender_id,
    content: m.content,
    created_at: m.created_at?.toISOString() ?? null,
    is_read: m.is_read ?? false,
    media_urls: m.media_urls ?? [],
  }));

  const nextBefore =
    hasMore && mappedMessages.length > 0 ?
      mappedMessages[mappedMessages.length - 1].created_at
    : null;

  return {
    messages: mappedMessages,
    hasMore,
    nextBefore,
  };
};

// ─── Send a message ─────────────────────────────────────────────────────────

export const sendMessageService = async (
  conversationId,
  senderId,
  content,
  mediaUrls = [],
) => {
  // Verify conversation exists and user is a participant
  const conversation = await prisma.conversations.findUnique({
    where: { id: conversationId },
    include: {
      conversation_members: true,
    },
  });

  if (!conversation) {
    const err = new Error("Conversation not found");
    err.statusCode = 404;
    throw err;
  }

  const isParticipant = conversation.conversation_members.some(
    (m) => m.user_id === senderId,
  );

  if (!isParticipant) {
    const err = new Error("Not a participant of this conversation");
    err.statusCode = 403;
    throw err;
  }

  const message = await prisma.messages.create({
    data: {
      conversation_id: conversationId,
      sender_id: senderId,
      content,
      media_urls: mediaUrls,
    },
  });

  // Notify all other participants (works for both direct and group).
  const receivers = conversation.conversation_members
    .filter((m) => m.user_id !== senderId)
    .map((m) => m.user_id);

  const notificationResults = await Promise.allSettled(
    receivers.map((receiverId) =>
      notificationService.createNotification({
        receiverId,
        actorId: senderId,
        type: "NEW_MESSAGE",
        referenceId: conversationId,
        content: content ? content.substring(0, 100) : null,
      }),
    ),
  );

  notificationResults.forEach((result, index) => {
    if (result.status === "rejected") {
      logger.error(
        `Failed to create NEW_MESSAGE notification for receiver ${receivers[index]} in conversation ${conversationId}: ${result.reason?.message ?? result.reason}`,
      );
    }
  });

  return {
    id: message.id,
    conversation_id: message.conversation_id,
    sender_id: message.sender_id,
    content: message.content,
    created_at: message.created_at?.toISOString() ?? null,
    is_read: message.is_read ?? false,
    media_urls: message.media_urls ?? [],
  };
};

// ─── Mark messages as read ──────────────────────────────────────────────────

export const markAsReadService = async (conversationId, currentUserId) => {
  const conversation = await prisma.conversations.findUnique({
    where: { id: conversationId },
    include: {
      conversation_members: true,
    },
  });

  if (!conversation) {
    const err = new Error("Conversation not found");
    err.statusCode = 404;
    throw err;
  }

  const isParticipant = conversation.conversation_members.some(
    (m) => m.user_id === currentUserId,
  );

  if (!isParticipant) {
    const err = new Error("Not a participant of this conversation");
    err.statusCode = 403;
    throw err;
  }

  const result = await prisma.messages.updateMany({
    where: {
      conversation_id: conversationId,
      sender_id: { not: currentUserId },
      is_read: false,
    },
    data: { is_read: true },
  });

  return result.count;
};

// ─── Group management ────────────────────────────────────────────────────────

/**
 * Get all members of a group. Requester must be a member.
 */
export const getGroupMembersService = async (groupId, currentUserId) => {
  const conversation = await prisma.conversations.findUnique({
    where: { id: groupId },
    include: {
      conversation_members: {
        include: { users: { select: USER_SELECT_FIELDS } },
      },
    },
  });

  if (!conversation || conversation.type !== "group") {
    const err = new Error("Group not found");
    err.statusCode = 404;
    throw err;
  }

  const self = conversation.conversation_members.find(
    (m) => m.user_id === currentUserId,
  );

  if (!self) {
    const err = new Error("Not a member of this group");
    err.statusCode = 403;
    throw err;
  }

  return conversation.conversation_members.map((m) => ({
    ...m.users,
    role: m.role ?? "member",
    joined_at: m.joined_at?.toISOString() ?? null,
  }));
};

/**
 * Add a new member to a group. Only admins may do this.
 */
export const addGroupMemberService = async (
  groupId,
  currentUserId,
  newMemberId,
) => {
  const conversation = await prisma.conversations.findUnique({
    where: { id: groupId },
    include: { conversation_members: true },
  });

  if (!conversation || conversation.type !== "group") {
    const err = new Error("Group not found");
    err.statusCode = 404;
    throw err;
  }

  const self = conversation.conversation_members.find(
    (m) => m.user_id === currentUserId,
  );

  if (!self || self.role !== "admin") {
    const err = new Error("Only group admins can add members");
    err.statusCode = 403;
    throw err;
  }

  const alreadyMember = conversation.conversation_members.some(
    (m) => m.user_id === newMemberId,
  );

  if (alreadyMember) {
    const err = new Error("User is already a member of this group");
    err.statusCode = 409;
    throw err;
  }

  const targetUser = await prisma.users.findUnique({
    where: { id: newMemberId },
    select: USER_SELECT_FIELDS,
  });

  if (!targetUser) {
    const err = new Error("User not found");
    err.statusCode = 404;
    throw err;
  }

  await prisma.conversation_members.create({
    data: { conversation_id: groupId, user_id: newMemberId, role: "member" },
  });

  return { ...targetUser, role: "member" };
};

/**
 * Remove a member from a group OR leave the group yourself.
 *
 * Rules:
 *  - Admin can remove any non-admin member.
 *  - Any member can remove themselves (leave).
 *  - The last admin cannot leave — they must promote someone first.
 */
export const removeGroupMemberService = async (
  groupId,
  currentUserId,
  targetUserId,
) => {
  const conversation = await prisma.conversations.findUnique({
    where: { id: groupId },
    include: { conversation_members: true },
  });

  if (!conversation || conversation.type !== "group") {
    const err = new Error("Group not found");
    err.statusCode = 404;
    throw err;
  }

  const self = conversation.conversation_members.find(
    (m) => m.user_id === currentUserId,
  );

  if (!self) {
    const err = new Error("Not a member of this group");
    err.statusCode = 403;
    throw err;
  }

  const targetMember = conversation.conversation_members.find(
    (m) => m.user_id === targetUserId,
  );

  if (!targetMember) {
    const err = new Error("Target user is not a member of this group");
    err.statusCode = 404;
    throw err;
  }

  const isSelf = currentUserId === targetUserId;

  if (!isSelf && self.role !== "admin") {
    const err = new Error("Only group admins can remove other members");
    err.statusCode = 403;
    throw err;
  }

  if (!isSelf && targetMember.role === "admin") {
    const err = new Error("Cannot remove another admin from the group");
    err.statusCode = 403;
    throw err;
  }

  // Prevent the last admin from leaving without transferring ownership.
  if (isSelf && self.role === "admin") {
    const adminCount = conversation.conversation_members.filter(
      (m) => m.role === "admin",
    ).length;

    if (adminCount === 1) {
      const err = new Error(
        "You are the last admin. Promote another member before leaving.",
      );
      err.statusCode = 400;
      throw err;
    }
  }

  await prisma.conversation_members.delete({
    where: {
      conversation_id_user_id: {
        conversation_id: groupId,
        user_id: targetUserId,
      },
    },
  });
};

/**
 * Update a group's name and/or image. Only admins may do this.
 */
export const updateGroupService = async (
  groupId,
  currentUserId,
  { name, groupImageUrl },
) => {
  const conversation = await prisma.conversations.findUnique({
    where: { id: groupId },
    include: { conversation_members: true },
  });

  if (!conversation || conversation.type !== "group") {
    const err = new Error("Group not found");
    err.statusCode = 404;
    throw err;
  }

  const self = conversation.conversation_members.find(
    (m) => m.user_id === currentUserId,
  );

  if (!self || self.role !== "admin") {
    const err = new Error("Only group admins can update group details");
    err.statusCode = 403;
    throw err;
  }

  const data = {};
  if (name !== undefined) data.name = name.trim();
  if (groupImageUrl !== undefined) data.group_image_url = groupImageUrl;

  if (Object.keys(data).length === 0) {
    const err = new Error("No fields to update");
    err.statusCode = 400;
    throw err;
  }

  const updated = await prisma.conversations.update({
    where: { id: groupId },
    data,
    include: {
      conversation_members: {
        include: { users: { select: USER_SELECT_FIELDS } },
      },
    },
  });

  updated._count = { unreadMessages: 0 };
  return mapGroupConversation(updated, currentUserId);
};

/**
 * Delete a group entirely. Only admins may do this.
 */
export const deleteGroupService = async (groupId, currentUserId) => {
  const conversation = await prisma.conversations.findUnique({
    where: { id: groupId },
    include: { conversation_members: true },
  });

  if (!conversation || conversation.type !== "group") {
    const err = new Error("Group not found");
    err.statusCode = 404;
    throw err;
  }

  const self = conversation.conversation_members.find(
    (m) => m.user_id === currentUserId,
  );

  if (!self || self.role !== "admin") {
    const err = new Error("Only group admins can delete the group");
    err.statusCode = 403;
    throw err;
  }

  await prisma.conversations.delete({ where: { id: groupId } });
};

// ─── Search users by username or email ──────────────────────────────────────

export const searchUsersService = async (query, limit = 3, currentUserId) => {
  const users = await prisma.users.findMany({
    where: {
      AND: [
        { id: { not: currentUserId } },
        {
          OR: [
            { username: { contains: query, mode: "insensitive" } },
            { email: { contains: query, mode: "insensitive" } },
          ],
        },
      ],
    },
    select: USER_SELECT_FIELDS,
    take: limit,
    orderBy: { username: "asc" },
  });

  return users;
};
