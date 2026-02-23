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

  res.status(200).json(result);
});

export const markAsSeen = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  await notificationService.markAsSeen(userId);

  res.status(200).json({ message: "Notifications marked as seen" });
});
