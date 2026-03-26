import prisma from "../config/prisma.js";
import {
  assertEndAfterStart,
  assertEventExists,
  assertOrganizer,
  eventInclude,
  eventSummarySelect,
  mapEvent,
  mapEventSummary,
  parseTimeString,
  validateEventPayload,
} from "./utils.js";

const buildPublishedEventsCursor = (eventDate, id) =>
  Buffer.from(
    JSON.stringify({ eventDate: eventDate.toISOString(), id }),
  ).toString("base64");

const parsePublishedEventsCursor = (cursor) => {
  try {
    const decoded = JSON.parse(Buffer.from(cursor, "base64").toString("utf8"));
    if (!decoded?.eventDate || !decoded?.id) {
      return null;
    }
    const eventDate = new Date(decoded.eventDate);
    if (Number.isNaN(eventDate.getTime())) {
      return null;
    }
    return { eventDate, id: decoded.id };
  } catch {
    return null;
  }
};

const buildMyEventsCursor = (eventDate, id) =>
  Buffer.from(
    JSON.stringify({ eventDate: eventDate.toISOString(), id }),
  ).toString("base64");

const parseMyEventsCursor = (cursor) => {
  try {
    const decoded = JSON.parse(Buffer.from(cursor, "base64").toString("utf8"));
    if (!decoded?.eventDate || !decoded?.id) {
      return null;
    }
    const eventDate = new Date(decoded.eventDate);
    if (Number.isNaN(eventDate.getTime())) {
      return null;
    }
    return { eventDate, id: decoded.id };
  } catch {
    return null;
  }
};

const buildOrganizedEventsCursor = (createdAt, id) =>
  Buffer.from(
    JSON.stringify({ createdAt: createdAt.toISOString(), id }),
  ).toString("base64");

const parseOrganizedEventsCursor = (cursor) => {
  try {
    const decoded = JSON.parse(Buffer.from(cursor, "base64").toString("utf8"));
    if (!decoded?.createdAt || !decoded?.id) {
      return null;
    }
    const createdAt = new Date(decoded.createdAt);
    if (Number.isNaN(createdAt.getTime())) {
      return null;
    }
    return { createdAt, id: decoded.id };
  } catch {
    return null;
  }
};

// ─── Create event (draft or publish) ─────────────────────────────────────────

export const createEventService = async (organizerId, body) => {
  const {
    title,
    category,
    about,
    event_date,
    start_time,
    end_time,
    location_type,
    location,
    meeting_link,
    ticket_price_type = "FREE",
    price,
    max_participant = -1,
    eligibility,
    event_image_url,
    venue,
    registration_deadline,
    participation_type,
    min_team_size,
    max_team_size,
    publish = false,
    activity = [],
    prizes = [],
    faqs = [],
  } = body;

  if (
    !title ||
    !category ||
    !event_date ||
    !start_time ||
    !end_time ||
    !location_type
  ) {
    const err = new Error(
      "title, category, event_date, start_time, end_time, and location_type are required",
    );
    err.statusCode = 400;
    throw err;
  }

  validateEventPayload({
    location_type,
    location,
    meeting_link,
    ticket_price_type,
    price,
  });

  const parsedStartTime = parseTimeString(start_time, "start_time");
  const parsedEndTime = parseTimeString(end_time, "end_time");
  assertEndAfterStart(parsedStartTime, parsedEndTime);

  const event = await prisma.events.create({
    data: {
      organizer_id: organizerId,
      title,
      category,
      about,
      event_date: new Date(event_date),
      start_time: parsedStartTime,
      end_time: parsedEndTime,
      location_type,
      location,
      meeting_link,
      ticket_price_type,
      price: price ?? null,
      max_participant,
      event_status: publish ? "published" : "draft",
      eligibility,
      event_image_url,
      venue,
      registration_deadline:
        registration_deadline ? new Date(registration_deadline) : null,
      participation_type,
      min_team_size,
      max_team_size,
      event_activity:
        activity.length ?
          {
            create: activity.map(({ activity_time, activity_title }) => ({
              activity_time: new Date(activity_time),
              activity_title,
            })),
          }
        : undefined,
      event_prizes:
        prizes.length ?
          { create: prizes.map(({ position, prize }) => ({ position, prize })) }
        : undefined,
      event_faqs:
        faqs.length ?
          { create: faqs.map(({ question, answer }) => ({ question, answer })) }
        : undefined,
    },
    include: eventInclude(organizerId),
  });

  return mapEvent(event, organizerId);
};

