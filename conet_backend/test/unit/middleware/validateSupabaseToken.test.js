/**
 * Unit tests – validateSupabaseToken middleware
 *
 * Tests all token scenarios that the middleware must handle:
 *  ✓ Valid token  → req.user populated, next() called
 *  ✓ Expired token → 401
 *  ✓ Missing Authorization header → 401
 *  ✓ Bearer prefix missing → 401
 *  ✓ Malformed token (not valid JWT) → 401
 *  ✓ Wrong secret → 401
 *  ✓ req.user shape (id, email, role)
 *
 * We test the middleware directly (not via HTTP) to keep tests fast and
 * independent of Express routing behavior.
 */

import { beforeEach, describe, expect, it } from "bun:test";
import validateSupabaseToken from "../../../middleware/validateSupabaseToken.js";
import {
  makeExpiredAuthHeader,
  makeJwt,
  makeMalformedAuthHeader,
  TEST_JWT_SECRET,
  TEST_USER,
} from "../../mocks/authMock.js";

// ─── Helpers ───────────────────────────────────────────────────────────────

/** Builds a minimal mock req object. */
const makeReq = (authHeader) => ({
  headers: authHeader ? { authorization: authHeader } : {},
});

/** Builds a mock res object that can capture status codes. */
const makeRes = () => {
  const res = { _status: null };
  res.status = (code) => {
    res._status = code;
    return res;
  };
  return res;
};

/** Calls the middleware and returns { req, res, error, nextCalled }. */
const callMiddleware = async (authHeader) => {
  const req = makeReq(authHeader);
  const res = makeRes();

  let nextCalled = false;
  let nextError = null;

  const next = (err) => {
    nextCalled = true;
    nextError = err ?? null;
  };

  // validateSupabaseToken is async (uses async/await internally)
  try {
    await validateSupabaseToken(req, res, next);
  } catch (e) {
    // asyncHandler re-throws; in Express, errors are passed to next()
    // When testing middleware directly we catch them here
    nextError = e;
  }

  return { req, res, nextCalled, nextError };
};

// ─────────────────────────────────────────────────────────────────────────────
describe("validateSupabaseToken", () => {
  beforeEach(() => {
    process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
  });

  it("populates req.user and calls next() with a valid token", async () => {
    const token = makeJwt(TEST_USER);
    const { req, nextCalled, nextError } = await callMiddleware(
      `Bearer ${token}`,
    );

    expect(nextCalled).toBe(true);
    expect(nextError).toBeNull();
    expect(req.user).toBeDefined();
    expect(req.user.id).toBe(TEST_USER.id);
    expect(req.user.email).toBe(TEST_USER.email);
    expect(req.user.role).toBe(TEST_USER.role);
  });

  it("sets res.status(401) and throws for a missing Authorization header", async () => {
    const { res, nextError } = await callMiddleware(undefined);

    expect(res._status).toBe(401);
    expect(nextError?.message).toContain("Authorization token is required");
  });

  it("sets res.status(401) when 'Bearer ' prefix is absent", async () => {
    const token = makeJwt(TEST_USER);
    const { res, nextError } = await callMiddleware(token); // no 'Bearer ' prefix

    expect(res._status).toBe(401);
    expect(nextError?.message).toContain("Authorization token is required");
  });

  it("sets res.status(401) for an expired token", async () => {
    const { res, nextError } = await callMiddleware(makeExpiredAuthHeader());

    expect(res._status).toBe(401);
    expect(nextError?.message).toContain("Invalid or expired token");
  });

  it("sets res.status(401) for a malformed token", async () => {
    const { res, nextError } = await callMiddleware(makeMalformedAuthHeader());

    expect(res._status).toBe(401);
    expect(nextError?.message).toContain("Invalid or expired token");
  });

  it("sets res.status(401) when token is signed with a wrong secret", async () => {
    const badToken = makeJwt(TEST_USER);
    process.env.SUPABASE_JWT_SECRET = "wrong-secret";

    const { res, nextError } = await callMiddleware(`Bearer ${badToken}`);

    expect(res._status).toBe(401);
    expect(nextError?.message).toContain("Invalid or expired token");
  });

  it("res status 401 when Authorization header is 'Bearer ' with no token", async () => {
    const { res } = await callMiddleware("Bearer ");

    expect(res._status).toBe(401);
  });
});
