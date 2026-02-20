import asyncHandler from "express-async-handler";
import {
  followUserService,
  getUserProfileService,
  unfollowUserService,
  updateAboutMeService,
  updateAcademicInfoService,
  updateInterestsService,
  updatePersonalInfoService,
  updatePicturesService,
  updateSocialLinksService,
} from "../services/profileService.js";

// GET USER PROFILE
export const getUserProfile = asyncHandler(async (req, res) => {
  const { uid } = req.params;
  const viewerId = req.user?.id ?? null;

  const profile = await getUserProfileService(uid, viewerId);

  res.status(200).json({
    success: true,
    profile,
  });
});

// FOLLOW USER
export const followUser = asyncHandler(async (req, res) => {
  const followerId = req.user.id;
  const { uid: followingId } = req.params;

  await followUserService(followerId, followingId);

  res.status(200).json({
    success: true,
    message: "User followed successfully",
  });
});

// UNFOLLOW USER
export const unfollowUser = asyncHandler(async (req, res) => {
  const followerId = req.user.id;
  const { uid: followingId } = req.params;

  await unfollowUserService(followerId, followingId);

  res.status(200).json({
    success: true,
    message: "User unfollowed successfully",
  });
});

// UPDATE ABOUT ME
export const updateAboutMe = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { about_me } = req.body;

  if (about_me === undefined) {
    res.status(400);
    throw new Error("about_me is required");
  }

  const user = await updateAboutMeService(userId, about_me);

  res.status(200).json({
    success: true,
    message: "About me updated successfully",
    user,
  });
});

// UPDATE ACADEMIC INFO
export const updateAcademicInfo = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { college_name, course, major, start_year, end_year } = req.body;

  if (!college_name || !course) {
    res.status(400);
    throw new Error("college_name and course are required");
  }

  const user = await updateAcademicInfoService(userId, {
    college_name,
    course,
    major,
    start_year,
    end_year,
  });

  res.status(200).json({
    success: true,
    message: "Academic info updated successfully",
    user,
  });
});

// UPDATE INTERESTS
export const updateInterests = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { interests } = req.body;

  if (!Array.isArray(interests)) {
    res.status(400);
    throw new Error("interests must be an array");
  }

  const user = await updateInterestsService(userId, interests);

  res.status(200).json({
    success: true,
    message: "Interests updated successfully",
    user,
  });
});

// UPDATE PERSONAL INFO
export const updatePersonalInfo = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { first_name, last_name, date_of_birth } = req.body;

  const user = await updatePersonalInfoService(userId, {
    first_name,
    last_name,
    date_of_birth,
  });

  res.status(200).json({
    success: true,
    message: "Personal info updated successfully",
    user,
  });
});

// UPDATE PICTURES
export const updatePictures = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { profile_pic_url, banner_url } = req.body;

  if (!profile_pic_url && !banner_url) {
    res.status(400);
    throw new Error(
      "At least one of profile_pic_url or banner_url is required",
    );
  }

  const user = await updatePicturesService(userId, {
    profile_pic_url,
    banner_url,
  });

  res.status(200).json({
    success: true,
    message: "Pictures updated successfully",
    user,
  });
});

// UPDATE SOCIAL LINKS
export const updateSocialLinks = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { social_links } = req.body;

  if (!Array.isArray(social_links)) {
    res.status(400);
    throw new Error("social_links must be an array");
  }

  const user = await updateSocialLinksService(userId, social_links);

  res.status(200).json({
    success: true,
    message: "Social links updated successfully",
    user,
  });
});
