import { Queue } from "bullmq";
import Redis from "ioredis";
import logger from "./logger.js";

const redisOptions = {
  host: process.env.REDIS_HOST || "127.0.0.1",
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
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
