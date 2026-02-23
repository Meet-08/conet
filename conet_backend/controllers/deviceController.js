import asyncHandler from "express-async-handler";
import {
  registerDeviceService,
  removeDeviceService,
} from "../services/deviceService.js";

// POST /api/devices/register
export const registerDevice = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { fcm_token, platform, device_name } = req.body;

  if (!fcm_token || !platform) {
    res.status(400);
    throw new Error("fcm_token and platform are required");
  }

  const device = await registerDeviceService(
    userId,
    fcm_token,
    platform,
    device_name,
  );

  res.status(200).json({
    success: true,
    message: "Device registered successfully",
    data: device,
  });
});

// DELETE /api/devices/current
export const removeDevice = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { fcm_token } = req.body;

  if (!fcm_token) {
    res.status(400);
    throw new Error("fcm_token is required");
  }

  await removeDeviceService(userId, fcm_token);

  res.status(200).json({
    success: true,
    message: "Device removed successfully",
  });
});
