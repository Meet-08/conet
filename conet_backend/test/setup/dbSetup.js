/**
 * dbSetup.js – Test Database Lifecycle Helpers
 *
 * Manages a real PostgreSQL test database for integration/e2e tests.
 *
 * REQUIREMENTS:
 *  - TEST_DATABASE_URL set in .env.test pointing to an isolated test schema
 *    or a separate PostgreSQL database (NEVER production).
 *  - `prisma migrate deploy` must have been run against it before tests start.
 *
 * USAGE:
 *   import { dbSetup, dbTeardown, cleanDb } from "../setup/dbSetup.js";
 *
 *   beforeAll(dbSetup);
 *   afterAll(dbTeardown);
 *   beforeEach(cleanDb);
 *
 * DELETION ORDER matters – children before parents to avoid FK violations.
 * Prisma's $executeRawUnsafe with TRUNCATE ... CASCADE is used for speed.
 */

import { PrismaClient } from "@prisma/client";

let testPrisma;

export const dbSetup = async () => {
  if (!process.env.TEST_DATABASE_URL) {
    throw new Error(
      "TEST_DATABASE_URL is not set. " +
        "Create .env.test and point it to your test database. " +
        "Never run tests against the production database.",
    );
  }

  testPrisma = new PrismaClient({
    datasources: { db: { url: process.env.TEST_DATABASE_URL } },
  });

  await testPrisma.$connect();
};

export const dbTeardown = async () => {
  if (testPrisma) {
    await testPrisma.$disconnect();
  }
};

/**
 * Truncates all application tables in the correct FK-safe order.
 * Called in beforeEach to guarantee test isolation.
 *
 * Uses TRUNCATE ... RESTART IDENTITY CASCADE for full reset.
 */
export const cleanDb = async () => {
  if (!testPrisma) throw new Error("Call dbSetup() in beforeAll first.");

  // Order: leaf tables → parent tables
  const tables = [
    "post_likes",
    "post_comments",
    "messages",
    "user_follows",
    "user_academics",
    "posts",
    "conversations",
    "users",
  ];

  // PostgreSQL-specific fast truncation – safe because this is test-only
  await testPrisma.$executeRawUnsafe(
    `TRUNCATE TABLE ${tables.map((t) => `"public"."${t}"`).join(", ")} RESTART IDENTITY CASCADE`,
  );
};

/**
 * Returns the test Prisma client.
 * Use this in e2e tests that need to seed data directly.
 */
export const getTestPrisma = () => {
  if (!testPrisma) throw new Error("Call dbSetup() in beforeAll first.");
  return testPrisma;
};

/**
 * Seeds a minimal user suitable for test cases that need a real DB row.
 * Requires the auth.users row to exist (Supabase manages that table).
 * For unit/integration tests, prefer mocks instead of real DB rows.
 */
export const seedTestUser = async (override = {}) => {
  const client = getTestPrisma();
  return client.users.create({
    data: {
      id: override.id ?? "00000000-0000-0000-0000-000000000001",
      email: override.email ?? "seed@test.edu",
      username: override.username ?? "seeduser",
      first_name: override.first_name ?? "Seed",
      last_name: override.last_name ?? "User",
      ...override,
    },
  });
};