// ─── Update event (organizer only) ───────────────────────────────────────────

export const updateEventService = async (eventId, organizerId, body) => {
  const existing = await assertEventExists(eventId);
  assertOrganizer(existing, organizerId);

  if (existing.event_status === "cancelled") {
    const err = new Error("Cannot update a cancelled event");
    err.statusCode = 409;
    throw err;
  }

  const {
    title,
    category,
    about,
    event_date,
    start_time,
    end_time,
    location_type,
    location,
    meeting_link,
    ticket_price_type,
    price,
    max_participant,
    eligibility,
    event_image_url,
    venue,
    registration_deadline,
    participation_type,
    min_team_size,
    max_team_size,
    activity,
    prizes,
    faqs,
  } = body;

  if (
    location_type !== undefined ||
    location !== undefined ||
    meeting_link !== undefined ||
    ticket_price_type !== undefined ||
    price !== undefined
  ) {
    validateEventPayload({
      location_type: location_type ?? existing.location_type,
      location: location ?? existing.location,
      meeting_link: meeting_link ?? existing.meeting_link,
      ticket_price_type: ticket_price_type ?? existing.ticket_price_type,
      price: price ?? existing.price,
    });
  }

  let parsedStartTime, parsedEndTime;
  if (start_time !== undefined) {
    parsedStartTime = parseTimeString(start_time, "start_time");
  }
  if (end_time !== undefined) {
    parsedEndTime = parseTimeString(end_time, "end_time");
  }
  if (start_time !== undefined || end_time !== undefined) {
    const effectiveStart = parsedStartTime ?? existing.start_time;
    const effectiveEnd = parsedEndTime ?? existing.end_time;
    assertEndAfterStart(effectiveStart, effectiveEnd);
  }

  const updateData = {
    ...(title !== undefined && { title }),
    ...(category !== undefined && { category }),
    ...(about !== undefined && { about }),
    ...(event_date !== undefined && { event_date: new Date(event_date) }),
    ...(start_time !== undefined && { start_time: parsedStartTime }),
    ...(end_time !== undefined && { end_time: parsedEndTime }),
    ...(location_type !== undefined && { location_type }),
    ...(location !== undefined && { location }),
    ...(meeting_link !== undefined && { meeting_link }),
    ...(ticket_price_type !== undefined && { ticket_price_type }),
    ...(price !== undefined && { price }),
    ...(max_participant !== undefined && { max_participant }),
    ...(eligibility !== undefined && { eligibility }),
    ...(event_image_url !== undefined && { event_image_url }),
    ...(venue !== undefined && { venue }),
    ...(registration_deadline !== undefined && {
      registration_deadline:
        registration_deadline ? new Date(registration_deadline) : null,
    }),
    ...(participation_type !== undefined && { participation_type }),
    ...(min_team_size !== undefined && { min_team_size }),
    ...(max_team_size !== undefined && { max_team_size }),
  };

  const updated = await prisma.$transaction(async (tx) => {
    if (activity !== undefined) {
      await tx.event_activity.deleteMany({ where: { event_id: eventId } });
      if (activity.length) {
        await tx.event_activity.createMany({
          data: activity.map(({ activity_time, activity_title }) => ({
            event_id: eventId,
            activity_time: new Date(activity_time),
            activity_title,
          })),
        });
      }
    }

    if (prizes !== undefined) {
      await tx.event_prizes.deleteMany({ where: { event_id: eventId } });
      if (prizes.length) {
        await tx.event_prizes.createMany({
          data: prizes.map(({ position, prize }) => ({
            event_id: eventId,
            position,
            prize,
          })),
        });
      }
    }

    if (faqs !== undefined) {
      await tx.event_faqs.deleteMany({ where: { event_id: eventId } });
      if (faqs.length) {
        await tx.event_faqs.createMany({
          data: faqs.map(({ question, answer }) => ({
            event_id: eventId,
            question,
            answer,
          })),
        });
      }
    }

    return tx.events.update({
      where: { id: eventId },
      data: updateData,
      include: eventInclude(organizerId),
    });
  });

  return mapEvent(updated, organizerId);
};

