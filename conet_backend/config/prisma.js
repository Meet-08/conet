import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient({
  log: ["warn", "error"],
});

export const warmUpDatabase = async (retries = 3, delay = 1000) => {
  for (let i = 0; i < retries; i++) {
    try {
      await prisma.$queryRaw`SELECT 1`;
      console.log("Database connection established and warmed up.");
      return true;
    } catch (error) {
      console.error(`Database warm-up attempt ${i + 1} failed:`, error.message);
      if (i < retries - 1) {
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }
  console.warn(
    "Database warm-up failed after multiple attempts. Server might experience initial request lag.",
  );
  return false;
};

export default prisma;
