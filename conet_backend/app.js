import cors from "cors";
import express from "express";
import errorHandler from "./middleware/errorhandler.js";
import requestLogger from "./middleware/requestLogger.js";
import conversationRoutes from "./routes/conversationRoutes.js";
import deviceRoutes from "./routes/deviceRoutes.js";
import eventRoutes from "./routes/eventRoutes.js";
import groupRoutes from "./routes/groupRoutes.js";
import notificationRoutes from "./routes/notificationRoutes.js";
import paymentRoutes from "./routes/paymentRoutes.js";
import postRoutes from "./routes/postRoutes.js";
import profileRoutes from "./routes/profileRoutes.js";

/**
 * Factory function that creates and configures the Express app.
 * Keeping app creation separate from server startup enables clean testing.
 */
export function createApp() {
  const app = express();

  app.use(requestLogger);
  app.use(cors());
  app.use(
    express.json({
      verify: (req, _res, buffer) => {
        req.rawBody = buffer.toString();
      },
    }),
  );

  app.use("/api/posts", postRoutes);
  app.use("/api/conversations", conversationRoutes);
  app.use("/api/groups", groupRoutes);
  app.use("/api/profile", profileRoutes);
  app.use("/api/devices", deviceRoutes);
  app.use("/api/notifications", notificationRoutes);
  app.use("/api/events", eventRoutes);
  app.use("/api/payments", paymentRoutes);

  app.get("/health", (_req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  // Catch-all 404 – must be registered BEFORE errorHandler
  app.use((_req, res, next) => {
    res.status(404);
    next(new Error(`Route not found`));
  });

  app.use(errorHandler);

  return app;
}
