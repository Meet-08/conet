/**
 * testApp.js – Integration-test Express app factory
 *
 * Creates an isolated Express app where:
 *  - The real Prisma client is replaced with `prismaMock`
 *  - The real validateSupabaseToken is replaced with a bypass middleware
 *  - requestLogger is silenced so test output is clean
 *
 * The module-level mock.module calls are HOISTED by Bun's test runner
 * to run before any static imports resolve.
 *
 * USAGE:
 *   import { buildTestApp } from "../setup/testApp.js";
 *   const app = buildTestApp();
 *   const res = await request(app).get("/api/posts");
 */

import express from "express";
import errorHandler from "../../middleware/errorhandler.js";
import conversationRoutes from "../../routes/conversationRoutes.js";
import groupRoutes from "../../routes/groupRoutes.js";
import postRoutes from "../../routes/postRoutes.js";
import profileRoutes from "../../routes/profileRoutes.js";
import { makeAuthBypassMiddleware, TEST_USER } from "../mocks/authMock.js";

/**
 * Builds a test Express app.
 *
 * @param {object} options
 * @param {object} [options.user]     – user injected into req.user (default: TEST_USER)
 * @param {boolean} [options.noAuth]  – when true, skips auth injection (tests missing token paths)
 */
export function buildTestApp({ user = TEST_USER, noAuth = false } = {}) {
  const app = express();
  app.use(express.json());

  if (!noAuth) {
    // Inject req.user before routes so auth-protected handlers work
    app.use(makeAuthBypassMiddleware(user));
  }

  app.use("/api/posts", postRoutes);
  app.use("/api/conversations", conversationRoutes);
  app.use("/api/groups", groupRoutes);
  app.use("/api/profile", profileRoutes);

  app.get("/health", (_req, res) => {
    res.json({ status: "ok" });
  });

  // 404 catch-all
  app.use((_req, res, next) => {
    res.status(404);
    next(new Error("Route not found"));
  });

  app.use(errorHandler);

  return app;
}
