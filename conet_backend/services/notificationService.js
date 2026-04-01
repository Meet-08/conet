import logger from "../config/logger.js";
import prisma from "../config/prisma.js";
import { notificationQueue } from "../config/queue.js";

class NotificationService {
  /**
   * Creates a notification, increments unseen count, and queues a push job.
   * @param {Object} params
   * @param {string} params.receiverId
   * @param {string} [params.actorId]
   * @param {string} params.type
   * @param {string} [params.referenceId]
   * @param {string} [params.content]
   */
  async createNotification({
    receiverId,
    actorId,
    type,
    referenceId,
    content,
  }) {
    // Do not notify self-actions
    if (actorId && receiverId === actorId) {
      return null;
    }

    try {
      const notification = await prisma.notifications.create({
        data: {
          receiver_id: receiverId,
          actor_id: actorId,
          type,
          reference_id: referenceId,
          content,
        },
      });

      // NEW_MESSAGE relies on Supabase realtime and should not depend on Redis.
      if (type !== "NEW_MESSAGE") {
        try {
          await notificationQueue.add("sendPushNotification", {
            receiverId,
            title: this.getNotificationTitle(type),
            body: content || this.getNotificationBody(type),
            type,
            referenceId,
          });
        } catch (queueError) {
          logger.error("Failed to enqueue notification push job:", queueError);
        }
      }

      return notification;
    } catch (error) {
      logger.error("Error creating notification:", error);
      throw error;
    }
  }

  getNotificationTitle(type) {
    switch (type) {
      case "NEW_MESSAGE":
        return "New Message";
      case "POST_LIKE":
        return "New Like";
      case "POST_COMMENT":
        return "New Comment";
      default:
        return "New Notification";
    }
  }

  getNotificationBody(type) {
    switch (type) {
      case "NEW_MESSAGE":
        return "You have received a new message.";
      case "POST_LIKE":
        return "Someone liked your post.";
      case "POST_COMMENT":
        return "Someone commented on your post.";
      default:
        return "You have a new notification.";
    }
  }

  async markAsSeen(userId) {
    try {
      await prisma.notifications.updateMany({
        where: {
          receiver_id: userId,
          is_seen: false,
        },
        data: {
          is_seen: true,
        },
      });
    } catch (error) {
      logger.error("Error marking notifications as seen:", error);
      throw error;
    }
  }

  async getNotifications(userId, limit = 20, cursor = null) {
    try {
      const query = {
        where: { receiver_id: userId },
        orderBy: { created_at: "desc" },
        take: limit,
        include: {
          users_notifications_actor_idTousers: {
            select: {
              id: true,
              first_name: true,
              last_name: true,
              username: true,
              profile_pic_url: true,
            },
          },
        },
      };

      if (cursor) {
        query.cursor = { id: cursor };
        query.skip = 1; // Skip the cursor itself
      }

      const [notifications, user] = await Promise.all([
        prisma.notifications.findMany(query),
        prisma.users.findUnique({
          where: { id: userId },
          select: { unseen_notification_count: true },
        }),
      ]);

      return {
        notifications,
        unseenCount: user?.unseen_notification_count || 0,
      };
    } catch (error) {
      logger.error("Error fetching notifications:", error);
      throw error;
    }
  }
}

export default new NotificationService();
