import express from "express";
import {
  addGroupMember,
  createGroup,
  deleteGroup,
  getGroupMembers,
  promoteGroupMember,
  removeGroupMember,
  updateGroup,
} from "../controllers/conversationController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

router.use(validateSupabaseToken);

// Create a group
router.post("/", createGroup);

// Update / delete a group (admin only)
router.patch("/:groupId", updateGroup);
router.delete("/:groupId", deleteGroup);

// Group members
router.get("/:groupId/members", getGroupMembers);
router.post("/:groupId/members", addGroupMember);
router.patch("/:groupId/members/:userId/role", promoteGroupMember);
router.delete("/:groupId/members/:userId", removeGroupMember);

export default router;
