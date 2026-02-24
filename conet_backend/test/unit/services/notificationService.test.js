/**
 * Unit tests – notificationService.js
 *
 * Coverage targets:
 *  ✓ createNotification – self-action skip, enqueue payload, custom content
 *  ✓ markAsSeen         – updateMany query and error propagation
 *  ✓ getNotifications   – default query, cursor pagination, unseen fallback
 */

import { beforeEach, describe, expect, it, mock } from "bun:test";
import { TEST_USER, TEST_USER_B } from "../../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../../mocks/prismaMock.js";

const queueAddMock = mock(() => Promise.resolve({ id: "job-1" }));
const loggerErrorMock = mock(() => undefined);

mock.module("../../../config/prisma.js", () => ({ default: prismaMock }));
mock.module("../../../config/queue.js", () => ({
  notificationQueue: {
    add: queueAddMock,
  },
}));
mock.module("../../../config/logger.js", () => ({
  default: {
    error: loggerErrorMock,
    info: mock(() => undefined),
  },
}));

import notificationService from "../../../services/notificationService.js";

const NOTIFICATION_ID = "99999999-9999-9999-9999-999999999999";

beforeEach(() => {
  resetPrismaMocks();
  queueAddMock.mockReset();
  queueAddMock.mockResolvedValue({ id: "job-1" });
  loggerErrorMock.mockReset();
});

describe("createNotification", () => {
  it("returns null and skips DB/queue when actorId equals receiverId", async () => {
    const result = await notificationService.createNotification({
      receiverId: TEST_USER.id,
      actorId: TEST_USER.id,
      type: "POST_LIKE",
      referenceId: "post-1",
    });

    expect(result).toBeNull();
    expect(prismaMock.notifications.create).not.toHaveBeenCalled();
    expect(queueAddMock).not.toHaveBeenCalled();
  });

  it("creates notification and enqueues push with generated title/body", async () => {
    prismaMock.notifications.create.mockResolvedValue({
      id: NOTIFICATION_ID,
      receiver_id: TEST_USER.id,
      actor_id: TEST_USER_B.id,
      type: "POST_LIKE",
      reference_id: "post-1",
      content: null,
    });

    const result = await notificationService.createNotification({
      receiverId: TEST_USER.id,
      actorId: TEST_USER_B.id,
      type: "POST_LIKE",
      referenceId: "post-1",
    });

    expect(result.id).toBe(NOTIFICATION_ID);
    expect(prismaMock.notifications.create).toHaveBeenCalledWith({
      data: {
        receiver_id: TEST_USER.id,
        actor_id: TEST_USER_B.id,
        type: "POST_LIKE",
        reference_id: "post-1",
        content: undefined,
      },
    });
    expect(queueAddMock).toHaveBeenCalledWith("sendPushNotification", {
      receiverId: TEST_USER.id,
      title: "New Like",
      body: "Someone liked your post.",
      type: "POST_LIKE",
      referenceId: "post-1",
    });
  });

  it("uses explicit content as queue body when provided", async () => {
    prismaMock.notifications.create.mockResolvedValue({
      id: NOTIFICATION_ID,
      receiver_id: TEST_USER.id,
      actor_id: TEST_USER_B.id,
      type: "POST_COMMENT",
      reference_id: "post-2",
      content: "Bob commented: Nice!",
    });

    await notificationService.createNotification({
      receiverId: TEST_USER.id,
      actorId: TEST_USER_B.id,
      type: "POST_COMMENT",
      referenceId: "post-2",
      content: "Bob commented: Nice!",
    });

    expect(queueAddMock).toHaveBeenCalledWith("sendPushNotification", {
      receiverId: TEST_USER.id,
      title: "New Comment",
      body: "Bob commented: Nice!",
      type: "POST_COMMENT",
      referenceId: "post-2",
    });
  });

  it("rethrows prisma errors and logs failure", async () => {
    const dbError = new Error("db down");
    prismaMock.notifications.create.mockRejectedValue(dbError);

    await expect(
      notificationService.createNotification({
        receiverId: TEST_USER.id,
        actorId: TEST_USER_B.id,
        type: "NEW_MESSAGE",
      }),
    ).rejects.toBe(dbError);

    expect(loggerErrorMock).toHaveBeenCalled();
  });
});

describe("markAsSeen", () => {
  it("marks all unseen user notifications as seen", async () => {
    prismaMock.notifications.updateMany.mockResolvedValue({ count: 3 });

    await notificationService.markAsSeen(TEST_USER.id);

    expect(prismaMock.notifications.updateMany).toHaveBeenCalledWith({
      where: {
        receiver_id: TEST_USER.id,
        is_seen: false,
      },
      data: {
        is_seen: true,
      },
    });
  });

  it("rethrows update errors", async () => {
    const updateError = new Error("write failed");
    prismaMock.notifications.updateMany.mockRejectedValue(updateError);

    await expect(notificationService.markAsSeen(TEST_USER.id)).rejects.toBe(
      updateError,
    );
  });
});

describe("getNotifications", () => {
  it("returns notifications and unseen count with default query", async () => {
    const rows = [
      {
        id: NOTIFICATION_ID,
        receiver_id: TEST_USER.id,
        actor_id: TEST_USER_B.id,
        type: "NEW_MESSAGE",
        created_at: new Date(),
      },
    ];

    prismaMock.notifications.findMany.mockResolvedValue(rows);
    prismaMock.users.findUnique.mockResolvedValue({
      unseen_notification_count: 7,
    });

    const result = await notificationService.getNotifications(TEST_USER.id);

    expect(result).toEqual({ notifications: rows, unseenCount: 7 });
    expect(prismaMock.notifications.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { receiver_id: TEST_USER.id },
        orderBy: { created_at: "desc" },
        take: 20,
      }),
    );
    expect(prismaMock.users.findUnique).toHaveBeenCalledWith({
      where: { id: TEST_USER.id },
      select: { unseen_notification_count: true },
    });
  });

  it("applies cursor pagination when cursor is provided", async () => {
    prismaMock.notifications.findMany.mockResolvedValue([]);
    prismaMock.users.findUnique.mockResolvedValue({
      unseen_notification_count: 0,
    });

    await notificationService.getNotifications(
      TEST_USER.id,
      10,
      NOTIFICATION_ID,
    );

    expect(prismaMock.notifications.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        take: 10,
        cursor: { id: NOTIFICATION_ID },
        skip: 1,
      }),
    );
  });

  it("defaults unseenCount to 0 when user row is missing", async () => {
    prismaMock.notifications.findMany.mockResolvedValue([]);
    prismaMock.users.findUnique.mockResolvedValue(null);

    const result = await notificationService.getNotifications(TEST_USER.id);

    expect(result.unseenCount).toBe(0);
  });
});