// ─── Publish event ────────────────────────────────────────────────────────────

export const publishEventService = async (eventId, organizerId) => {
  const existing = await assertEventExists(eventId);
  assertOrganizer(existing, organizerId);

  if (existing.event_status === "published") {
    const err = new Error("Event is already published");
    err.statusCode = 409;
    throw err;
  }
  if (existing.event_status === "cancelled") {
    const err = new Error("Cannot publish a cancelled event");
    err.statusCode = 409;
    throw err;
  }

  const event = await prisma.events.update({
    where: { id: eventId },
    data: { event_status: "published" },
    include: eventInclude(organizerId),
  });

  return mapEvent(event, organizerId);
};

// ─── Cancel event ─────────────────────────────────────────────────────────────

export const cancelEventService = async (eventId, organizerId) => {
  const existing = await assertEventExists(eventId);
  assertOrganizer(existing, organizerId);

  if (existing.event_status === "cancelled") {
    const err = new Error("Event is already cancelled");
    err.statusCode = 409;
    throw err;
  }

  const event = await prisma.events.update({
    where: { id: eventId },
    data: { event_status: "cancelled" },
    include: eventInclude(organizerId),
  });

  return mapEvent(event, organizerId);
};

// ─── Get single event ─────────────────────────────────────────────────────────

export const getEventService = async (eventId, viewerId) => {
  const event = await prisma.events.findUnique({
    where: { id: eventId },
    include: eventInclude(viewerId),
  });

  if (!event) {
    const err = new Error("Event not found");
    err.statusCode = 404;
    throw err;
  }

  // Non-organizers can only see published events
  if (event.event_status !== "published" && event.organizer_id !== viewerId) {
    const err = new Error("Event not found");
    err.statusCode = 404;
    throw err;
  }

  return mapEvent(event, viewerId);
};

export const registerEventService = async (eventId, userId) => {
  const event = await prisma.events.findUnique({ where: { id: eventId } });

  if (!event) {
    const err = new Error("Event not found");
    err.statusCode = 404;
    throw err;
  }

  if (event.event_status !== "published") {
    const err = new Error("Only published events can be registered");
    err.statusCode = 409;
    throw err;
  }

  if (event.organizer_id === userId) {
    const err = new Error("Organizer cannot register for their own event");
    err.statusCode = 400;
    throw err;
  }

  if (
    event.registration_deadline &&
    new Date(event.registration_deadline).getTime() < Date.now()
  ) {
    const err = new Error("Registration deadline has passed");
    err.statusCode = 409;
    throw err;
  }

  if (event.max_participant != null && event.max_participant > -1) {
    const registrationCount = await prisma.event_registrations.count({
      where: {
        event_id: eventId,
        registration_status: "registered",
      },
    });

    if (registrationCount >= event.max_participant) {
      const err = new Error("Event registration is full");
      err.statusCode = 409;
      throw err;
    }
  }

  await prisma.event_registrations.upsert({
    where: { event_id_user_id: { event_id: eventId, user_id: userId } },
    create: {
      event_id: eventId,
      user_id: userId,
      registration_status: "registered",
    },
    update: {
      registration_status: "registered",
      registered_at: new Date(),
    },
  });

  const updatedEvent = await prisma.events.findUnique({
    where: { id: eventId },
    include: eventInclude(userId),
  });

  return mapEvent(updatedEvent, userId);
};

// ─── List published events (cursor-paginated, filterable) ───────────────────

