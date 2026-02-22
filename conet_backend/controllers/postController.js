import asyncHandler from "express-async-handler";
import {
  addCommentService,
  createPostService,
  deleteCommentService,
  deletePostService,
  editCommentService,
  getAllPostsService,
  getLikedPostsService,
  getPostCommentsService,
  getPostService,
  getUserPostsService,
  toggleLikeService,
  updatePostService,
} from "../services/postService.js";

// CREATE POST
export const createPost = asyncHandler(async (req, res) => {
  const { content, media_urls } = req.body;

  if (!content) {
    res.status(400);
    throw new Error("Content is required");
  }

  const post = await createPostService(req.user.id, { content, media_urls });

  res
    .status(201)
    .json({ success: true, message: "Post created successfully", post });
});

// GET ALL POSTS
export const getAllPosts = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;

  const posts = await getAllPostsService(page, limit, req.user?.id ?? null);

  res.status(200).json({ success: true, count: posts.length, posts });
});

// GET SINGLE POST
export const getPost = asyncHandler(async (req, res) => {
  const post = await getPostService(req.params.id, req.user.id);

  res.status(200).json({ success: true, post });
});

// GET USER POSTS
export const getUserPosts = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;

  const result = await getUserPostsService(
    req.params.userId,
    page,
    limit,
    req.user?.id ?? null,
  );

  res.status(200).json({ success: true, ...result });
});

// GET LIKED POSTS
export const getLikedPosts = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;

  const result = await getLikedPostsService(
    req.user.id,
    page,
    limit,
    req.user.id,
  );

  res.status(200).json({ success: true, ...result });
});

// UPDATE POST
export const updatePost = asyncHandler(async (req, res) => {
  const { content, media_urls } = req.body;

  const post = await updatePostService(req.params.id, req.user.id, {
    content,
    media_urls,
  });

  res
    .status(200)
    .json({ success: true, message: "Post updated successfully", post });
});

// DELETE POST
export const deletePost = asyncHandler(async (req, res) => {
  await deletePostService(req.params.id, req.user.id);

  res.status(200).json({ success: true, message: "Post deleted successfully" });
});

// TOGGLE LIKE
export const toggleLike = asyncHandler(async (req, res) => {
  const result = await toggleLikeService(req.params.id, req.user.id);

  res.status(200).json({ success: true, ...result });
});

// ADD COMMENT
export const addComment = asyncHandler(async (req, res) => {
  const { content } = req.body;

  if (!content) {
    res.status(400);
    throw new Error("Comment content is required");
  }

  const comment = await addCommentService(req.params.id, req.user.id, content);

  res
    .status(201)
    .json({ success: true, message: "Comment added successfully", comment });
});

// GET POST COMMENTS
export const getPostComments = asyncHandler(async (req, res) => {
  const comments = await getPostCommentsService(req.params.id);

  res.status(200).json({ success: true, count: comments.length, comments });
});

// EDIT COMMENT
export const editComment = asyncHandler(async (req, res) => {
  const { content } = req.body;

  if (!content) {
    res.status(400);
    throw new Error("Comment content is required");
  }

  const comment = await editCommentService(
    req.params.postId,
    req.params.commentId,
    req.user.id,
    content,
  );

  res
    .status(200)
    .json({ success: true, message: "Comment updated successfully", comment });
});

// DELETE COMMENT
export const deleteComment = asyncHandler(async (req, res) => {
  await deleteCommentService(
    req.params.postId,
    req.params.commentId,
    req.user.id,
  );

  res
    .status(200)
    .json({ success: true, message: "Comment deleted successfully" });
});
