import prisma from "../config/prisma.js";

// ─── Shared mappers ──────────────────────────────────────────────────────────

const mapCohost = (c) => ({
  id: c.id,
  user_id: c.user_id,
  username: c.users?.username ?? null,
  profile_pic_url: c.users?.profile_pic_url ?? null,
  first_name: c.users?.first_name ?? null,
  last_name: c.users?.last_name ?? null,
});

const mapEvent = (event, viewerId = null) => ({
  id: event.id,
  organizer_id: event.organizer_id,
  organizer: event.users ?? null,
  title: event.title,
  category: event.category,
  about: event.about ?? null,
  event_date: event.event_date,
  start_time: event.start_time,
  end_time: event.end_time,
  location_type: event.location_type,
  location: event.location ?? null,
  meeting_link: event.meeting_link ?? null,
  ticket_price_type: event.ticket_price_type,
  price: event.price ? Number(event.price) : null,
  max_participant: event.max_participant,
  event_status: event.event_status,
  eligibility: event.eligibility ?? null,
  event_image_url: event.event_image_url ?? null,
  created_at: event.created_at,
  cohosts: event.event_cohosts?.map(mapCohost) ?? [],
  activity: event.event_activity ?? [],
  prizes: event.event_prizes ?? [],
  registration_count: event._count?.event_registrations ?? 0,
  is_registered:
    viewerId ?
      (event.event_registrations?.some((r) => r.user_id === viewerId) ?? false)
    : false,
  is_bookmarked:
    viewerId ?
      (event.event_bookmarks?.some((b) => b.user_id === viewerId) ?? false)
    : false,
});

const eventInclude = (viewerId = null) => ({
  users: {
    select: {
      id: true,
      username: true,
      first_name: true,
      last_name: true,
      profile_pic_url: true,
    },
  },
  event_cohosts: {
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
  },
  event_activity: { orderBy: { activity_time: "asc" } },
  event_prizes: true,
  _count: { select: { event_registrations: true } },
  ...(viewerId ?
    {
      event_registrations: {
        where: { user_id: viewerId, registration_status: "registered" },
        select: { user_id: true },
      },
      event_bookmarks: {
        where: { user_id: viewerId },
        select: { user_id: true },
      },
    }
  : {}),
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

const assertEventExists = async (eventId) => {
  const event = await prisma.events.findUnique({ where: { id: eventId } });
  if (!event) {
    const err = new Error("Event not found");
    err.statusCode = 404;
    throw err;
  }
  return event;
};

const assertOrganizer = (event, userId) => {
  if (event.organizer_id !== userId) {
    const err = new Error("Only the organizer can perform this action");
    err.statusCode = 403;
    throw err;
  }
};

const validateEventPayload = ({
  location_type,
  location,
  meeting_link,
  ticket_price_type,
  price,
}) => {
  if (location_type === "OFFLINE" && !location) {
    const err = new Error("location is required for offline events");
    err.statusCode = 400;
    throw err;
  }
  if (location_type === "ONLINE" && !meeting_link) {
    const err = new Error("meeting_link is required for online events");
    err.statusCode = 400;
    throw err;
  }
  if (ticket_price_type === "PAID" && (price == null || Number(price) <= 0)) {
    const err = new Error("price must be a positive number for paid events");
    err.statusCode = 400;
    throw err;
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
    publish = false,
    activity = [],
    prizes = [],
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

  const event = await prisma.events.create({
    data: {
      organizer_id: organizerId,
      title,
      category,
      about,
      event_date: new Date(event_date),
      start_time: new Date(`1970-01-01T${start_time}Z`),
      end_time: new Date(`1970-01-01T${end_time}Z`),
      location_type,
      location,
      meeting_link,
      ticket_price_type,
      price: price ?? null,
      max_participant,
      event_status: publish ? "published" : "draft",
      eligibility,
      event_image_url,
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
    activity,
    prizes,
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

  const updateData = {
    ...(title !== undefined && { title }),
    ...(category !== undefined && { category }),
    ...(about !== undefined && { about }),
    ...(event_date !== undefined && { event_date: new Date(event_date) }),
    ...(start_time !== undefined && {
      start_time: new Date(`1970-01-01T${start_time}Z`),
    }),
    ...(end_time !== undefined && {
      end_time: new Date(`1970-01-01T${end_time}Z`),
    }),
    ...(location_type !== undefined && { location_type }),
    ...(location !== undefined && { location }),
    ...(meeting_link !== undefined && { meeting_link }),
    ...(ticket_price_type !== undefined && { ticket_price_type }),
    ...(price !== undefined && { price }),
    ...(max_participant !== undefined && { max_participant }),
    ...(eligibility !== undefined && { eligibility }),
    ...(event_image_url !== undefined && { event_image_url }),
  };

  // All mutations run inside a single transaction — no partial state on failure
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

// ─── List published events (cursor-paginated, filterable) ───────────────────

export const listPublishedEventsService = async (
  { category, location_type, date_from, date_to, search, cursor, limit = 20 },
  viewerId,
) => {
  const safeLimit = Math.min(100, Math.max(1, Math.floor(Number(limit) || 20)));
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
  };

  const rows = await prisma.events.findMany({
    where,
    take: safeLimit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    orderBy: [{ event_date: "asc" }, { id: "asc" }],
    include: eventInclude(viewerId),
  });

  const hasMore = rows.length > safeLimit;
  if (hasMore) rows.pop();
  const nextCursor = hasMore ? rows[rows.length - 1].id : null;

  return {
    events: rows.map((e) => mapEvent(e, viewerId)),
    nextCursor,
    hasMore,
    limit: safeLimit,
  };
};

// ─── List organizer's own events (cursor-paginated) ─────────────────────────

export const listMyOrganizedEventsService = async (
  organizerId,
  { cursor, limit = 20, status },
) => {
  const safeLimit = Math.min(100, Math.max(1, Math.floor(Number(limit) || 20)));

  const where = {
    organizer_id: organizerId,
    ...(status && { event_status: status }),
  };

  const rows = await prisma.events.findMany({
    where,
    take: safeLimit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    orderBy: [{ created_at: "desc" }, { id: "desc" }],
    include: eventInclude(organizerId),
  });

  const hasMore = rows.length > safeLimit;
  if (hasMore) rows.pop();
  const nextCursor = hasMore ? rows[rows.length - 1].id : null;

  return {
    events: rows.map((e) => mapEvent(e, organizerId)),
    nextCursor,
    hasMore,
    limit: safeLimit,
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