export const listPublishedEventsService = async ({
  category,
  location_type,
  date_from,
  date_to,
  search,
  cursor,
  page_size = 20,
}) => {
  const safePageSize = Math.min(
    100,
    Math.max(1, Math.floor(Number(page_size) || 20)),
  );

  const parsedCursor = cursor ? parsePublishedEventsCursor(cursor) : null;
  if (cursor && !parsedCursor) {
    const err = new Error("Invalid cursor format");
    err.statusCode = 400;
    throw err;
  }

  const where = {
    event_status: "published",
    ...(category && { category }),
    ...(location_type && { location_type }),
    ...(date_from || date_to ?
      {
        event_date: {
          ...(date_from && { gte: new Date(date_from) }),
          ...(date_to && { lte: new Date(date_to) }),
        },
      }
    : {}),
    ...(search && {
      OR: [
        { title: { contains: search, mode: "insensitive" } },
        { about: { contains: search, mode: "insensitive" } },
        { category: { contains: search, mode: "insensitive" } },
      ],
    }),
    ...(parsedCursor && {
      OR: [
        { event_date: { gt: parsedCursor.eventDate } },
        {
          event_date: parsedCursor.eventDate,
          id: { gt: parsedCursor.id },
        },
      ],
    }),
  };

  const rows = await prisma.events.findMany({
    where,
    take: safePageSize + 1,
    orderBy: [{ event_date: "asc" }, { id: "asc" }],
    select: eventSummarySelect,
  });

  const hasMore = rows.length > safePageSize;
  if (hasMore) rows.pop();
  const nextCursor =
    hasMore ?
      buildPublishedEventsCursor(
        rows[rows.length - 1].event_date,
        rows[rows.length - 1].id,
      )
    : null;

  return {
    events: rows.map(mapEventSummary),
    nextCursor,
    hasMore,
    pageSize: safePageSize,
  };
};

// ─── List organizer's own events (cursor-paginated) ─────────────────────────

export const listMyOrganizedEventsService = async (
  organizerId,
  { cursor, page_size = 20, status },
) => {
  const safePageSize = Math.min(
    100,
    Math.max(1, Math.floor(Number(page_size) || 20)),
  );

  const parsedCursor = cursor ? parseOrganizedEventsCursor(cursor) : null;
  if (cursor && !parsedCursor) {
    const err = new Error("Invalid cursor format");
    err.statusCode = 400;
    throw err;
  }

  const where = {
    organizer_id: organizerId,
    ...(status && { event_status: status }),
    ...(parsedCursor && {
      OR: [
        { created_at: { lt: parsedCursor.createdAt } },
        { created_at: parsedCursor.createdAt, id: { lt: parsedCursor.id } },
      ],
    }),
  };

  const rows = await prisma.events.findMany({
    where,
    take: safePageSize + 1,
    orderBy: [{ created_at: "desc" }, { id: "desc" }],
    select: eventSummarySelect,
  });

  const hasMore = rows.length > safePageSize;
  if (hasMore) rows.pop();
  const nextCursor =
    hasMore ?
      buildOrganizedEventsCursor(
        rows[rows.length - 1].created_at,
        rows[rows.length - 1].id,
      )
    : null;

  return {
    events: rows.map(mapEventSummary),
    nextCursor,
    hasMore,
    pageSize: safePageSize,
  };
};

// ─── List current user's events by chip type ────────────────────────────────

