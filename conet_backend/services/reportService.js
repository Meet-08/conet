import { USER_SELECT_FIELDS } from "../config/constants.js";
import prisma from "../config/prisma.js";

export const REPORT_TARGET_TYPES = [
  "post",
  "comment",
  "conversation",
  "event",
  "user",
];

export const REPORT_REVIEW_STATUSES = ["reviewed", "resolved", "rejected"];

const REPORT_USER_SELECT = {
  ...USER_SELECT_FIELDS,
  user_role: true,
  is_verified: true,
};

const mapUser = (user) => {
  if (!user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    username: user.username,
    profile_pic_url: user.profile_pic_url,
    user_role: user.user_role,
    is_verified: user.is_verified ?? false,
  };
};

const mapReport = (report) => ({
  id: report.id,
  reporter_id: report.reporter_id,
  target_id: report.target_id,
  target_type: report.target_type,
  reason: report.reason,
  description: report.description,
  status: report.status ?? "pending",
  reviewed_by: report.reviewed_by,
  reviewed_at: report.reviewed_at,
  created_at: report.created_at,
  updated_at: report.updated_at,
  reporter: mapUser(report.users_reports_reporter_idTousers),
  reviewer: mapUser(report.users_reports_reviewed_byTousers),
});

const reportInclude = {
  users_reports_reporter_idTousers: {
    select: REPORT_USER_SELECT,
  },
  users_reports_reviewed_byTousers: {
    select: REPORT_USER_SELECT,
  },
};

const findCurrentUser = async (userId) => {
  const user = await prisma.users.findUnique({
    where: { id: userId },
    select: { id: true, user_role: true },
  });

  if (!user) {
    const err = new Error("User not found");
    err.statusCode = 404;
    throw err;
  }

  return user;
};

const ensureAdmin = async (userId) => {
  const user = await findCurrentUser(userId);

  if (user.user_role !== "admin") {
    const err = new Error("Not authorized to manage reports");
    err.statusCode = 403;
    throw err;
  }
};

const getPaginatedReports = async (where, page = 1, limit = 20) => {
  const skip = (page - 1) * limit;

  const [reports, total] = await prisma.$transaction([
    prisma.reports.findMany({
      where,
      skip,
      take: limit,
      orderBy: { created_at: "desc" },
      include: reportInclude,
    }),
    prisma.reports.count({ where }),
  ]);

  return {
    reports: reports.map(mapReport),
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
};

export const createReportService = async (
  userId,
  { target_id, target_type, reason, description },
) => {
  const existing = await prisma.reports.findUnique({
    where: {
      reporter_id_target_id_target_type: {
        reporter_id: userId,
        target_id,
        target_type,
      },
    },
  });

  if (existing) {
    const err = new Error("You have already reported this target");
    err.statusCode = 409;
    throw err;
  }

  const report = await prisma.reports.create({
    data: {
      reporter_id: userId,
      target_id,
      target_type,
      reason: reason?.trim() || null,
      description: description?.trim() || null,
    },
    include: reportInclude,
  });

  return mapReport(report);
};

export const getMyReportsService = async (
  userId,
  page = 1,
  limit = 20,
  status = null,
  targetType = null,
) => {
  const where = {
    reporter_id: userId,
    ...(status ? { status } : {}),
    ...(targetType ? { target_type: targetType } : {}),
  };

  return getPaginatedReports(where, page, limit);
};

export const getReportsService = async (
  userId,
  page = 1,
  limit = 20,
  status = null,
  targetType = null,
) => {
  await ensureAdmin(userId);

  const where = {
    ...(status ? { status } : {}),
    ...(targetType ? { target_type: targetType } : {}),
  };

  return getPaginatedReports(where, page, limit);
};

export const getReportService = async (reportId, userId) => {
  const report = await prisma.reports.findUnique({
    where: { id: reportId },
    include: reportInclude,
  });

  if (!report) {
    const err = new Error("Report not found");
    err.statusCode = 404;
    throw err;
  }

  if (report.reporter_id !== userId) {
    const currentUser = await findCurrentUser(userId);

    if (currentUser.user_role !== "admin") {
      const err = new Error("Not authorized to view this report");
      err.statusCode = 403;
      throw err;
    }
  }

  return mapReport(report);
};

export const reviewReportService = async (reportId, userId, { status }) => {
  await ensureAdmin(userId);

  const existing = await prisma.reports.findUnique({
    where: { id: reportId },
  });

  if (!existing) {
    const err = new Error("Report not found");
    err.statusCode = 404;
    throw err;
  }

  if (!REPORT_REVIEW_STATUSES.includes(status)) {
    const err = new Error("Invalid report review status");
    err.statusCode = 400;
    throw err;
  }

  const report = await prisma.reports.update({
    where: { id: reportId },
    data: {
      status,
      reviewed_by: userId,
      reviewed_at: new Date(),
      updated_at: new Date(),
    },
    include: reportInclude,
  });

  return mapReport(report);
};
