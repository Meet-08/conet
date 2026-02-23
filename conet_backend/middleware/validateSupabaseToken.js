import jwt from "jsonwebtoken";

export const validateSupabaseToken = async (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401);
    throw new Error("Authorization token is required");
  }

  const token = authHeader.split(" ")[1];

  try {
    // Supabase JWT secret from your project settings
    const decoded = jwt.verify(token, process.env.SUPABASE_JWT_SECRET);

    // Supabase tokens have 'sub' as the user ID
    req.user = {
      id: decoded.sub,
      email: decoded.email,
      role: decoded.role,
    };

    next();
  } catch (err) {
    res.status(401);
    throw new Error("Invalid or expired token");
  }
};

export default validateSupabaseToken;
