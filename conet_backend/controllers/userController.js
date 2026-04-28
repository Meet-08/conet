import asyncHandler from "express-async-handler";
import { searchUsersService } from "../services/userService.js";

// GET /api/users/search?query=...&limit=8
export const searchUsers = asyncHandler(async (req, res) => {
  const { query } = req.query;
  const parsedLimit = parseInt(req.query.limit, 10);
  const limit =
    Number.isNaN(parsedLimit) ? 3 : Math.min(Math.max(parsedLimit, 1), 50);
  const currentUserId = req.user.id;

  if (!query || !String(query).trim()) {
    res.status(400);
    throw new Error("query parameter is required");
  }

  const users = await searchUsersService(query, limit, currentUserId);

  res.status(200).json(users);
});
