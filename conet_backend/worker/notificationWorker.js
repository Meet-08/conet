import { Worker } from "bullmq";
import "dotenv/config";
import admin from "firebase-admin";
import logger from "../config/logger.js";
import prisma from "../config/prisma.js";
import { connection } from "../config/queue.js";

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(
        JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT),
      ),
    });

    logger.info("Firebase Admin SDK initialized in worker");
  } catch (error) {
    logger.error("Failed to initialize Firebase Admin SDK in worker:", error);
  }
}

const processNotificationJob = async (job) => {
  const { receiverId, title, body, type, referenceId } = job.data;

  try {
    const activeDevices = await prisma.user_devices.findMany({
      where: {
        user_id: receiverId,
        is_active: true,
      },
      select: {
        id: true,
        fcm_token: true,
      },
    });

    if (activeDevices.length === 0) {
      logger.info(`No active devices found for user ${receiverId}`);
      return;
    }

    // 2. Prepare FCM messages
    const messages = activeDevices.map((device) => ({
      token: device.fcm_token,
      notification: {
        title,
        body,
      },
      data: {
        type,
        referenceId: referenceId || "",
      },
    }));

    // 3. Send FCM messages in parallel
    const sendPromises = messages.map((message) =>
      admin
        .messaging()
        .send(message)
        .catch((error) => ({ error, token: message.token })),
    );

    const results = await Promise.all(sendPromises);

    // 4. Handle invalid tokens
    const invalidTokens = [];
    results.forEach((result) => {
      if (result && result.error) {
        const errorCode = result.error.code;
        if (
          errorCode === "messaging/registration-token-not-registered" ||
          errorCode === "messaging/invalid-registration-token"
        ) {
          invalidTokens.push(result.token);
        } else {
          logger.error(
            `FCM send error for token ${result.token}:`,
            result.error,
          );
        }
      }
    });

    // 5. Deactivate invalid tokens
    if (invalidTokens.length > 0) {
      await prisma.user_devices.updateMany({
        where: {
          fcm_token: {
            in: invalidTokens,
          },
        },
        data: {
          is_active: false,
        },
      });
      logger.info(`Deactivated ${invalidTokens.length} invalid FCM tokens`);
    }

    logger.info(
      `Successfully processed notification job for user ${receiverId}`,
    );
  } catch (error) {
    logger.error(
      `Error processing notification job for user ${receiverId}:`,
      error,
    );
    throw error; // Re-throw to let BullMQ handle retries
  }
};

const worker = new Worker("notificationQueue", processNotificationJob, {
  connection,
  concurrency: 5, // Process up to 5 jobs concurrently
});

worker.on("error", (err) => {
  logger.error("Worker error:", err);
});

worker.on("completed", (job) => {
  logger.info(`Job ${job.id} has completed!`);
});

worker.on("failed", (job, err) => {
  logger.error(`Job ${job.id} has failed with ${err.message}`);
});

// Graceful shutdown
const shutdown = async () => {
  logger.info("Shutting down worker...");
  await worker.close();
  await connection.quit();
  await prisma.$disconnect();
  process.exit(0);
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

logger.info("Notification worker started");
