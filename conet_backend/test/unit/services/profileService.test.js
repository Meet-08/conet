/**
 * Unit tests – profileService.js
 *
 * Strategy: mock the Prisma client at module level.
 * Every Prisma call is intercepted; no real DB connection is made.
 *
 * Coverage targets:
 *  ✓ getUserProfileService  – found, not found, with/without viewer, social_links parsing
 *  ✓ followUserService     – success, self-follow, user-not-found, duplicate (upsert idempotent)
 *  ✓ unfollowUserService   – success, self-unfollow guard
 *  ✓ updateAboutMeService  – success, Prisma error propagation
 *  ✓ updateAcademicInfoService – first create, subsequent update
 *  ✓ updateInterestsService
 *  ✓ updatePersonalInfoService – partial fields
 *  ✓ updatePicturesService
 *  ✓ updateSocialLinksService
 */

import { beforeEach, describe, expect, it, mock } from "bun:test";
import { TEST_USER, TEST_USER_B } from "../../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../../mocks/prismaMock.js";

// ── Module mock must be declared before the import of the module under test ──
// Bun hoists mock.module() calls before static imports resolve.
mock.module("../../../config/prisma.js", () => ({ default: prismaMock }));

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
} from "../../../services/profileService.js";

// ─── Fixtures ──────────────────────────────────────────────────────────────

const mockUserRow = {
  id: TEST_USER.id,
  email: TEST_USER.email,
  first_name: "Alice",
  last_name: "Smith",
  username: "alice",
  profile_pic_url: null,
  user_role: "user",
  is_verified: false,
  about_me: "Hello world",
  banner_image_url: null,
  interests: ["math", "cs"],
  social_links: [{ platform: "github", url: "https://github.com/alice" }],
  date_of_birth: null,
  gender: null,
  user_academics: [],
  _count: {
    user_follows_user_follows_following_idTousers: 5, // follower_count
    user_follows_user_follows_follower_idTousers: 3, // following_count
  },
};

beforeEach(() => {
  resetPrismaMocks();
});

