import { createRemoteJWKSet, jwtVerify } from "jose";
import jwt from "jsonwebtoken";

const jwksCache = new Map();

const buildSupabaseIssuer = (supabaseUrl) => {
  const normalizedUrl = supabaseUrl.replace(/\/$/, "");
  return process.env.SUPABASE_JWT_ISSUER?.trim() || `${normalizedUrl}/auth/v1`;
};

const buildSupabaseJwks = (supabaseUrl) => {
  const normalizedUrl = supabaseUrl.replace(/\/$/, "");
  const jwksUrl = `${normalizedUrl}/auth/v1/.well-known/jwks.json`;
  const issuer = buildSupabaseIssuer(supabaseUrl);
  const cacheKey = `${jwksUrl}|${issuer}`;

  if (!jwksCache.has(cacheKey)) {
    jwksCache.set(cacheKey, {
      jwks: createRemoteJWKSet(new URL(jwksUrl)),
      issuer,
    });
  }

  return jwksCache.get(cacheKey);
};

const verifySupabaseToken = async (token) => {
  const supabaseUrl = process.env.SUPABASE_URL?.trim();

  if (supabaseUrl) {
    try {
      const { jwks, issuer } = buildSupabaseJwks(supabaseUrl);
      const { payload } = await jwtVerify(token, jwks, { issuer });
      return payload;
    } catch (error) {
      if (!process.env.SUPABASE_JWT_SECRET) {
        throw error;
      }
    }
  }

  const legacySecret = process.env.SUPABASE_JWT_SECRET;

  if (!legacySecret) {
    throw new Error("Supabase JWT verification is not configured");
  }

  return jwt.verify(token, legacySecret);
};

export const validateSupabaseToken = async (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401);
    throw new Error("Authorization token is required");
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = await verifySupabaseToken(token);

    req.user = {
      id: decoded.sub,
      email: decoded.email,
      role: decoded.role || "authenticated",
    };

    next();
  } catch (err) {
    res.status(401);
    throw new Error("Invalid or expired token");
  }
};

export default validateSupabaseToken;
