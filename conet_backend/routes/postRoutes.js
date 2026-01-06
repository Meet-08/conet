import express from "express";
import {
  addComment,
  createPost,
  deleteComment,
  deletePost,
  editComment,
  getAllPosts,
  getPost,
  getPostComments,
  getUserPosts,
  toggleLike,
  updatePost,
} from "../controllers/postController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

// Public routes (no auth required)
router.get("/", getAllPosts);
router.get("/:id", getPost);
router.get("/user/:userId", getUserPosts);
router.get("/:id/comments", getPostComments);

// Protected routes (auth required)
router.post("/", validateSupabaseToken, createPost);
router.put("/:id", validateSupabaseToken, updatePost);
router.delete("/:id", validateSupabaseToken, deletePost);
router.put("/like/:id", validateSupabaseToken, toggleLike);
router.post("/comment/:id", validateSupabaseToken, addComment);
router.put("/:postId/comment/:commentId", validateSupabaseToken, editComment);
router.delete(
  "/:postId/comment/:commentId",
  validateSupabaseToken,
  deleteComment
);

export default router;
