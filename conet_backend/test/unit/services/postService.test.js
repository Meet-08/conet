/**
 * Unit tests – postService.js
 *
 * Coverage targets:
 *  ✓ createPostService        – success, defaults media_urls to []
 *  ✓ getAllPostsService        – pagination math, viewer like status
 *  ✓ getPostService           – found, 404
 *  ✓ getUserPostsService      – pagination + total, $transaction used
 *  ✓ updatePostService        – success, 404, 403 (wrong owner)
 *  ✓ deletePostService        – success, 404, 403 (wrong owner), cascade note
 *  ✓ toggleLikeService        – like → unlike → like cycle, 404
 *  ✓ addCommentService        – success, post 404
 *  ✓ getPostCommentsService   – success, post 404, mapping
 *  ✓ editCommentService       – success, 404, 403
 *  ✓ deleteCommentService     – success, 404, 403
 */

import { beforeEach, describe, expect, it, mock } from "bun:test";
import { TEST_USER, TEST_USER_B } from "../../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../../mocks/prismaMock.js";

mock.module("../../../config/prisma.js", () => ({ default: prismaMock }));

import {
  addCommentService,
  createPostService,
  deleteCommentService,
  deletePostService,
  editCommentService,
  getAllPostsService,
  getPostCommentsService,
  getPostService,
  getUserPostsService,
  toggleLikeService,
  updatePostService,
} from "../../../services/postService.js";

// ─── Fixtures ──────────────────────────────────────────────────────────────

const POST_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const COMMENT_ID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";

const mockUser = {
  id: TEST_USER.id,
  username: "alice",
  email: TEST_USER.email,
  first_name: "Alice",
  last_name: "Smith",
  profile_pic_url: null,
  user_role: "user",
  is_verified: false,
};

const mockPost = {
  id: POST_ID,
  user_id: TEST_USER.id,
  user: mockUser,
  content: "Hello campus!",
  media_urls: [],
  like_count: 0,
  comment_count: 0,
  created_at: new Date(),
  updated_at: new Date(),
  post_likes: [],
  post_comments: [],
  _count: { post_likes: 0, post_comments: 0 },
};

const mockComment = {
  id: COMMENT_ID,
  post_id: POST_ID,
  user_id: TEST_USER.id,
  content: "Great post!",
  created_at: new Date(),
  user: mockUser,
};

beforeEach(() => {
  resetPrismaMocks();
});

