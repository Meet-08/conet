import prisma from "../config/prisma.js";
import notificationService from "./notificationService.js";
import { EMPTY_QUILL_DELTA_JSON, jsonFieldToString } from "./utils.js";

// ─── Shared response mappings ─────────────────────────────────────────────

const mapPost = (post, viewerId = null) => ({
  id: post.id,
  user: post.users ?? post.user ?? null,
  content: jsonFieldToString(post.content, EMPTY_QUILL_DELTA_JSON),
  media_urls: post.media_urls ?? [],
  like_count: post._count?.post_likes ?? post.like_count ?? 0,
  comment_count: post._count?.post_comments ?? post.comment_count ?? 0,
  is_liked: post.post_likes?.length > 0,
  created_at: post.created_at,
});

const mapComment = (comment) => ({
  id: comment.id,
  post_id: comment.post_id,
  user_id: comment.user_id,
  username: (comment.users ?? comment.user)?.username ?? null,
  profile_pic_url: (comment.users ?? comment.user)?.profile_pic_url ?? null,
  content: comment.content,
  created_at: comment.created_at,
  user: comment.users ?? comment.user ?? null,
});

// ─── Create post ─────────────────────────────────────────────────────────

export const createPostService = async (
  userId,
  { content, media_urls = [] },
) => {
  const post = await prisma.posts.create({
    data: {
      content,
      media_urls,
      user_id: userId,
    },
    include: { users: true },
  });

  return mapPost(post, userId);
};

// ─── Get all posts (paginated feed) ──────────────────────────────────────

export const getAllPostsService = async (
  page = 1,
  limit = 20,
  viewerId = null,
) => {
  const skip = (page - 1) * limit;

  const posts = await prisma.posts.findMany({
    skip,
    take: limit,
    orderBy: { created_at: "desc" },
    include: {
      users: true,
      _count: {
        select: { post_likes: true, post_comments: true },
      },
      post_likes:
        viewerId ?
          { where: { user_id: viewerId }, select: { user_id: true } }
        : false,
    },
  });

  return posts.map((p) => mapPost(p, viewerId));
};

// ─── Get single post ──────────────────────────────────────────────────────

export const getPostService = async (postId, viewerId = null) => {
  const post = await prisma.posts.findUnique({
    where: { id: postId },
    include: {
      users: true,
      _count: {
        select: { post_likes: true, post_comments: true },
      },
      post_likes:
        viewerId ?
          { where: { user_id: viewerId }, select: { user_id: true } }
        : false,
    },
  });

  if (!post) {
    const err = new Error("Post not found");
    err.statusCode = 404;
    throw err;
  }

  return mapPost(post, viewerId);
};

// ─── Get posts by user (paginated) ────────────────────────────────────────

