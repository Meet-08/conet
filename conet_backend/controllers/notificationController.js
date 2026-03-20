import asyncHandler from "express-async-handler";
import notificationService from "../services/notificationService.js";

export const getNotifications = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { limit, cursor } = req.query;

  const result = await notificationService.getNotifications(
    userId,
    limit ? parseInt(limit, 10) : 20,
    cursor,
  );

  const notifications = result.notifications.map((n) => {
    const actor = n.users_notifications_actor_idTousers;
    const { users_notifications_actor_idTousers: _, ...rest } = n;
    return {
      ...rest,
      actor_first_name: actor?.first_name ?? null,
      actor_last_name: actor?.last_name ?? null,
      actor_username: actor?.username ?? null,
      actor_profile_pic_url: actor?.profile_pic_url ?? null,
    };
  });

  res.status(200).json({ ...result, notifications });
});

export const markAsSeen = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  await notificationService.markAsSeen(userId);

  res.status(200).json({ message: "Notifications marked as seen" });
});