// ─────────────────────────────────────────────────────────────────────────────
describe("getUserProfileService", () => {
  it("returns a mapped profile when user exists", async () => {
    prismaMock.users.findUnique.mockResolvedValue(mockUserRow);

    const result = await getUserProfileService(TEST_USER.id);

    expect(result.id).toBe(TEST_USER.id);
    expect(result.follower_count).toBe(5);
    expect(result.following_count).toBe(3);
    expect(result.is_following).toBe(false);
    expect(Array.isArray(result.social_links)).toBe(true);
  });

  it("throws 404 when user does not exist", async () => {
    prismaMock.users.findUnique.mockResolvedValue(null);

    await expect(getUserProfileService("nonexistent-id")).rejects.toMatchObject(
      {
        message: "User not found",
        statusCode: 404,
      },
    );
  });

  it("sets is_following=true when viewer follows the profile owner", async () => {
    prismaMock.users.findUnique.mockResolvedValue(mockUserRow);
    // The second findUnique call checks the follow relationship
    prismaMock.user_follows.findUnique.mockResolvedValue({
      follower_id: TEST_USER_B.id,
      following_id: TEST_USER.id,
    });

    const result = await getUserProfileService(TEST_USER.id, TEST_USER_B.id);

    expect(result.is_following).toBe(true);
  });

  it("sets is_following=false when viewer is same as profile owner", async () => {
    prismaMock.users.findUnique.mockResolvedValue(mockUserRow);

    const result = await getUserProfileService(TEST_USER.id, TEST_USER.id);

    // No follow check made for self; always false
    expect(result.is_following).toBe(false);
    expect(prismaMock.user_follows.findUnique).not.toHaveBeenCalled();
  });

  it("parses social_links correctly when stored as a JSON string", async () => {
    prismaMock.users.findUnique.mockResolvedValue({
      ...mockUserRow,
      social_links: JSON.stringify([
        { platform: "x", url: "https://x.com/alice" },
      ]),
    });

    const result = await getUserProfileService(TEST_USER.id);

    expect(result.social_links).toEqual([
      { platform: "x", url: "https://x.com/alice" },
    ]);
  });

  it("returns empty interests array if null in DB", async () => {
    prismaMock.users.findUnique.mockResolvedValue({
      ...mockUserRow,
      interests: null,
    });

    const result = await getUserProfileService(TEST_USER.id);

    expect(result.interests).toEqual([]);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("followUserService", () => {
  it("creates a follow relationship", async () => {
    prismaMock.users.findUnique.mockResolvedValue({ id: TEST_USER_B.id });
    prismaMock.user_follows.upsert.mockResolvedValue({});

    await expect(
      followUserService(TEST_USER.id, TEST_USER_B.id),
    ).resolves.toBeUndefined();

    expect(prismaMock.user_follows.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: {
          follower_id: TEST_USER.id,
          following_id: TEST_USER_B.id,
        },
      }),
    );
  });

  it("throws 400 when trying to follow yourself", async () => {
    await expect(
      followUserService(TEST_USER.id, TEST_USER.id),
    ).rejects.toMatchObject({
      message: "You cannot follow yourself",
      statusCode: 400,
    });

    expect(prismaMock.users.findUnique).not.toHaveBeenCalled();
  });

  it("throws 404 when target user does not exist", async () => {
    prismaMock.users.findUnique.mockResolvedValue(null);

    await expect(
      followUserService(TEST_USER.id, "ghost-user-id"),
    ).rejects.toMatchObject({
      message: "User not found",
      statusCode: 404,
    });
  });

  it("is idempotent – upsert silently ignores duplicate follows", async () => {
    prismaMock.users.findUnique.mockResolvedValue({ id: TEST_USER_B.id });
    // Upsert returns existing row on duplicate; no error
    prismaMock.user_follows.upsert.mockResolvedValue({
      follower_id: TEST_USER.id,
      following_id: TEST_USER_B.id,
    });

    // Should not throw on a second call
    await expect(
      followUserService(TEST_USER.id, TEST_USER_B.id),
    ).resolves.toBeUndefined();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("unfollowUserService", () => {
  it("deletes the follow relationship", async () => {
    prismaMock.user_follows.deleteMany.mockResolvedValue({ count: 1 });

    await expect(
      unfollowUserService(TEST_USER.id, TEST_USER_B.id),
    ).resolves.toBeUndefined();

    expect(prismaMock.user_follows.deleteMany).toHaveBeenCalledWith({
      where: {
        follower_id: TEST_USER.id,
        following_id: TEST_USER_B.id,
      },
    });
  });

  it("throws 400 when trying to unfollow yourself", async () => {
    await expect(
      unfollowUserService(TEST_USER.id, TEST_USER.id),
    ).rejects.toMatchObject({
      message: "You cannot unfollow yourself",
      statusCode: 400,
    });
  });

  it("is a no-op (does not throw) when follow relationship does not exist", async () => {
    // deleteMany with count: 0 means nothing was deleted – should not throw
    prismaMock.user_follows.deleteMany.mockResolvedValue({ count: 0 });

    await expect(
      unfollowUserService(TEST_USER.id, TEST_USER_B.id),
    ).resolves.toBeUndefined();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("updateAboutMeService", () => {
  it("updates and returns the user", async () => {
    const updatedUser = { id: TEST_USER.id, about_me: "New bio" };
    prismaMock.users.update.mockResolvedValue(updatedUser);

    const result = await updateAboutMeService(TEST_USER.id, "New bio");

    expect(result).toEqual(updatedUser);
    expect(prismaMock.users.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { about_me: "New bio" } }),
    );
  });

  it("propagates Prisma errors as-is", async () => {
    prismaMock.users.update.mockRejectedValue(new Error("DB connection lost"));

    await expect(updateAboutMeService(TEST_USER.id, "bio")).rejects.toThrow(
      "DB connection lost",
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("updateAcademicInfoService", () => {
  it("creates academic record when none exists", async () => {
    prismaMock.user_academics.findFirst.mockResolvedValue(null);
    prismaMock.user_academics.create.mockResolvedValue({});
    prismaMock.users.findUnique.mockResolvedValue({ id: TEST_USER.id });

    await updateAcademicInfoService(TEST_USER.id, {
      college_name: "MIT",
      course: "CS",
    });

    expect(prismaMock.user_academics.create).toHaveBeenCalled();
    expect(prismaMock.user_academics.update).not.toHaveBeenCalled();
  });

  it("updates existing academic record", async () => {
    prismaMock.user_academics.findFirst.mockResolvedValue({ id: "acad-1" });
    prismaMock.user_academics.update.mockResolvedValue({});
    prismaMock.users.findUnique.mockResolvedValue({ id: TEST_USER.id });

    await updateAcademicInfoService(TEST_USER.id, {
      college_name: "Stanford",
      course: "Physics",
    });

    expect(prismaMock.user_academics.update).toHaveBeenCalled();
    expect(prismaMock.user_academics.create).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("updateInterestsService", () => {
  it("saves an array of interests", async () => {
    prismaMock.users.update.mockResolvedValue({ interests: ["math", "cs"] });

    const result = await updateInterestsService(TEST_USER.id, ["math", "cs"]);

    expect(prismaMock.users.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { interests: ["math", "cs"] } }),
    );
    expect(result.interests).toEqual(["math", "cs"]);
  });

  it("accepts an empty array (clearing interests)", async () => {
    prismaMock.users.update.mockResolvedValue({ interests: [] });

    const result = await updateInterestsService(TEST_USER.id, []);

    expect(result.interests).toEqual([]);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("updatePersonalInfoService", () => {
  it("updates only provided fields (partial update)", async () => {
    prismaMock.users.update.mockResolvedValue({ first_name: "Bob" });

    await updatePersonalInfoService(TEST_USER.id, { first_name: "Bob" });

    expect(prismaMock.users.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { first_name: "Bob" } }),
    );
    // last_name not passed, should not appear in data
    const callArgs = prismaMock.users.update.mock.calls[0][0];
    expect(callArgs.data.last_name).toBeUndefined();
  });

  it("converts date_of_birth string to a Date object", async () => {
    prismaMock.users.update.mockResolvedValue({});

    await updatePersonalInfoService(TEST_USER.id, {
      date_of_birth: "1999-05-20",
    });

    const callArgs = prismaMock.users.update.mock.calls[0][0];
    expect(callArgs.data.date_of_birth).toBeInstanceOf(Date);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("updatePicturesService", () => {
  it("updates profile_pic_url", async () => {
    prismaMock.users.update.mockResolvedValue({});

    await updatePicturesService(TEST_USER.id, {
      profile_pic_url: "https://cdn.example.com/pic.jpg",
    });

    const callArgs = prismaMock.users.update.mock.calls[0][0];
    expect(callArgs.data.profile_pic_url).toBe(
      "https://cdn.example.com/pic.jpg",
    );
    expect(callArgs.data.banner_image_url).toBeUndefined();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("updateSocialLinksService", () => {
  it("saves social links JSON", async () => {
    const links = [
      { platform: "linkedin", url: "https://linkedin.com/in/alice" },
    ];
    prismaMock.users.update.mockResolvedValue({ social_links: links });

    const result = await updateSocialLinksService(TEST_USER.id, links);

    expect(prismaMock.users.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { social_links: links } }),
    );
  });
});
