import asyncHandler from "express-async-handler";
import prisma from "../config/prisma.js";

// CREATE POST
export const createPost = asyncHandler(async (req, res) => {
  const { content, media_urls } = req.body;
  const user_id = req.user.id;

  if (!content) {
    res.status(400);
    throw new Error("Content is required");
  }

  const post = await prisma.posts.create({
    data: {
      content,
      media_urls: media_urls || [],
      user_id,
    },
    include: {
      user: true,
    },
  });

  res.status(201).json({
    success: true,
    message: "Post created successfully",
    post,
  });
});

// GET ALL POSTS
export const getAllPosts = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;

  const posts = await prisma.posts.findMany({
    skip,
    take: limit,
    orderBy: { created_at: "desc" },
    include: {
      user: true,
      post_likes: true,
    },
  });

  const total = await prisma.posts.count();

  res.status(200).json({
    success: true,
    count: posts.length,
    total,
    page,
    totalPages: Math.ceil(total / limit),
    posts,
  });
});

// GET SINGLE POST
export const getPost = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const post = await prisma.posts.findUnique({
    where: { id },
    include: {
      user: true,
      post_likes: true,
      post_comments: {
        include: { user: true },
        orderBy: { created_at: "desc" },
      },
    },
  });

  if (!post) {
    res.status(404);
    throw new Error("Post not found");
  }

  res.status(200).json({
    success: true,
    post,
  });
});

// GET USER POSTS
export const getUserPosts = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;

  const posts = await prisma.posts.findMany({
    where: { user_id: userId },
    skip,
    take: limit,
    orderBy: { created_at: "desc" },
    include: {
      user: true,
      post_likes: true,
    },
  });

  const total = await prisma.posts.count({
    where: { user_id: userId },
  });

  res.status(200).json({
    success: true,
    count: posts.length,
    total,
    page,
    totalPages: Math.ceil(total / limit),
    posts,
  });
});

// UPDATE POST
export const updatePost = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { content, media_urls } = req.body;
  const user_id = req.user.id;

  const existingPost = await prisma.posts.findUnique({
    where: { id },
  });

  if (!existingPost) {
    res.status(404);
    throw new Error("Post not found");
  }

  // Ensure user owns the post
  if (existingPost.user_id !== user_id) {
    res.status(403);
    throw new Error("Not authorized to update this post");
  }

  const post = await prisma.posts.update({
    where: { id },
    data: {
      content,
      media_urls,
      updated_at: new Date(),
    },
    include: {
      user: true,
    },
  });

  res.status(200).json({
    success: true,
    message: "Post updated successfully",
    post,
  });
});

// DELETE POST
export const deletePost = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const user_id = req.user.id;

  const existingPost = await prisma.posts.findUnique({
    where: { id },
  });

  if (!existingPost) {
    res.status(404);
    throw new Error("Post not found");
  }

  // Ensure user owns the post
  if (existingPost.user_id !== user_id) {
    res.status(403);
    throw new Error("Not authorized to delete this post");
  }

  // Delete related likes and comments first
  await prisma.post_likes.deleteMany({
    where: { post_id: id },
  });

  await prisma.post_comments.deleteMany({
    where: { post_id: id },
  });

  await prisma.posts.delete({
    where: { id },
  });

  res.status(200).json({
    success: true,
    message: "Post deleted successfully",
  });
});

// TOGGLE LIKE
export const toggleLike = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const user_id = req.user.id;

  const post = await prisma.posts.findUnique({
    where: { id },
  });

  if (!post) {
    res.status(404);
    throw new Error("Post not found");
  }

  const existingLike = await prisma.post_likes.findUnique({
    where: {
      post_id_user_id: {
        post_id: id,
        user_id,
      },
    },
  });

  let liked;
  if (existingLike) {
    // Unlike
    await prisma.post_likes.delete({
      where: {
        post_id_user_id: {
          post_id: id,
          user_id,
        },
      },
    });

    liked = false;
  } else {
    // Like
    await prisma.post_likes.create({
      data: {
        post_id: id,
        user_id,
      },
    });

    liked = true;
  }

  const updatedPost = await prisma.posts.findUnique({
    where: { id },
  });

  res.json({
    success: true,
    liked,
    like_count: updatedPost.like_count,
  });
});

// ADD COMMENT
export const addComment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { content } = req.body;
  const user_id = req.user.id;

  if (!content) {
    res.status(400);
    throw new Error("Comment content is required");
  }

  const post = await prisma.posts.findUnique({
    where: { id },
  });

  if (!post) {
    res.status(404);
    throw new Error("Post not found");
  }

  const comment = await prisma.post_comments.create({
    data: {
      post_id: id,
      user_id,
      content,
    },
    include: {
      user: true,
    },
  });

  res.status(201).json({
    success: true,
    message: "Comment added successfully",
    comment,
  });
});

// GET POST COMMENTS
export const getPostComments = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const post = await prisma.posts.findUnique({
    where: { id },
  });

  if (!post) {
    res.status(404);
    throw new Error("Post not found");
  }

  const comments = await prisma.post_comments.findMany({
    where: { post_id: id },
    orderBy: { created_at: "desc" },
    include: {
      user: true,
    },
  });

  const formattedComments = comments.map((comment) => ({
    id: comment.id,
    post_id: comment.post_id,
    user_id: comment.user_id,
    username: comment.user.username,
    profile_pic_url: comment.user.profile_pic_url,
    content: comment.content,
  }));

  res.status(200).json({
    success: true,
    count: comments.length,
    comments: formattedComments,
  });
});

// EDIT COMMENT
export const editComment = asyncHandler(async (req, res) => {
  const { postId, commentId } = req.params;
  const { content } = req.body;
  const user_id = req.user.id;

  if (!content) {
    res.status(400);
    throw new Error("Comment content is required");
  }

  const comment = await prisma.post_comments.findUnique({
    where: { id: commentId },
  });

  if (!comment) {
    res.status(404);
    throw new Error("Comment not found");
  }

  // Ensure user owns the comment
  if (comment.user_id !== user_id) {
    res.status(403);
    throw new Error("Not authorized to edit this comment");
  }

  const updatedComment = await prisma.post_comments.update({
    where: { id: commentId },
    data: { content },
    include: {
      user: true,
    },
  });

  res.json({
    success: true,
    message: "Comment updated successfully",
    comment: updatedComment,
  });
});

// DELETE COMMENT
export const deleteComment = asyncHandler(async (req, res) => {
  const { postId, commentId } = req.params;
  const user_id = req.user.id;

  const comment = await prisma.post_comments.findUnique({
    where: { id: commentId, post_id: postId },
  });

  if (!comment) {
    res.status(404);
    throw new Error("Comment not found");
  }

  // Ensure user owns the comment
  if (comment.user_id !== user_id) {
    res.status(403);
    throw new Error("Not authorized to delete this comment");
  }

  await prisma.post_comments.delete({
    where: { id: commentId },
  });

  res.json({
    success: true,
    message: "Comment deleted successfully",
  });
});
