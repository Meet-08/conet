import express from "express";
import {
  followUser,
  getFollowers,
  getFollowing,
  getUserProfile,
  unfollowUser,
  updateAboutMe,
  updateAcademicInfo,
  updateInterests,
  updatePersonalInfo,
  updatePictures,
  updateSocialLinks,
} from "../controllers/profileController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

router.get("/:uid", validateSupabaseToken, getUserProfile);

router.put("/about-me", validateSupabaseToken, updateAboutMe);
router.put("/academic-info", validateSupabaseToken, updateAcademicInfo);
router.put("/interests", validateSupabaseToken, updateInterests);
router.put("/personal-info", validateSupabaseToken, updatePersonalInfo);
router.put("/pictures", validateSupabaseToken, updatePictures);
router.put("/social-links", validateSupabaseToken, updateSocialLinks);
router.post("/:uid/follow", validateSupabaseToken, followUser);
router.delete("/:uid/follow", validateSupabaseToken, unfollowUser);
router.get("/:uid/followers", validateSupabaseToken, getFollowers);
router.get("/:uid/following", validateSupabaseToken, getFollowing);

export default router;