export const getUserPostsService = async (
  userId,
  page = 1,
  limit = 20,
  viewerId = null,
) => {
  const skip = (page - 1) * limit;

  const [posts, total] = await prisma.$transaction([
    prisma.posts.findMany({
      where: { user_id: userId },
      skip,
      take: limit,
      orderBy: { created_at: "desc" },
      include: {
        users: true,
        _count: {
          select: { post_likes: true, post_comments: true },
        },
        post_likes:
          viewerId ?
            { where: { user_id: viewerId }, select: { user_id: true } }
          : false,
      },
    }),
    prisma.posts.count({ where: { user_id: userId } }),
  ]);

  return {
    posts: posts.map((p) => mapPost(p, viewerId)),
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
};

// ─── Get posts liked by user (paginated) ──────────────────────────────────

export const getLikedPostsService = async (
  userId,
  page = 1,
  limit = 20,
  viewerId = null,
) => {
  const skip = (page - 1) * limit;

  const [likes, total] = await prisma.$transaction([
    prisma.post_likes.findMany({
      where: { user_id: userId },
      skip,
      take: limit,
      orderBy: { created_at: "desc" },
      include: {
        posts: {
          include: {
            users: true,
            _count: {
              select: { post_likes: true, post_comments: true },
            },
            post_likes:
              viewerId ?
                { where: { user_id: viewerId }, select: { user_id: true } }
              : false,
          },
        },
      },
    }),
    prisma.post_likes.count({ where: { user_id: userId } }),
  ]);

  return {
    posts: likes.map((like) => mapPost(like.posts ?? like.post, viewerId)),
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
};

// ─── Update post ─────────────────────────────────────────────────────────

export const updatePostService = async (
  postId,
  userId,
  { content, media_urls },
) => {
  const existing = await prisma.posts.findUnique({ where: { id: postId } });

  if (!existing) {
    const err = new Error("Post not found");
    err.statusCode = 404;
    throw err;
  }

  if (existing.user_id !== userId) {
    const err = new Error("Not authorized to update this post");
    err.statusCode = 403;
    throw err;
  }

  const post = await prisma.posts.update({
    where: { id: postId },
    data: {
      content,
      media_urls,
      updated_at: new Date(),
    },
    include: { users: true },
  });

  return mapPost(post, userId);
};

// ─── Delete post ─────────────────────────────────────────────────────────
// Prisma cascade (onDelete: Cascade) handles related post_likes and
// post_comments automatically via the schema – no manual cleanup needed.

export const deletePostService = async (postId, userId) => {
  const existing = await prisma.posts.findUnique({ where: { id: postId } });

  if (!existing) {
    const err = new Error("Post not found");
    err.statusCode = 404;
    throw err;
  }

  if (existing.user_id !== userId) {
    const err = new Error("Not authorized to delete this post");
    err.statusCode = 403;
    throw err;
  }

  await prisma.posts.delete({ where: { id: postId } });
};

// ─── Toggle like ──────────────────────────────────────────────────────────

export const toggleLikeService = async (postId, userId) => {
  const post = await prisma.posts.findUnique({ where: { id: postId } });

  if (!post) {
    const err = new Error("Post not found");
    err.statusCode = 404;
    throw err;
  }

  const existing = await prisma.post_likes.findUnique({
    where: { post_id_user_id: { post_id: postId, user_id: userId } },
  });

  let liked;

  if (existing) {
    await prisma.post_likes.delete({
      where: { post_id_user_id: { post_id: postId, user_id: userId } },
    });
    liked = false;
  } else {
    await prisma.post_likes.create({
      data: { post_id: postId, user_id: userId },
    });
    liked = true;

    // Send notification
    await notificationService.createNotification({
      receiverId: post.user_id,
      actorId: userId,
      type: "POST_LIKE",
      referenceId: postId,
    });
  }

  const updated = await prisma.posts.findUnique({ where: { id: postId } });

  return { liked, like_count: updated.like_count };
};

// ─── Add comment ──────────────────────────────────────────────────────────

export const addCommentService = async (postId, userId, content) => {
  const post = await prisma.posts.findUnique({ where: { id: postId } });

  if (!post) {
    const err = new Error("Post not found");
    err.statusCode = 404;
    throw err;
  }

  const comment = await prisma.post_comments.create({
    data: { post_id: postId, user_id: userId, content },
    include: { users: true },
  });

  // Send notification
  await notificationService.createNotification({
    receiverId: post.user_id,
    actorId: userId,
    type: "POST_COMMENT",
    referenceId: postId,
    content: content.substring(0, 100), // Send a snippet of the comment
  });

  return mapComment(comment);
};

// ─── Get post comments ────────────────────────────────────────────────────

export const getPostCommentsService = async (postId) => {
  const post = await prisma.posts.findUnique({ where: { id: postId } });

  if (!post) {
    const err = new Error("Post not found");
    err.statusCode = 404;
    throw err;
  }

  const comments = await prisma.post_comments.findMany({
    where: { post_id: postId },
    orderBy: { created_at: "desc" },
    include: { users: true },
  });

  return comments.map(mapComment);
};

// ─── Edit comment ─────────────────────────────────────────────────────────

export const editCommentService = async (
  postId,
  commentId,
  userId,
  content,
) => {
  const comment = await prisma.post_comments.findUnique({
    where: { id: commentId },
  });

  if (!comment) {
    const err = new Error("Comment not found");
    err.statusCode = 404;
    throw err;
  }

  if (comment.user_id !== userId) {
    const err = new Error("Not authorized to edit this comment");
    err.statusCode = 403;
    throw err;
  }

  const updated = await prisma.post_comments.update({
    where: { id: commentId },
    data: { content },
    include: { users: true },
  });

  return mapComment(updated);
};

// ─── Delete comment ───────────────────────────────────────────────────────

export const deleteCommentService = async (postId, commentId, userId) => {
  const comment = await prisma.post_comments.findUnique({
    where: { id: commentId, post_id: postId },
  });

  if (!comment) {
    const err = new Error("Comment not found");
    err.statusCode = 404;
    throw err;
  }

  if (comment.user_id !== userId) {
    const err = new Error("Not authorized to delete this comment");
    err.statusCode = 403;
    throw err;
  }

  await prisma.post_comments.delete({ where: { id: commentId } });
};
