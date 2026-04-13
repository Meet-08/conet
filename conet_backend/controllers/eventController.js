import asyncHandler from "express-async-handler";
import {
  addCohostService,
  attendEventService,
  cancelEventService,
  createEventService,
  exportEventParticipationXlsxService,
  getEventAttendeesService,
  getEventService,
  getRegistrationInfoService,
  listCohostsService,
  listMyEventsService,
  listMyOrganizedEventsService,
  listPublishedEventsService,
  publishEventService,
  registerEventService,
  registerParticipantForEventService,
  removeCohostService,
  saveEventService,
  updateEventService,
} from "../services/eventService.js";

// ─── Create event (draft or publish) ─────────────────────────────────────────

export const createEvent = asyncHandler(async (req, res) => {
  const event = await createEventService(req.user.id, req.body);
  res
    .status(201)
    .json({ success: true, message: "Event created successfully", event });
});

// ─── Update event ─────────────────────────────────────────────────────────────

export const updateEvent = asyncHandler(async (req, res) => {
  const event = await updateEventService(req.params.id, req.user.id, req.body);
  res
    .status(200)
    .json({ success: true, message: "Event updated successfully", event });
});

// ─── Publish event ────────────────────────────────────────────────────────────

export const publishEvent = asyncHandler(async (req, res) => {
  const event = await publishEventService(req.params.id, req.user.id);
  res
    .status(200)
    .json({ success: true, message: "Event published successfully", event });
});

// ─── Cancel event ─────────────────────────────────────────────────────────────

export const cancelEvent = asyncHandler(async (req, res) => {
  const event = await cancelEventService(req.params.id, req.user.id);
  res
    .status(200)
    .json({ success: true, message: "Event cancelled successfully", event });
});

// ─── Get single event ─────────────────────────────────────────────────────────

export const getEvent = asyncHandler(async (req, res) => {
  const event = await getEventService(req.params.id, req.user.id);
  res.status(200).json({ success: true, event });
});

export const registerEvent = asyncHandler(async (req, res) => {
  const payload =
    req.body != null && typeof req.body === "object" ?
      { ...req.body }
    : req.body;

  if (
    payload != null &&
    typeof payload === "object" &&
    payload.team_name !== undefined
  ) {
    if (typeof payload.team_name !== "string") {
      res.status(400);
      throw new Error("team_name must be a string");
    }

    payload.team_name = payload.team_name.trim();
  }

  const result = await registerEventService(
    req.params.id,
    req.user.id,
    payload,
  );
  res.status(200).json({
    success: true,
    message: "Event registered successfully",
    ...result,
  });
});

export const registerParticipant = asyncHandler(async (req, res) => {
  const payload =
    req.body != null && typeof req.body === "object" ?
      { ...req.body }
    : req.body;

  if (
    payload != null &&
    typeof payload === "object" &&
    payload.team_name !== undefined
  ) {
    if (typeof payload.team_name !== "string") {
      res.status(400);
      throw new Error("team_name must be a string");
    }

    payload.team_name = payload.team_name.trim();
  }

  const result = await registerParticipantForEventService(
    req.params.id,
    req.user.id,
    payload,
  );

  res.status(200).json({
    success: true,
    message: "Participant registered successfully",
    ...result,
  });
});

export const getRegistrationInfo = asyncHandler(async (req, res) => {
  const registration = await getRegistrationInfoService(
    req.params.id,
    req.user.id,
  );
  res.status(200).json({ success: true, registration });
});

export const getEventAttendees = asyncHandler(async (req, res) => {
  const result = await getEventAttendeesService(req.params.id, req.user.id, {
    status: req.query.status,
  });
  res.status(200).json({ success: true, ...result });
});

export const exportEventParticipationXlsx = asyncHandler(async (req, res) => {
  const { workbook, fileName } = await exportEventParticipationXlsxService(
    req.params.id,
    req.user.id,
  );

  res.setHeader(
    "Content-Type",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  );
  res.setHeader("Content-Disposition", `attachment; filename="${fileName}"`);

  await workbook.xlsx.write(res);
  res.end();
});

export const attendEvent = asyncHandler(async (req, res) => {
  const result = await attendEventService(req.params.id, req.user.id, req.body);
  res.status(200).json(result);
});

export const saveEvent = asyncHandler(async (req, res) => {
  const result = await saveEventService(req.params.id, req.user.id);
  res.status(200).json(result);
});

// ─── List published events ────────────────────────────────────────────────────

export const listPublishedEvents = asyncHandler(async (req, res) => {
  const { category, location_type, date_from, date_to, search, cursor } =
    req.query;
  const pageSizeInput = req.query.page_size;
  const rawPageSize = parseInt(pageSizeInput);
  if (pageSizeInput !== undefined && (isNaN(rawPageSize) || rawPageSize < 1)) {
    res.status(400);
    throw new Error("page_size must be a positive integer");
  }
  const page_size = Math.min(rawPageSize || 20, 100);

  const result = await listPublishedEventsService({
    viewerId: req.user.id,
    category,
    location_type,
    date_from,
    date_to,
    search,
    cursor: cursor || null,
    page_size,
  });

  res.status(200).json({ success: true, ...result });
});

// ─── List organizer's own events ──────────────────────────────────────────────

export const listMyOrganizedEvents = asyncHandler(async (req, res) => {
  const { cursor, status } = req.query;
  const pageSizeInput = req.query.page_size;
  const rawPageSize = parseInt(pageSizeInput);
  if (pageSizeInput !== undefined && (isNaN(rawPageSize) || rawPageSize < 1)) {
    res.status(400);
    throw new Error("page_size must be a positive integer");
  }
  const page_size = Math.min(rawPageSize || 20, 100);

  const result = await listMyOrganizedEventsService(req.user.id, {
    cursor: cursor || null,
    page_size,
    status,
  });

  res.status(200).json({ success: true, ...result });
});

// ─── List current user's events by selected type ────────────────────────────

export const listMyEvents = asyncHandler(async (req, res) => {
  const { cursor, type = "upcoming" } = req.query;
  const pageSizeInput = req.query.page_size;
  const rawPageSize = parseInt(pageSizeInput);

  if (pageSizeInput !== undefined && (isNaN(rawPageSize) || rawPageSize < 1)) {
    res.status(400);
    throw new Error("page_size must be a positive integer");
  }

  const page_size = Math.min(rawPageSize || 20, 100);
  const result = await listMyEventsService(req.user.id, {
    type,
    cursor: cursor || null,
    page_size,
  });

  res.status(200).json({ success: true, ...result });
});

// ─── Co-host management ───────────────────────────────────────────────────────

export const addCohost = asyncHandler(async (req, res) => {
  const { user_id } = req.body;

  if (!user_id) {
    res.status(400);
    throw new Error("user_id is required");
  }

  const cohost = await addCohostService(req.params.id, req.user.id, user_id);
  res
    .status(201)
    .json({ success: true, message: "Co-host added successfully", cohost });
});

export const removeCohost = asyncHandler(async (req, res) => {
  await removeCohostService(req.params.id, req.user.id, req.params.userId);
  res
    .status(200)
    .json({ success: true, message: "Co-host removed successfully" });
});

export const listCohosts = asyncHandler(async (req, res) => {
  const cohosts = await listCohostsService(req.params.id, req.user.id);
  res.status(200).json({ success: true, cohosts });
});
