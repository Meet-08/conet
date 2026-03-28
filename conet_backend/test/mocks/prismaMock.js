/**
 * Prisma Mock
 *
 * Provides a fully-typed mock of every model and operation used across
 * the codebase.  Each method is a `mock()` from bun:test so tests can:
 *   - Override return values per test:  prismaMock.users.findUnique.mockResolvedValue(...)
 *   - Assert calls:                     expect(prismaMock.users.update).toHaveBeenCalledWith(...)
 *   - Reset state:                      resetPrismaMocks()
 *
 * USAGE IN TEST FILE:
 *   import { mock } from "bun:test";
 *   import { prismaMock, resetPrismaMocks } from "../mocks/prismaMock.js";
 *
 *   mock.module("../../config/prisma.js", () => ({ default: prismaMock }));
 *
 *   // Then import the module under test so it receives the mock:
 *   const { getUserProfileService } = await import("../../services/profileService.js");
 */

import { mock } from "bun:test";

const makeMethods = () => ({
  findUnique: mock(() => Promise.resolve(null)),
  findFirst: mock(() => Promise.resolve(null)),
  findMany: mock(() => Promise.resolve([])),
  create: mock(() => Promise.resolve({})),
  createMany: mock(() => Promise.resolve({ count: 0 })),
  update: mock(() => Promise.resolve({})),
  upsert: mock(() => Promise.resolve({})),
  delete: mock(() => Promise.resolve({})),
  deleteMany: mock(() => Promise.resolve({ count: 0 })),
  updateMany: mock(() => Promise.resolve({ count: 0 })),
  groupBy: mock(() => Promise.resolve([])),
  count: mock(() => Promise.resolve(0)),
});

export const prismaMock = {
  users: makeMethods(),
  user_follows: makeMethods(),
  user_academics: makeMethods(),
  posts: makeMethods(),
  post_likes: makeMethods(),
  post_comments: makeMethods(),
  events: makeMethods(),
  event_activity: makeMethods(),
  event_prizes: makeMethods(),
  event_faqs: makeMethods(),
  event_cohosts: makeMethods(),
  event_registrations: makeMethods(),
  event_bookmarks: makeMethods(),
  conversations: makeMethods(),
  conversation_members: makeMethods(),
  messages: makeMethods(),
  notifications: makeMethods(),
  $transaction: mock((fn) =>
    typeof fn === "function" ? fn(prismaMock) : Promise.all(fn),
  ),
  $disconnect: mock(() => Promise.resolve()),
};

/**
 * Resets all mock implementations and call history.
 * Call this in `beforeEach` to prevent state leaking between tests.
 */
export const resetPrismaMocks = () => {
  for (const model of Object.values(prismaMock)) {
    if (typeof model === "object" && model !== null) {
      for (const method of Object.values(model)) {
        if (typeof method?.mockReset === "function") {
          method.mockReset();
          // Restore safe defaults after reset
          if (
            method._name?.includes("findUnique") ||
            method._name?.includes("findFirst")
          ) {
            method.mockResolvedValue(null);
          } else if (
            method._name?.includes("findMany") ||
            method._name?.includes("groupBy")
          ) {
            method.mockResolvedValue([]);
          } else if (
            method._name?.includes("createMany") ||
            method._name?.includes("deleteMany") ||
            method._name?.includes("updateMany")
          ) {
            method.mockResolvedValue({ count: 0 });
          } else {
            method.mockResolvedValue({});
          }
        }
      }
    }
  }
};
