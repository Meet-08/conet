/**
 * Auth / JWT Mock Utilities
 *
 * Provides:
 *  - makeJwt(payload)        – signs a valid test JWT
 *  - makeBearerHeader(jwt)   – returns the Authorization header string
 *  - bypassAuth(app)         – injects req.user without real JWT validation
 *  - TEST_USER / TEST_USER_B – canonical test user fixtures
 *
 * The SUPABASE_JWT_SECRET used here must match what validateSupabaseToken
 * reads from process.env.  Set it in .env.test.
 */

import jwt from "jsonwebtoken";

// ─── Canonical fixtures ────────────────────────────────────────────────────

export const TEST_USER = {
  id: "11111111-1111-1111-1111-111111111111",
  email: "alice@test.edu",
  username: "alice",
  role: "authenticated",
};

export const TEST_USER_B = {
  id: "22222222-2222-2222-2222-222222222222",
  email: "bob@test.edu",
  username: "bob",
  role: "authenticated",
};

export const TEST_JWT_SECRET = "test-secret-do-not-use-in-production";

// ─── JWT helpers ───────────────────────────────────────────────────────────

/**
 * Signs a Supabase-shaped JWT using the test secret.
 * @param {Partial<typeof TEST_USER>} payload
 * @param {import("jsonwebtoken").SignOptions} options
 */
export const makeJwt = (payload = TEST_USER, options = { expiresIn: "1h" }) => {
  return jwt.sign(
    {
      sub: payload.id,
      email: payload.email,
      role: payload.role ?? "authenticated",
      aud: "authenticated",
    },
    TEST_JWT_SECRET,
    options,
  );
};

/**
 * Returns the full Authorization header value for the given user.
 */
export const makeAuthHeader = (user = TEST_USER) => `Bearer ${makeJwt(user)}`;

/**
 * Returns an authorization header with an expired token.
 */
export const makeExpiredAuthHeader = (user = TEST_USER) =>
  `Bearer ${makeJwt(user, { expiresIn: "-1s" })}`;

/**
 * Returns a header with a structurally invalid (malformed) token.
 */
export const makeMalformedAuthHeader = () => "Bearer this.is.not.a.jwt";

/**
 * Middleware factory that bypasses JWT validation entirely.
 * Injects the given user into req.user.
 *
 * USE ONLY IN TESTS to isolate route/service logic from auth.
 */
export const makeAuthBypassMiddleware = (user = TEST_USER) => {
  return (_req, res, next) => {
    _req.user = user;
    next();
  };
};
