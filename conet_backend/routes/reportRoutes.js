import express from "express";
import {
  createReport,
  getMyReports,
  getReport,
  getReports,
  reviewReport,
} from "../controllers/reportController.js";
import {
  validateCreateReport,
  validateReviewReport,
} from "../middleware/validateReport.js";
import validateSupabaseToken from "../middleware/validateSupabaseToken.js";

const router = express.Router();

router.use(validateSupabaseToken);

router.get("/mine", getMyReports);
router.get("/admin", getReports);
router.get("/:id", getReport);
router.post("/", validateCreateReport, createReport);
router.patch("/:id/review", validateReviewReport, reviewReport);

export default router;
