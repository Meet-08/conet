import asyncHandler from "express-async-handler";
import {
  createReportService,
  getMyReportsService,
  getReportService,
  getReportsService,
  reviewReportService,
} from "../services/reportService.js";

const parsePage = (value) => {
  const parsed = parseInt(value, 10);
  return Number.isNaN(parsed) || parsed < 1 ? 1 : parsed;
};

const parseLimit = (value) => {
  const parsed = parseInt(value, 10);
  if (Number.isNaN(parsed)) {
    return 20;
  }

  return Math.min(Math.max(parsed, 1), 50);
};

export const createReport = asyncHandler(async (req, res) => {
  const report = await createReportService(req.user.id, req.body);

  res.status(201).json({
    success: true,
    message: "Report submitted successfully",
    report,
  });
});

export const getMyReports = asyncHandler(async (req, res) => {
  const page = parsePage(req.query.page);
  const limit = parseLimit(req.query.limit);
  const { status, target_type } = req.query;

  const result = await getMyReportsService(
    req.user.id,
    page,
    limit,
    status?.trim() || null,
    target_type?.trim() || null,
  );

  res.status(200).json({ success: true, ...result });
});

export const getReports = asyncHandler(async (req, res) => {
  const page = parsePage(req.query.page);
  const limit = parseLimit(req.query.limit);
  const { status, target_type } = req.query;

  const result = await getReportsService(
    req.user.id,
    page,
    limit,
    status?.trim() || null,
    target_type?.trim() || null,
  );

  res.status(200).json({ success: true, ...result });
});

export const getReport = asyncHandler(async (req, res) => {
  const report = await getReportService(req.params.id, req.user.id);

  res.status(200).json({ success: true, report });
});

export const reviewReport = asyncHandler(async (req, res) => {
  const report = await reviewReportService(req.params.id, req.user.id, {
    status: req.body.status,
  });

  res.status(200).json({
    success: true,
    message: "Report updated successfully",
    report,
  });
});
