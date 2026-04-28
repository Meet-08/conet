import { USER_SELECT_FIELDS } from "../config/constants.js";
import prisma from "../config/prisma.js";

const buildUserSearchConditions = (part) => [
  { first_name: { contains: part, mode: "insensitive" } },
  { last_name: { contains: part, mode: "insensitive" } },
  { username: { contains: part, mode: "insensitive" } },
  { email: { contains: part, mode: "insensitive" } },
];

export const searchUsersService = async (query, limit = 3, currentUserId) => {
  const normalizedQuery = String(query ?? "").trim();
  if (!normalizedQuery) {
    return [];
  }

  const queryParts = normalizedQuery
    .split(/\s+/)
    .map((part) => part.trim())
    .filter(Boolean);

  return prisma.users.findMany({
    where: {
      AND: [
        { id: { not: currentUserId } },
        ...(queryParts.length > 0 ? queryParts : [normalizedQuery]).map(
          (part) => ({
            OR: buildUserSearchConditions(part),
          }),
        ),
      ],
    },
    select: USER_SELECT_FIELDS,
    take: limit,
    orderBy: { username: "asc" },
  });
};
