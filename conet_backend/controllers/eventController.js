import asyncHandler from "express-async-handler";
import {
  addCohostService,
  cancelEventService,
  createEventService,
  getEventService,
  listCohostsService,
  listMyOrganizedEventsService,
  listPublishedEventsService,
  publishEventService,
  removeCohostService,
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

// ─── List published events ────────────────────────────────────────────────────

export const listPublishedEvents = asyncHandler(async (req, res) => {
  const { category, location_type, date_from, date_to, search, cursor } =
    req.query;
  const rawLimit = parseInt(req.query.limit);
  if (req.query.limit !== undefined && (isNaN(rawLimit) || rawLimit < 1)) {
    res.status(400);
    throw new Error("limit must be a positive integer");
  }
  const limit = Math.min(rawLimit || 20, 100);

  const result = await listPublishedEventsService(
    {
      category,
      location_type,
      date_from,
      date_to,
      search,
      cursor: cursor || null,
      limit,
    },
    req.user.id,
  );

  res.status(200).json({ success: true, ...result });
});

// ─── List organizer's own events ──────────────────────────────────────────────

export const listMyOrganizedEvents = asyncHandler(async (req, res) => {
  const { cursor, status } = req.query;
  const rawLimit = parseInt(req.query.limit);
  if (req.query.limit !== undefined && (isNaN(rawLimit) || rawLimit < 1)) {
    res.status(400);
    throw new Error("limit must be a positive integer");
  }
  const limit = Math.min(rawLimit || 20, 100);

  const result = await listMyOrganizedEventsService(req.user.id, {
    cursor: cursor || null,
    limit,
    status,
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
