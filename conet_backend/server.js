import "dotenv/config";
import { createApp } from "./app.js";
import { warmUpDatabase } from "./config/prisma.js";

const startServer = async () => {
  const app = createApp();
  const port = process.env.PORT || 5000;

  await warmUpDatabase();

  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
};

startServer();
