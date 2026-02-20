/**
 * Unit tests – errorhandler.js middleware
 *
 * Tests that every HTTP status code bucket returns the correct JSON shape.
 *
 *  ✓ 400 Validation Error
 *  ✓ 401 Unauthorized
 *  ✓ 403 Forbidden
 *  ✓ 404 Not Found
 *  ✓ 500 Server Error
 *  ✓ Unknown status → generic "Error" response (default case)
 *  ✓ err.statusCode used when res.statusCode is 200 (service-layer errors)
 *  ✓ stackTrace hidden in production, shown in development
 */

import { describe, expect, it } from "bun:test";
import errorHandler from "../../../middleware/errorhandler.js";

// ─── Helpers ───────────────────────────────────────────────────────────────

const makeErr = (
  message = "test error",
  stack = "Error: test\n  at test.js:1",
) => {
  const err = new Error(message);
  err.stack = stack;
  return err;
};

/**
 * Builds a mock req/res/next tuple and calls errorHandler.
 * `resStatusCode` simulates the res.statusCode that Express sets when
 * the controller explicitly calls res.status(N) before throwing.
 * `errStatusCode` simulates err.statusCode set by the service layer.
 */
const callHandler = (
  resStatusCode,
  err = makeErr(),
  errStatusCode = undefined,
) => {
  if (errStatusCode !== undefined) err.statusCode = errStatusCode;

  const req = {
    method: "GET",
    originalUrl: "/test",
  };

  let captured = null;
  let capturedStatus = null;

  const res = {
    statusCode: resStatusCode,
    json: (body) => {
      captured = body;
    },
    status: function (code) {
      capturedStatus = code;
      this.statusCode = code;
      return this;
    },
  };

  errorHandler(err, req, res, () => {});

  return { body: captured, status: capturedStatus };
};

// ─────────────────────────────────────────────────────────────────────────────
describe("errorHandler middleware", () => {
  it("returns Validation Failed body for 400 errors", () => {
    const { body, status } = callHandler(400, makeErr("Bad input"));

    expect(status).toBe(400);
    expect(body.title).toBe("Validation Failed");
    expect(body.message).toBe("Bad input");
  });

  it("returns Unauthorized body for 401 errors", () => {
    const { body, status } = callHandler(401, makeErr("Token expired"));

    expect(status).toBe(401);
    expect(body.title).toBe("Unauthorized");
    expect(body.message).toBe("Token expired");
  });

  it("returns Forbidden body for 403 errors", () => {
    const { body, status } = callHandler(403, makeErr("Access denied"));

    expect(status).toBe(403);
    expect(body.title).toBe("Forbidden");
    expect(body.message).toBe("Access denied");
  });

  it("returns Not Found body for 404 errors", () => {
    const { body, status } = callHandler(404, makeErr("Resource missing"));

    expect(status).toBe(404);
    expect(body.title).toBe("Not Found");
    expect(body.message).toBe("Resource missing");
  });

  it("returns Server Error body for 500 errors", () => {
    const { body, status } = callHandler(500, makeErr("Unhandled crash"));

    expect(status).toBe(500);
    expect(body.title).toBe("Server Error");
    expect(body.message).toBe("Unhandled crash");
  });

  it("falls through to default case for unknown status codes and still sends a response", () => {
    // Codes like 409 are not in the switch but now get a generic response
    const { body, status } = callHandler(409, makeErr("Conflict"));

    expect(status).toBe(409);
    expect(body.title).toBe("Error");
    expect(body.message).toBe("Conflict");
  });

  it("uses err.statusCode when res.statusCode is 200 (service-layer error pattern)", () => {
    // Simulates: service throws { statusCode: 404 } but controller never
    // called res.status() so res.statusCode is still 200.
    const { body, status } = callHandler(200, makeErr("User not found"), 404);

    expect(status).toBe(404);
    expect(body.title).toBe("Not Found");
    expect(body.message).toBe("User not found");
  });

  it("uses 500 as fallback when both res.statusCode is 200 and err has no statusCode", () => {
    const { body, status } = callHandler(200, makeErr("crash"));

    expect(status).toBe(500);
    expect(body.title).toBe("Server Error");
  });

  it("hides stackTrace in production, exposes it in development", () => {
    const originalEnv = process.env.NODE_ENV;

    process.env.NODE_ENV = "production";
    const { body: prodBody } = callHandler(
      500,
      makeErr("secret internal error"),
    );
    expect(prodBody.stackTrace).toBeUndefined();

    process.env.NODE_ENV = "development";
    const { body: devBody } = callHandler(500, makeErr("debug error"));
    expect(devBody.stackTrace).toBeDefined();

    process.env.NODE_ENV = originalEnv;
  });
});
