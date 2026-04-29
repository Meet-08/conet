import { UUID_REGEX } from "../config/constants.js";
import {
  REPORT_REVIEW_STATUSES,
  REPORT_TARGET_TYPES,
} from "../services/reportService.js";

const isNonEmptyString = (value) =>
  typeof value === "string" && value.trim().length > 0;

export const validateCreateReport = (req, res, next) => {
  const { target_id, target_type, reason, description } = req.body ?? {};

  if (!isNonEmptyString(target_id) || !UUID_REGEX.test(target_id.trim())) {
    res.status(400);
    throw new Error("target_id must be a valid UUID");
  }

  if (
    !isNonEmptyString(target_type) ||
    !REPORT_TARGET_TYPES.includes(target_type.trim())
  ) {
    res.status(400);
    throw new Error("target_type is invalid");
  }

  if (!isNonEmptyString(reason)) {
    res.status(400);
    throw new Error("reason is required");
  }

  if (description != null && !isNonEmptyString(description)) {
    res.status(400);
    throw new Error("description must be a non-empty string when provided");
  }

  next();
};

export const validateReviewReport = (req, res, next) => {
  const { status } = req.body ?? {};

  if (!REPORT_REVIEW_STATUSES.includes(String(status ?? "").trim())) {
    res.status(400);
    throw new Error("status must be one of reviewed, resolved, or rejected");
  }

  next();
};
