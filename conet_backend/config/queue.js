import { Queue } from "bullmq";
import Redis from "ioredis";
import logger from "./logger.js";

// Parse Upstash Redis URL
const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
const url = new URL(redisUrl);

const redisOptions = {
  host: url.hostname,
  port: parseInt(url.port) || 6379,
  password: url.password || undefined,
  username: url.username || "default",
  tls: redisUrl.startsWith("rediss://") ? {} : undefined,
  maxRetriesPerRequest: null,
};

export const connection = new Redis(redisOptions);

connection.on("error", (error) => {
  logger.error("Redis connection error:", error);
});

connection.on("connect", () => {
  logger.info("Successfully connected to Redis");
});

export const notificationQueue = new Queue("notificationQueue", { connection });
