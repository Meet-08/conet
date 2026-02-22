import { USER_SELECT_FIELDS, UUID_REGEX } from "../config/constants.js";
import prisma from "../config/prisma.js";

/**
 * Normalize conversation pair so user_one < user_two (alphabetical UUID sort).
 * This ensures the unique_pair constraint works correctly.
 */
const normalizePair = (userA, userB) => {
  return userA.localeCompare(userB) <= 0 ?
      { user_one: userA, user_two: userB }
    : { user_one: userB, user_two: userA };
};

/**
 * Map a raw Prisma conversation row + currentUserId into the API shape.
 * Includes last_message, updated_at, and unread_count.
 */
const mapConversation = (row, currentUserId) => {
  const isUserOne = row.user_one === currentUserId;
  const otherUser =
    isUserOne ?
      row.users_conversations_user_twoTousers
    : row.users_conversations_user_oneTousers;

  return {
    id: row.id,
    other_user: otherUser,
    last_message:
      row.messages_conversations_last_message_idTomessages?.content ?? null,
    last_message_media_urls:
      row.messages_conversations_last_message_idTomessages?.media_urls ?? [],
    updated_at:
      row.updated_at?.toISOString() ?? row.created_at?.toISOString() ?? null,
    unread_count: row._count?.unreadMessages ?? 0,
  };
};

// ─── Create or retrieve a conversation ──────────────────────────────────────

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

  // Upsert: find existing or create new
  const conversation = await prisma.conversations.upsert({
    where: {
      user_one_user_two: {
        user_one: pair.user_one,
        user_two: pair.user_two,
      },
    },
    update: {}, // no-op if exists
    create: {
      user_one: pair.user_one,
      user_two: pair.user_two,
    },
  });

  return {
    id: conversation.id,
    other_user: otherUser,
    last_message: null,
    updated_at: conversation.updated_at?.toISOString() ?? null,
    unread_count: 0,
  };
};

// ─── Get all conversations for a user ───────────────────────────────────────

export const getConversationsService = async (currentUserId) => {
  const rows = await prisma.conversations.findMany({
    where: {
      OR: [{ user_one: currentUserId }, { user_two: currentUserId }],
      last_message_id: {
        not: null,
      },
    },
    include: {
      users_conversations_user_oneTousers: { select: USER_SELECT_FIELDS },
      users_conversations_user_twoTousers: { select: USER_SELECT_FIELDS },
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

export const getMessagesService = async (conversationId, limit = 20) => {
  const messages = await prisma.messages.findMany({
    where: { conversation_id: conversationId },
    orderBy: { created_at: "desc" },
    take: limit,
  });

  return messages.map((m) => ({
    id: m.id,
    conversation_id: m.conversation_id,
    sender_id: m.sender_id,
    content: m.content,
    created_at: m.created_at?.toISOString() ?? null,
    is_read: m.is_read ?? false,
    media_urls: m.media_urls ?? [],
  }));
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
  });

  if (!conversation) {
    const err = new Error("Conversation not found");
    err.statusCode = 404;
    throw err;
  }

  if (
    conversation.user_one !== senderId &&
    conversation.user_two !== senderId
  ) {
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
  await prisma.messages.updateMany({
    where: {
      conversation_id: conversationId,
      sender_id: { not: currentUserId },
      is_read: false,
    },
    data: { is_read: true },
  });
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
