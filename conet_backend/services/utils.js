import prisma from "../config/prisma.js";

export const EMPTY_QUILL_DELTA_JSON = '{"ops":[]}';

export const jsonFieldToString = (value, fallback = "") => {
  if (value == null) return fallback;
  if (typeof value === "string") return value;

  try {
    return JSON.stringify(value);
  } catch {
    return fallback;
  }
};

export const mapCohost = (c) => ({
  id: c.id,
  user_id: c.user_id,
  username: c.users?.username ?? "",
  profile_pic_url: c.users?.profile_pic_url ?? null,
  first_name: c.users?.first_name ?? null,
  last_name: c.users?.last_name ?? null,
});

export const mapEvent = (event, viewerId = null) => ({
  id: event.id,
  organizer_id: event.organizer_id,
  organizer: event.users ?? null,
  title: event.title,
  category: event.category,
  about: jsonFieldToString(event.about, EMPTY_QUILL_DELTA_JSON),
  start_date: event.start_date,
  end_date: event.end_date,
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
  venue: event.venue ?? null,
  registration_deadline: event.registration_deadline ?? null,
  participation_type: event.participation_type ?? null,
  min_team_size: event.min_team_size ?? null,
  max_team_size: event.max_team_size ?? null,
  conversation_id: event.conversation_id ?? null,
  custom_fields: Array.isArray(event.custom_fields) ? event.custom_fields : [],
  created_at: event.created_at,
  cohosts: event.event_cohosts?.map(mapCohost) ?? [],
  activity: event.event_activity ?? [],
  prizes: event.event_prizes ?? [],
  faqs: event.event_faqs ?? [],
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

export const mapEventSummary = (event) => ({
  id: event.id,
  event_image_url: event.event_image_url ?? null,
  title: event.title,
  category: event.category,
  ticket_price_type: event.ticket_price_type,
  price: event.price ? Number(event.price) : null,
  event_start_date: event.start_date,
  venue: event.venue ?? null,
  location: event.location ?? null,
  max_participant: event.max_participant ?? null,
  registration_count: event._count?.event_registrations ?? 0,
  is_bookmarked: (event.event_bookmarks?.length ?? 0) > 0,
});

export const eventSummarySelect = (viewerId = null) => ({
  event_image_url: true,
  title: true,
  category: true,
  ticket_price_type: true,
  price: true,
  start_date: true,
  venue: true,
  location: true,
  max_participant: true,
  _count: { select: { event_registrations: true } },
  id: true,
  created_at: true,
  ...(viewerId ?
    {
      event_bookmarks: {
        where: { user_id: viewerId },
        select: { user_id: true },
      },
    }
  : {}),
});

export const eventInclude = (viewerId = null) => ({
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
  event_faqs: { orderBy: { created_at: "asc" } },
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

export const assertEventExists = async (eventId) => {
  const event = await prisma.events.findUnique({ where: { id: eventId } });
  if (!event) {
    const err = new Error("Event not found");
    err.statusCode = 404;
    throw err;
  }
  return event;
};

export const assertOrganizer = (event, userId) => {
  if (event.organizer_id !== userId) {
    const err = new Error("Only the organizer can perform this action");
    err.statusCode = 403;
    throw err;
  }
};

export const assertAttendanceScanner = async (eventId, scannerUserId) => {
  const event = await assertEventExists(eventId);

  if (event.event_status !== "published") {
    const err = new Error("Only published events can accept attendance");
    err.statusCode = 409;
    throw err;
  }

  if (event.organizer_id === scannerUserId) {
    return event;
  }

  const cohost = await prisma.event_cohosts.findUnique({
    where: {
      event_id_user_id: {
        event_id: eventId,
        user_id: scannerUserId,
      },
    },
  });

  if (!cohost) {
    const err = new Error("Only organizer or co-host can scan tickets");
    err.statusCode = 403;
    throw err;
  }

  return event;
};

export const validateEventPayload = ({
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

const TIME_RE = /^\d{2}:\d{2}(:\d{2})?$/;

export const parseTimeString = (str, fieldName) => {
  if (!TIME_RE.test(str)) {
    const err = new Error(`${fieldName} must be in HH:MM or HH:MM:SS format`);
    err.statusCode = 400;
    throw err;
  }
  return new Date(`1970-01-01T${str}Z`);
};

export const assertEndAfterStart = (startDate, endDate) => {
  if (endDate.getTime() <= startDate.getTime()) {
    const err = new Error("end_time must be after start_time");
    err.statusCode = 400;
    throw err;
  }
};

