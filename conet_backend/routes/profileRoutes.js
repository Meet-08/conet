import express from "express";
import {
  getUserProfile,
  updateAboutMe,
  updateAcademicInfo,
  updateInterests,
  updatePersonalInfo,
  updatePictures,
  updateSocialLinks,
} from "../controllers/profileController.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

// Public routes
router.get("/:uid", getUserProfile);

// Protected routes (auth required)
router.put("/about-me", validateSupabaseToken, updateAboutMe);
router.put("/academic-info", validateSupabaseToken, updateAcademicInfo);
router.put("/interests", validateSupabaseToken, updateInterests);
router.put("/personal-info", validateSupabaseToken, updatePersonalInfo);
router.put("/pictures", validateSupabaseToken, updatePictures);
router.put("/social-links", validateSupabaseToken, updateSocialLinks);

export default router;
