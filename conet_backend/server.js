import cors from "cors";
import "dotenv/config";
import express from "express";
import conversationRoutes from "./routes/conversationRoutes.js";
import postRoutes from "./routes/postRoutes.js";

const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/posts", postRoutes);
app.use("/api/conversations", conversationRoutes);

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