export const listMyEventsService = async (
  userId,
  { type = "upcoming", cursor, page_size = 20 },
) => {
  const allowedTypes = ["upcoming", "past", "saved"];
  if (!allowedTypes.includes(type)) {
    const err = new Error("type must be one of: upcoming, past, saved");
    err.statusCode = 400;
    throw err;
  }

  const safePageSize = Math.min(
    100,
    Math.max(1, Math.floor(Number(page_size) || 20)),
  );

  const parsedCursor = cursor ? parseMyEventsCursor(cursor) : null;
  if (cursor && !parsedCursor) {
    const err = new Error("Invalid cursor format");
    err.statusCode = 400;
    throw err;
  }

  const now = new Date();
  const today = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );

  const baseWhere = {
    event_status: "published",
    ...(type === "saved" ?
      {
        event_bookmarks: { some: { user_id: userId } },
      }
    : {
        OR: [
          { organizer_id: userId },
          {
            event_registrations: {
              some: { user_id: userId, registration_status: "registered" },
            },
          },
        ],
        ...(type === "upcoming" ?
          { event_date: { gte: today } }
        : { event_date: { lt: today } }),
      }),
  };

  const cursorWhere =
    !parsedCursor ? {}
    : type === "past" ?
      {
        OR: [
          { event_date: { lt: parsedCursor.eventDate } },
          {
            event_date: parsedCursor.eventDate,
            id: { lt: parsedCursor.id },
          },
        ],
      }
    : {
        OR: [
          { event_date: { gt: parsedCursor.eventDate } },
          {
            event_date: parsedCursor.eventDate,
            id: { gt: parsedCursor.id },
          },
        ],
      };

  const rows = await prisma.events.findMany({
    where: {
      ...baseWhere,
      ...cursorWhere,
    },
    take: safePageSize + 1,
    orderBy:
      type === "past" ?
        [{ event_date: "desc" }, { id: "desc" }]
      : [{ event_date: "asc" }, { id: "asc" }],
    select: eventSummarySelect,
  });

  const hasMore = rows.length > safePageSize;
  if (hasMore) rows.pop();

  const nextCursor =
    hasMore ?
      buildMyEventsCursor(
        rows[rows.length - 1].event_date,
        rows[rows.length - 1].id,
      )
    : null;

  return {
    type,
    events: rows.map(mapEventSummary),
    nextCursor,
    hasMore,
    pageSize: safePageSize,
  };
};

// ─── Co-host management ───────────────────────────────────────────────────────

export const addCohostService = async (eventId, organizerId, cohostUserId) => {
  const existing = await assertEventExists(eventId);
  assertOrganizer(existing, organizerId);

  if (cohostUserId === organizerId) {
    const err = new Error("Organizer cannot add themselves as a co-host");
    err.statusCode = 400;
    throw err;
  }

  // Verify the target user exists
  const targetUser = await prisma.users.findUnique({
    where: { id: cohostUserId },
  });
  if (!targetUser) {
    const err = new Error("User not found");
    err.statusCode = 404;
    throw err;
  }

  const cohost = await prisma.event_cohosts.upsert({
    where: { event_id_user_id: { event_id: eventId, user_id: cohostUserId } },
    create: { event_id: eventId, user_id: cohostUserId },
    update: {},
    include: {
      users: {
        select: {
          id: true,
          username: true,
          first_name: true,
          last_name: true,
          profile_pic_url: true,
        },
      },
    },
  });

  return mapCohost(cohost);
};

export const removeCohostService = async (
  eventId,
  organizerId,
  cohostUserId,
) => {
  const existing = await assertEventExists(eventId);
  assertOrganizer(existing, organizerId);

  const cohost = await prisma.event_cohosts.findUnique({
    where: { event_id_user_id: { event_id: eventId, user_id: cohostUserId } },
  });

  if (!cohost) {
    const err = new Error("Co-host not found for this event");
    err.statusCode = 404;
    throw err;
  }

  await prisma.event_cohosts.delete({
    where: { event_id_user_id: { event_id: eventId, user_id: cohostUserId } },
  });
};

export const listCohostsService = async (eventId, requesterId) => {
  const existing = await assertEventExists(eventId);

  // Non-organizer can only see cohosts of published events
  if (
    existing.event_status !== "published" &&
    existing.organizer_id !== requesterId
  ) {
    const err = new Error("Event not found");
    err.statusCode = 404;
    throw err;
  }

  const cohosts = await prisma.event_cohosts.findMany({
    where: { event_id: eventId },
    include: {
      users: {
        select: {
          id: true,
          username: true,
          first_name: true,
          last_name: true,
          profile_pic_url: true,
        },
      },
    },
  });

  return cohosts.map(mapCohost);
};
