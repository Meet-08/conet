import prisma from "../config/prisma.js";

export const registerDeviceService = async (
  userId,
  fcmToken,
  platform,
  deviceName,
) => {
  // Upsert by fcm_token
  // If token exists -> update user_id, platform, device_name, is_active, updated_at
  // If not exists -> create new row
  const device = await prisma.user_devices.upsert({
    where: {
      fcm_token: fcmToken,
    },
    update: {
      user_id: userId,
      platform,
      device_name: deviceName,
      is_active: true,
      updated_at: new Date(),
    },
    create: {
      user_id: userId,
      fcm_token: fcmToken,
      platform,
      device_name: deviceName,
      is_active: true,
    },
  });

  return device;
};

export const removeDeviceService = async (userId, fcmToken) => {
  // Remove or deactivate device by token
  // We can just delete it to keep the table clean, or set is_active = false
  // Let's delete it for simplicity and to avoid stale tokens
  const device = await prisma.user_devices.deleteMany({
    where: {
      user_id: userId,
      fcm_token: fcmToken,
    },
  });

  return device;
};
