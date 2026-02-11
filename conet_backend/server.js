import cors from "cors";
import "dotenv/config";
import express from "express";
import errorHandler from "./middleware/errorhandler.js";
import requestLogger from "./middleware/requestLogger.js";
import conversationRoutes from "./routes/conversationRoutes.js";
import postRoutes from "./routes/postRoutes.js";
import profileRoutes from "./routes/profileRoutes.js";

const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(requestLogger); // Log requests first
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/posts", postRoutes);
app.use("/api/conversations", conversationRoutes);
app.use("/api/profile", profileRoutes);

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Error Handler
app.use(errorHandler);

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
