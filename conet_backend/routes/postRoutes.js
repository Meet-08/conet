import express from "express";
import {
  addComment,
  createPost,
  deleteComment,
  deletePost,
  editComment,
  getAllPosts,
  getLikedPosts,
  getPost,
  getPostComments,
  getUserPosts,
  toggleLike,
  updatePost,
} from "../controllers/postController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

// All post routes require a valid Supabase token
router.use(validateSupabaseToken);

router.get("/", getAllPosts);
router.get("/liked", getLikedPosts);
router.get("/:id", getPost);
router.get("/user/:userId", getUserPosts);
router.get("/:id/comments", getPostComments);

router.post("/", createPost);
router.put("/:id", updatePost);
router.delete("/:id", deletePost);
router.put("/like/:id", toggleLike);
router.post("/comment/:id", addComment);
router.put("/:postId/comment/:commentId", editComment);
router.delete("/:postId/comment/:commentId", deleteComment);

export default router;
