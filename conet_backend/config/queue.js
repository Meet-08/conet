import { Queue } from "bullmq";
import Redis from "ioredis";
import logger from "./logger.js";

const isTest = process.env.NODE_ENV === "test";
const redisEnabledInTests = process.env.ENABLE_REDIS_IN_TESTS === "true";
const shouldDisableRedis = isTest && !redisEnabledInTests;

let connection = null;
let queue = null;

if (!shouldDisableRedis) {
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

  connection = new Redis(redisOptions);

  connection.on("error", (error) => {
    logger.error("Redis connection error:", error);
  });

  connection.on("connect", () => {
    logger.info("Successfully connected to Redis");
  });

  queue = new Queue("notificationQueue", { connection });
} else {
  logger.info("Redis queue is disabled in test environment");
}

export { connection };

export const notificationQueue = {
  async add(...args) {
    if (!queue) {
      return null;
    }
    return queue.add(...args);
  },
};
