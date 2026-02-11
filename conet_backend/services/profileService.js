import { USER_SELECT_FIELDS } from "../config/constants.js";
import prisma from "../config/prisma.js";

// ─── Full profile select fields (extends USER_SELECT_FIELDS) ────────────────

const PROFILE_SELECT_FIELDS = {
  ...USER_SELECT_FIELDS,
  about_me: true,
  banner_image_url: true,
  interests: true,
  social_links: true,
  date_of_birth: true,
  gender: true,
  user_academics: true,
};

// ─── Get user profile by ID ────────────────────────────────────────────────

export const getUserProfileService = async (uid) => {
  const user = await prisma.users.findUnique({
    where: { id: uid },
    select: {
      ...PROFILE_SELECT_FIELDS,
      _count: {
        select: {
          user_follows_user_follows_following_idTousers: true, // follower count
          user_follows_user_follows_follower_idTousers: true, // following count
        },
      },
    },
  });

  if (!user) {
    const err = new Error("User not found");
    err.statusCode = 404;
    throw err;
  }

  // Parse social_links from JSON if stored as string
  let socialLinks = [];
  if (user.social_links) {
    socialLinks =
      typeof user.social_links === "string" ? JSON.parse(user.social_links)
      : Array.isArray(user.social_links) ? user.social_links
      : [];
  }

  return {
    id: user.id,
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    username: user.username,
    profile_pic_url: user.profile_pic_url,
    user_role: user.user_role,
    is_verified: user.is_verified ?? false,
    about_me: user.about_me,
    banner_image_url: user.banner_image_url,
    interests: user.interests ?? [],
    social_links: socialLinks,
    date_of_birth: user.date_of_birth,
    user_academics: user.user_academics ?? [],
    follower_count:
      user._count.user_follows_user_follows_following_idTousers ?? 0,
    following_count:
      user._count.user_follows_user_follows_follower_idTousers ?? 0,
  };
};

// ─── Update about me ───────────────────────────────────────────────────────

export const updateAboutMeService = async (userId, aboutMe) => {
  const user = await prisma.users.update({
    where: { id: userId },
    data: { about_me: aboutMe },
    select: USER_SELECT_FIELDS,
  });

  return user;
};

// ─── Update academic info ──────────────────────────────────────────────────

export const updateAcademicInfoService = async (
  userId,
  { college_name, course, major, start_year, end_year },
) => {
  // Upsert: update if exists, create if not
  const existing = await prisma.user_academics.findFirst({
    where: { user_id: userId },
  });

  if (existing) {
    await prisma.user_academics.update({
      where: { id: existing.id },
      data: {
        college_name,
        course,
        major: major ?? null,
        start_year: start_year ?? null,
        end_year: end_year ?? null,
      },
    });
  } else {
    await prisma.user_academics.create({
      data: {
        user_id: userId,
        college_name,
        course,
        major: major ?? null,
        start_year: start_year ?? null,
        end_year: end_year ?? null,
      },
    });
  }

  const user = await prisma.users.findUnique({
    where: { id: userId },
    select: USER_SELECT_FIELDS,
  });

  return user;
};

// ─── Update interests ──────────────────────────────────────────────────────

export const updateInterestsService = async (userId, interests) => {
  const user = await prisma.users.update({
    where: { id: userId },
    data: { interests },
    select: USER_SELECT_FIELDS,
  });

  return user;
};

// ─── Update personal info ──────────────────────────────────────────────────

export const updatePersonalInfoService = async (
  userId,
  { first_name, last_name, date_of_birth },
) => {
  const data = {};
  if (first_name !== undefined) data.first_name = first_name;
  if (last_name !== undefined) data.last_name = last_name;
  if (date_of_birth !== undefined) data.date_of_birth = new Date(date_of_birth);

  const user = await prisma.users.update({
    where: { id: userId },
    data,
    select: USER_SELECT_FIELDS,
  });

  return user;
};

// ─── Update pictures ───────────────────────────────────────────────────────

export const updatePicturesService = async (
  userId,
  { profile_pic_url, banner_url },
) => {
  const data = {};
  if (profile_pic_url !== undefined) data.profile_pic_url = profile_pic_url;
  if (banner_url !== undefined) data.banner_image_url = banner_url;

  const user = await prisma.users.update({
    where: { id: userId },
    data,
    select: USER_SELECT_FIELDS,
  });

  return user;
};

// ─── Update social links ──────────────────────────────────────────────────

export const updateSocialLinksService = async (userId, socialLinks) => {
  const user = await prisma.users.update({
    where: { id: userId },
    data: { social_links: socialLinks },
    select: USER_SELECT_FIELDS,
  });

  return user;
};