// ─────────────────────────────────────────────────────────────────────────────
describe("createPostService", () => {
  it("creates a post and returns it", async () => {
    prismaMock.posts.create.mockResolvedValue(mockPost);

    const result = await createPostService(TEST_USER.id, {
      content: "Hello campus!",
    });

    expect(result.id).toBe(POST_ID);
    expect(prismaMock.posts.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          content: "Hello campus!",
          user_id: TEST_USER.id,
        }),
      }),
    );
  });

  it("defaults media_urls to [] when omitted", async () => {
    prismaMock.posts.create.mockResolvedValue(mockPost);

    await createPostService(TEST_USER.id, { content: "Text only" });

    const callData = prismaMock.posts.create.mock.calls[0][0].data;
    expect(callData.media_urls).toEqual([]);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("getAllPostsService", () => {
  it("returns mapped posts array", async () => {
    prismaMock.posts.findMany.mockResolvedValue([mockPost]);

    const result = await getAllPostsService(1, 20);

    expect(result).toHaveLength(1);
    expect(result[0].id).toBe(POST_ID);
  });

  it("calculates skip correctly from page/limit", async () => {
    prismaMock.posts.findMany.mockResolvedValue([]);

    await getAllPostsService(3, 10); // skip = (3-1)*10 = 20

    expect(prismaMock.posts.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 20, take: 10 }),
    );
  });

  it("includes post_likes filter when viewerId is provided", async () => {
    prismaMock.posts.findMany.mockResolvedValue([]);

    await getAllPostsService(1, 20, TEST_USER.id);

    const arg = prismaMock.posts.findMany.mock.calls[0][0];
    expect(arg.include.post_likes).toMatchObject({
      where: { user_id: TEST_USER.id },
    });
  });

  it("excludes post_likes include when viewerId is null (public feed)", async () => {
    prismaMock.posts.findMany.mockResolvedValue([]);

    await getAllPostsService(1, 20, null);

    const arg = prismaMock.posts.findMany.mock.calls[0][0];
    expect(arg.include.post_likes).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("getPostService", () => {
  it("returns the post when found", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);

    const result = await getPostService(POST_ID);

    expect(result.id).toBe(POST_ID);
  });

  it("throws 404 when post does not exist", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(null);

    await expect(getPostService("ghost")).rejects.toMatchObject({
      message: "Post not found",
      statusCode: 404,
    });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("getUserPostsService", () => {
  it("returns posts with pagination metadata", async () => {
    prismaMock.$transaction.mockResolvedValue([[mockPost], 1]);

    const result = await getUserPostsService(TEST_USER.id, 1, 10);

    expect(result.total).toBe(1);
    expect(result.totalPages).toBe(1);
    expect(result.page).toBe(1);
    expect(result.posts).toHaveLength(1);
  });

  it("uses $transaction for atomic count + list", async () => {
    prismaMock.$transaction.mockResolvedValue([[], 0]);

    await getUserPostsService(TEST_USER.id, 1, 20);

    expect(prismaMock.$transaction).toHaveBeenCalled();
  });

  it("calculates totalPages correctly", async () => {
    prismaMock.$transaction.mockResolvedValue([[], 45]);

    const result = await getUserPostsService(TEST_USER.id, 1, 20);

    expect(result.totalPages).toBe(3); // ceil(45/20) = 3
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("updatePostService", () => {
  it("updates and returns the post when owner calls it", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.posts.update.mockResolvedValue({
      ...mockPost,
      content: "Updated",
    });

    const result = await updatePostService(POST_ID, TEST_USER.id, {
      content: "Updated",
    });

    expect(result.content).toBe("Updated");
  });

  it("throws 404 when post does not exist", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(null);

    await expect(
      updatePostService("ghost", TEST_USER.id, { content: "x" }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it("throws 403 when a different user attempts update", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);

    await expect(
      updatePostService(POST_ID, TEST_USER_B.id, { content: "x" }),
    ).rejects.toMatchObject({
      message: "Not authorized to update this post",
      statusCode: 403,
    });

    // Prisma update must NOT be called after authorization failure
    expect(prismaMock.posts.update).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("deletePostService", () => {
  it("deletes the post when owner calls it", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.posts.delete.mockResolvedValue(mockPost);

    await expect(
      deletePostService(POST_ID, TEST_USER.id),
    ).resolves.toBeUndefined();

    expect(prismaMock.posts.delete).toHaveBeenCalledWith({
      where: { id: POST_ID },
    });
  });

  it("throws 404 when post does not exist", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(null);

    await expect(
      deletePostService("ghost", TEST_USER.id),
    ).rejects.toMatchObject({
      statusCode: 404,
    });
  });

  it("throws 403 when a different user attempts deletion", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);

    await expect(
      deletePostService(POST_ID, TEST_USER_B.id),
    ).rejects.toMatchObject({
      message: "Not authorized to delete this post",
      statusCode: 403,
    });

    expect(prismaMock.posts.delete).not.toHaveBeenCalled();
  });

  it("does NOT manually delete related records (relies on DB CASCADE)", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.posts.delete.mockResolvedValue(mockPost);

    await deletePostService(POST_ID, TEST_USER.id);

    // Cascade is handled by the DB schema; service must not duplicate it
    expect(prismaMock.post_likes.deleteMany).not.toHaveBeenCalled();
    expect(prismaMock.post_comments.deleteMany).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("toggleLikeService", () => {
  it("creates a like when post is not yet liked", async () => {
    prismaMock.posts.findUnique
      .mockResolvedValueOnce(mockPost) // existence check
      .mockResolvedValueOnce({ ...mockPost, like_count: 1 }); // post-update fetch
    prismaMock.post_likes.findUnique.mockResolvedValue(null); // not liked
    prismaMock.post_likes.create.mockResolvedValue({});

    const result = await toggleLikeService(POST_ID, TEST_USER.id);

    expect(result.liked).toBe(true);
    expect(result.like_count).toBe(1);
    expect(prismaMock.post_likes.create).toHaveBeenCalled();
    expect(prismaMock.post_likes.delete).not.toHaveBeenCalled();
  });

  it("removes the like when post is already liked (unlike)", async () => {
    prismaMock.posts.findUnique
      .mockResolvedValueOnce(mockPost)
      .mockResolvedValueOnce({ ...mockPost, like_count: 0 });
    prismaMock.post_likes.findUnique.mockResolvedValue({
      post_id: POST_ID,
      user_id: TEST_USER.id,
    });
    prismaMock.post_likes.delete.mockResolvedValue({});

    const result = await toggleLikeService(POST_ID, TEST_USER.id);

    expect(result.liked).toBe(false);
    expect(prismaMock.post_likes.delete).toHaveBeenCalled();
    expect(prismaMock.post_likes.create).not.toHaveBeenCalled();
  });

  it("throws 404 when post does not exist", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(null);

    await expect(
      toggleLikeService("ghost", TEST_USER.id),
    ).rejects.toMatchObject({
      statusCode: 404,
    });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("addCommentService", () => {
  it("creates and returns a mapped comment", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.post_comments.create.mockResolvedValue(mockComment);

    const result = await addCommentService(
      POST_ID,
      TEST_USER.id,
      "Great post!",
    );

    expect(result.content).toBe("Great post!");
    expect(result.username).toBe("alice");
  });

  it("throws 404 when post does not exist", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(null);

    await expect(
      addCommentService("ghost", TEST_USER.id, "hi"),
    ).rejects.toMatchObject({ statusCode: 404 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("getPostCommentsService", () => {
  it("returns an array of mapped comments", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(mockPost);
    prismaMock.post_comments.findMany.mockResolvedValue([mockComment]);

    const result = await getPostCommentsService(POST_ID);

    expect(result).toHaveLength(1);
    expect(result[0].username).toBe("alice");
    expect(result[0].content).toBe("Great post!");
  });

  it("throws 404 when post does not exist", async () => {
    prismaMock.posts.findUnique.mockResolvedValue(null);

    await expect(getPostCommentsService("ghost")).rejects.toMatchObject({
      statusCode: 404,
    });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("editCommentService", () => {
  it("updates and returns the comment when owner calls it", async () => {
    prismaMock.post_comments.findUnique.mockResolvedValue(mockComment);
    prismaMock.post_comments.update.mockResolvedValue({
      ...mockComment,
      content: "Edited!",
    });

    const result = await editCommentService(
      POST_ID,
      COMMENT_ID,
      TEST_USER.id,
      "Edited!",
    );

    expect(result.content).toBe("Edited!");
  });

  it("throws 404 when comment does not exist", async () => {
    prismaMock.post_comments.findUnique.mockResolvedValue(null);

    await expect(
      editCommentService(POST_ID, "ghost", TEST_USER.id, "x"),
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it("throws 403 when a different user attempts to edit", async () => {
    prismaMock.post_comments.findUnique.mockResolvedValue(mockComment);

    await expect(
      editCommentService(POST_ID, COMMENT_ID, TEST_USER_B.id, "x"),
    ).rejects.toMatchObject({
      message: "Not authorized to edit this comment",
      statusCode: 403,
    });

    expect(prismaMock.post_comments.update).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("deleteCommentService", () => {
  it("deletes the comment when owner calls it", async () => {
    prismaMock.post_comments.findUnique.mockResolvedValue(mockComment);
    prismaMock.post_comments.delete.mockResolvedValue({});

    await expect(
      deleteCommentService(POST_ID, COMMENT_ID, TEST_USER.id),
    ).resolves.toBeUndefined();

    expect(prismaMock.post_comments.delete).toHaveBeenCalledWith({
      where: { id: COMMENT_ID },
    });
  });

  it("throws 404 when comment does not exist", async () => {
    prismaMock.post_comments.findUnique.mockResolvedValue(null);

    await expect(
      deleteCommentService(POST_ID, "ghost", TEST_USER.id),
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it("throws 403 when a different user attempts deletion", async () => {
    prismaMock.post_comments.findUnique.mockResolvedValue(mockComment);

    await expect(
      deleteCommentService(POST_ID, COMMENT_ID, TEST_USER_B.id),
    ).rejects.toMatchObject({
      message: "Not authorized to delete this comment",
      statusCode: 403,
    });

    expect(prismaMock.post_comments.delete).not.toHaveBeenCalled();
  });
});
