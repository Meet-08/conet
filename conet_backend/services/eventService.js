import ExcelJS from "exceljs";
import prisma from "../config/prisma.js";
import {
  assertEndAfterStart,
  assertEventExists,
  assertOrganizer,
  eventInclude,
  eventSummarySelect,
  mapCohost,
  mapEvent,
  mapEventSummary,
  parseTimeString,
  validateEventPayload,
} from "./utils.js";

const XLSX_DATE_FORMAT = "dd/mm/yyyy";

const assertAttendanceScanner = async (eventId, scannerUserId) => {
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

const attendeeUserSelect = {
  id: true,
  username: true,
  first_name: true,
  last_name: true,
  profile_pic_url: true,
};

const mapAttendeeUser = (user) => ({
  id: user?.id ?? null,
  username: user?.username ?? null,
  first_name: user?.first_name ?? null,
  last_name: user?.last_name ?? null,
  profile_pic_url: user?.profile_pic_url ?? null,
});

const formatParticipantDisplayName = (member) => {
  const firstName = String(member?.users?.first_name ?? "").trim();
  const lastName = String(member?.users?.last_name ?? "").trim();
  const fullName = `${firstName} ${lastName}`.trim();

  if (fullName) return fullName;

  const username = String(member?.users?.username ?? "").trim();
  if (username) return username;

  return String(member?.user_id ?? "A participant");
};

const formatUserDisplayName = (user) => {
  const firstName = String(user?.first_name ?? "").trim();
  const lastName = String(user?.last_name ?? "").trim();
  const fullName = `${firstName} ${lastName}`.trim();
  if (fullName) return fullName;

  const username = String(user?.username ?? "").trim();
  if (username) return username;

  return "Unknown attendee";
};

const sanitizeXlsxFileName = (value) =>
  String(value ?? "participants")
    .trim()
    .replace(/[^a-zA-Z0-9-_ ]+/g, "")
    .replace(/\s+/g, "_")
    .slice(0, 60) || "participants";

const normalizeCellValue = (value) => {
  if (value === null || value === undefined) return "";
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  if (Array.isArray(value)) {
    return value
      .map((entry) => normalizeCellValue(entry))
      .filter(Boolean)
      .join(", ");
  }

  if (isPlainObject(value)) {
    return Object.entries(value)
      .map(([key, entry]) => `${key}: ${normalizeCellValue(entry)}`)
      .join("; ");
  }

  return String(value);
};

const normalizeAttendeeStatusFilter = (value) => {
  if (value === undefined || value === null) return null;

  const normalized = String(value).trim().toLowerCase();
  if (!normalized) return null;

  if (normalized === "all") return "all";

  const allowedStatuses = new Set(["registered", "attended", "cancelled"]);
  if (!allowedStatuses.has(normalized)) {
    const err = new Error(
      "status must be one of: registered, attended, cancelled, all",
    );
    err.statusCode = 400;
    throw err;
  }

  return normalized;
};

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

const isPlainObject = (value) =>
  value !== null && typeof value === "object" && !Array.isArray(value);

const normalizeParticipationType = (value) => {
  if (value === undefined) return undefined;

  const normalized = String(value).trim().toLowerCase();
  if (!normalized) return undefined;

  if (normalized !== "individual" && normalized !== "team") {
    const err = new Error(
      "participation_type must be either individual or team",
    );
    err.statusCode = 400;
    throw err;
  }

  return normalized;
};

const normalizeOptionalPositiveInteger = (value, fieldName) => {
  if (value === undefined) return undefined;
  if (value === null || value === "") return null;

  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1) {
    const err = new Error(`${fieldName} must be a positive integer`);
    err.statusCode = 400;
    throw err;
  }

  return parsed;
};

const normalizeOptionalString = (value, fieldName) => {
  if (value === undefined) return undefined;
  if (value === null) return null;

  if (typeof value !== "string") {
    const err = new Error(`${fieldName} must be a string`);
    err.statusCode = 400;
    throw err;
  }

  const trimmed = value.trim();
  return trimmed.length ? trimmed : null;
};

const normalizeOptionalStringArray = (value, fieldName) => {
  if (value === undefined) return undefined;
  if (value === null) return [];

  if (!Array.isArray(value)) {
    const err = new Error(`${fieldName} must be an array of strings`);
    err.statusCode = 400;
    throw err;
  }

  const normalized = [];

  for (let index = 0; index < value.length; index += 1) {
    const entry = value[index];
    if (typeof entry !== "string") {
      const err = new Error(`${fieldName}[${index}] must be a string`);
      err.statusCode = 400;
      throw err;
    }

    const trimmed = entry.trim();
    if (trimmed.length) {
      normalized.push(trimmed);
    }
  }

  return [...new Set(normalized)];
};

const validateTeamSizeConfig = ({
  participationType,
  minTeamSize,
  maxTeamSize,
}) => {
  if (
    minTeamSize != null &&
    maxTeamSize != null &&
    Number(minTeamSize) > Number(maxTeamSize)
  ) {
    const err = new Error("min_team_size cannot be greater than max_team_size");
    err.statusCode = 400;
    throw err;
  }

  if (participationType === "team" && maxTeamSize == null) {
    const err = new Error("max_team_size is required for team events");
    err.statusCode = 400;
    throw err;
  }
};

const normalizeCustomFieldDefinitions = (customFields) => {
  if (customFields === undefined) return undefined;
  if (customFields === null) return [];

  if (!Array.isArray(customFields)) {
    const err = new Error("custom_fields must be an array");
    err.statusCode = 400;
    throw err;
  }

  const seenKeys = new Set();

  return customFields.map((field, index) => {
    if (!isPlainObject(field)) {
      const err = new Error(`custom_fields[${index}] must be an object`);
      err.statusCode = 400;
      throw err;
    }

    const keyRaw =
      field.key ?? field.field_key ?? field.id ?? field.name ?? field.label;
    const key = String(keyRaw ?? "").trim();

    if (!key) {
      const err = new Error(
        `custom_fields[${index}] must have a non-empty key, id, name, or label`,
      );
      err.statusCode = 400;
      throw err;
    }

    if (seenKeys.has(key)) {
      const err = new Error(`Duplicate custom field key: ${key}`);
      err.statusCode = 400;
      throw err;
    }
    seenKeys.add(key);

    const label = String(field.label ?? field.name ?? field.title ?? key)
      .trim()
      .slice(0, 100);
    const rawType = String(field.type ?? field.field_type ?? "text")
      .trim()
      .toLowerCase();
    const type =
      (
        rawType === "single_select" ||
        rawType === "single-select" ||
        rawType === "singleselect" ||
        rawType === "dropdown"
      ) ?
        "select"
      : (
        rawType === "multiple_select" ||
        rawType === "multiple-select" ||
        rawType === "multiselect"
      ) ?
        "multi_select"
      : rawType === "image_url" || rawType === "image-url" ? "image"
      : rawType;
    const options =
      Array.isArray(field.options) ?
        field.options.map((option) => String(option).trim()).filter(Boolean)
      : undefined;
    const imageUrl = String(
      field.image_url ?? field.imageUrl ?? field.url ?? "",
    ).trim();

    if (type === "image" && !imageUrl) {
      const err = new Error(
        `custom_fields[${index}].image_url is required for image fields`,
      );
      err.statusCode = 400;
      throw err;
    }

    return {
      ...field,
      key,
      label: label || key,
      type: type || "text",
      required: type === "image" ? false : Boolean(field.required),
      ...(type === "image" ? { image_url: imageUrl } : {}),
      ...(type !== "image" && options ? { options } : {}),
    };
  });
};

const parseEventCustomFields = (customFields) => {
  if (Array.isArray(customFields)) return customFields;
  if (typeof customFields === "string") {
    try {
      const parsed = JSON.parse(customFields);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
};

const hasValue = (value) => {
  if (value === null || value === undefined) return false;
  if (typeof value === "string") return value.trim().length > 0;
  if (Array.isArray(value)) return value.length > 0;
  if (typeof value === "number" || typeof value === "boolean") return true;
  if (isPlainObject(value)) return Object.keys(value).length > 0;
  return true;
};

const getRequiredCustomFields = (customFields) => {
  const definitions = parseEventCustomFields(customFields);

  return definitions
    .filter(
      (field) =>
        isPlainObject(field) &&
        String(field.type ?? "")
          .trim()
          .toLowerCase() !== "image" &&
        Boolean(field.required),
    )
    .map((field) => {
      const key = String(
        field.key ?? field.field_key ?? field.id ?? field.name ?? field.label,
      ).trim();
      const label = String(field.label ?? field.name ?? key ?? "Field").trim();
      return { key, label: label || key || "Field" };
    })
    .filter((field) => field.key.length > 0);
};

const findCustomFieldResponseValue = (responses, field) => {
  if (!isPlainObject(responses)) return undefined;

  const candidates = [field.key, field.label].filter(Boolean);
  for (const candidate of candidates) {
    if (Object.hasOwn(responses, candidate)) {
      return responses[candidate];
    }
  }

  return undefined;
};

const normalizeCustomFieldResponseValue = (value) => {
  if (value === null || value === undefined) return undefined;

  if (typeof value === "string") {
    const trimmed = value.trim();
    return trimmed.length ? trimmed : undefined;
  }

  if (Array.isArray(value)) {
    const normalized = value
      .map((entry) => (typeof entry === "string" ? entry.trim() : entry))
      .filter((entry) => hasValue(entry));
    return normalized.length ? normalized : undefined;
  }

  if (isPlainObject(value)) {
    return Object.keys(value).length ? value : undefined;
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return value;
  }

  return undefined;
};

const getEventCustomFieldDescriptors = (customFields) => {
  const definitions = parseEventCustomFields(customFields);

  return definitions
    .filter(
      (field) =>
        isPlainObject(field) &&
        String(field.type ?? "")
          .trim()
          .toLowerCase() !== "image",
    )
    .map((field) => {
      const key = String(
        field.key ?? field.field_key ?? field.id ?? field.name ?? field.label,
      ).trim();
      const label = String(field.label ?? field.name ?? key).trim();
      return { key, label };
    })
    .filter((field) => field.key.length > 0);
};

const normalizeCustomFieldResponsesForEvent = (customFields, responses) => {
  const safeResponses = isPlainObject(responses) ? responses : {};
  const descriptors = getEventCustomFieldDescriptors(customFields);

  if (!descriptors.length) {
    if (Object.keys(safeResponses).length) {
      const err = new Error(
        "This event does not accept custom_field_responses",
      );
      err.statusCode = 400;
      throw err;
    }
    return {};
  }

  const allowedKeys = new Set();
  for (const descriptor of descriptors) {
    allowedKeys.add(descriptor.key);
    if (descriptor.label) {
      allowedKeys.add(descriptor.label);
    }
  }

  const unknownKeys = Object.keys(safeResponses).filter(
    (key) => !allowedKeys.has(key),
  );

  if (unknownKeys.length) {
    const err = new Error(
      `Unknown custom form fields in response: ${unknownKeys.join(", ")}`,
    );
    err.statusCode = 400;
    throw err;
  }

  const normalized = {};
  for (const descriptor of descriptors) {
    const rawValue = findCustomFieldResponseValue(safeResponses, descriptor);
    const value = normalizeCustomFieldResponseValue(rawValue);
    if (value !== undefined) {
      normalized[descriptor.key] = value;
    }
  }

  return normalized;
};

const parseActivityTimeValue = (value, fieldName) => {
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) {
      const err = new Error(`${fieldName} must be a valid date/time`);
      err.statusCode = 400;
      throw err;
    }
    return value;
  }

  if (typeof value !== "string") {
    const err = new Error(`${fieldName} must be a string date/time value`);
    err.statusCode = 400;
    throw err;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    const err = new Error(`${fieldName} is required`);
    err.statusCode = 400;
    throw err;
  }

  // Support HH:MM(:SS) payloads from app clients.
  if (/^\d{2}:\d{2}(:\d{2})?$/.test(trimmed)) {
    return parseTimeString(trimmed, fieldName);
  }

  const parsed = new Date(trimmed);
  if (Number.isNaN(parsed.getTime())) {
    const err = new Error(
      `${fieldName} must be a valid ISO date-time or HH:MM(:SS)`,
    );
    err.statusCode = 400;
    throw err;
  }

  return parsed;
};

const normalizeActivityEntries = (activity, fieldName = "activity") => {
  if (!Array.isArray(activity)) {
    const err = new Error(`${fieldName} must be an array`);
    err.statusCode = 400;
    throw err;
  }

  return activity.map((entry, index) => {
    if (!isPlainObject(entry)) {
      const err = new Error(`${fieldName}[${index}] must be an object`);
      err.statusCode = 400;
      throw err;
    }

    const title = String(entry.activity_title ?? "").trim();
    if (!title) {
      const err = new Error(
        `${fieldName}[${index}].activity_title is required`,
      );
      err.statusCode = 400;
      throw err;
    }

    return {
      activity_time: parseActivityTimeValue(
        entry.activity_time,
        `${fieldName}[${index}].activity_time`,
      ),
      activity_title: title,
    };
  });
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
    custom_fields,
    publish = false,
    activity = [],
    prizes = [],
    faqs = [],
  } = body;

  const hasConversationIdField =
    Object.prototype.hasOwnProperty.call(body, "conversation_id") ||
    Object.prototype.hasOwnProperty.call(body, "conversationId") ||
    Object.prototype.hasOwnProperty.call(body, "conversionId");
  const rawConversationId =
    hasConversationIdField ?
      (body.conversation_id ?? body.conversationId ?? body.conversionId ?? null)
    : undefined;

  if (
    !title ||
    !category ||
    !event_date ||
    !start_time ||
    !end_time ||
    !location_type ||
    !event_image_url
  ) {
    const err = new Error(
      "title, category, event_date, start_time, end_time, location_type, and event_image_url are required",
    );
    err.statusCode = 400;
    throw err;
  }

  const normalizedEventImageUrl = normalizeOptionalString(
    event_image_url,
    "event_image_url",
  );
  if (!normalizedEventImageUrl) {
    const err = new Error("event_image_url is required");
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

  const normalizedParticipationType =
    normalizeParticipationType(participation_type) ?? "individual";
  const normalizedMinTeamSize = normalizeOptionalPositiveInteger(
    min_team_size,
    "min_team_size",
  );
  const normalizedMaxTeamSize = normalizeOptionalPositiveInteger(
    max_team_size,
    "max_team_size",
  );
  validateTeamSizeConfig({
    participationType: normalizedParticipationType,
    minTeamSize: normalizedMinTeamSize,
    maxTeamSize: normalizedMaxTeamSize,
  });

  const normalizedCustomFields = normalizeCustomFieldDefinitions(custom_fields);
  const normalizedVenue = normalizeOptionalString(venue, "venue");
  const normalizedConversationId =
    hasConversationIdField ?
      normalizeOptionalString(rawConversationId, "conversation_id")
    : undefined;

  const resolvedMinTeamSize =
    normalizedParticipationType === "team" ?
      (normalizedMinTeamSize ?? null)
    : 1;
  const resolvedMaxTeamSize =
    normalizedParticipationType === "team" ? normalizedMaxTeamSize : 1;
  const normalizedActivities = normalizeActivityEntries(activity, "activity");

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
      event_image_url: normalizedEventImageUrl,
      venue: normalizedVenue,
      registration_deadline:
        registration_deadline ? new Date(registration_deadline) : null,
      participation_type: normalizedParticipationType,
      min_team_size: resolvedMinTeamSize,
      max_team_size: resolvedMaxTeamSize,
      upi_id: null,
      custom_fields: normalizedCustomFields ?? [],
      ...(normalizedConversationId !== undefined && {
        conversation_id: normalizedConversationId,
      }),
      event_activity:
        normalizedActivities.length ?
          {
            create: normalizedActivities.map(
              ({ activity_time, activity_title }) => ({
                activity_time,
                activity_title,
              }),
            ),
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
    custom_fields,
    activity,
    prizes,
    faqs,
  } = body;

  const hasConversationIdField =
    Object.prototype.hasOwnProperty.call(body, "conversation_id") ||
    Object.prototype.hasOwnProperty.call(body, "conversationId") ||
    Object.prototype.hasOwnProperty.call(body, "conversionId");
  const rawConversationId =
    hasConversationIdField ?
      (body.conversation_id ?? body.conversationId ?? body.conversionId ?? null)
    : undefined;

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

  const normalizedParticipationType =
    participation_type !== undefined ?
      normalizeParticipationType(participation_type)
    : undefined;
  const normalizedMinTeamSize =
    min_team_size !== undefined ?
      normalizeOptionalPositiveInteger(min_team_size, "min_team_size")
    : undefined;
  const normalizedMaxTeamSize =
    max_team_size !== undefined ?
      normalizeOptionalPositiveInteger(max_team_size, "max_team_size")
    : undefined;

  const effectiveParticipationType =
    normalizedParticipationType ??
    normalizeParticipationType(existing.participation_type) ??
    "individual";
  const effectiveMinTeamSize =
    normalizedMinTeamSize !== undefined ?
      normalizedMinTeamSize
    : existing.min_team_size;
  const effectiveMaxTeamSize =
    normalizedMaxTeamSize !== undefined ?
      normalizedMaxTeamSize
    : existing.max_team_size;

  validateTeamSizeConfig({
    participationType: effectiveParticipationType,
    minTeamSize: effectiveMinTeamSize,
    maxTeamSize: effectiveMaxTeamSize,
  });

  const normalizedCustomFields =
    custom_fields !== undefined ?
      normalizeCustomFieldDefinitions(custom_fields)
    : undefined;
  const normalizedVenue =
    venue !== undefined ? normalizeOptionalString(venue, "venue") : undefined;
  const normalizedConversationId =
    hasConversationIdField ?
      normalizeOptionalString(rawConversationId, "conversation_id")
    : undefined;
  const normalizedActivities =
    activity !== undefined ?
      normalizeActivityEntries(activity, "activity")
    : undefined;

  const resetTeamSizesForIndividual =
    normalizedParticipationType === "individual" &&
    min_team_size === undefined &&
    max_team_size === undefined;

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
    ...(normalizedVenue !== undefined && { venue: normalizedVenue }),
    ...(registration_deadline !== undefined && {
      registration_deadline:
        registration_deadline ? new Date(registration_deadline) : null,
    }),
    ...(normalizedParticipationType !== undefined && {
      participation_type: normalizedParticipationType,
    }),
    ...(normalizedMinTeamSize !== undefined && {
      min_team_size: normalizedMinTeamSize,
    }),
    ...(normalizedMaxTeamSize !== undefined && {
      max_team_size: normalizedMaxTeamSize,
    }),
    ...(resetTeamSizesForIndividual && {
      min_team_size: 1,
      max_team_size: 1,
    }),
    ...(normalizedCustomFields !== undefined && {
      custom_fields: normalizedCustomFields,
    }),
    ...(normalizedConversationId !== undefined && {
      conversation_id: normalizedConversationId,
    }),
  };

  const updated = await prisma.$transaction(async (tx) => {
    if (activity !== undefined) {
      await tx.event_activity.deleteMany({ where: { event_id: eventId } });
      if (normalizedActivities.length) {
        await tx.event_activity.createMany({
          data: normalizedActivities.map(
            ({ activity_time, activity_title }) => ({
              event_id: eventId,
              activity_time,
              activity_title,
            }),
          ),
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

export const registerEventService = async (eventId, userId, body = {}) => {
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

  if (body != null && !isPlainObject(body)) {
    const err = new Error("Registration payload must be an object");
    err.statusCode = 400;
    throw err;
  }

  const payload = body ?? {};
  const participationType =
    normalizeParticipationType(event.participation_type) ?? "individual";

  const teamId = normalizeOptionalString(payload.team_id, "team_id");
  const teamName = normalizeOptionalString(payload.team_name, "team_name");
  const transactionId = normalizeOptionalString(
    payload.transaction_id,
    "transaction_id",
  );
  const teamSize = normalizeOptionalPositiveInteger(
    payload.team_size,
    "team_size",
  );
  const memberUserIds = normalizeOptionalStringArray(
    payload.member_user_ids,
    "member_user_ids",
  );

  let customFieldResponses;
  if (payload.custom_field_responses !== undefined) {
    if (
      payload.custom_field_responses !== null &&
      !isPlainObject(payload.custom_field_responses)
    ) {
      const err = new Error("custom_field_responses must be an object");
      err.statusCode = 400;
      throw err;
    }

    customFieldResponses = payload.custom_field_responses ?? {};
  }

  if (participationType === "team") {
    if (!hasValue(teamName)) {
      const err = new Error("team_name is required for team events");
      err.statusCode = 400;
      throw err;
    }

    if (teamSize == null) {
      const err = new Error("team_size is required for team events");
      err.statusCode = 400;
      throw err;
    }

    if (event.min_team_size != null && teamSize < event.min_team_size) {
      const err = new Error(
        `team_size must be at least ${event.min_team_size} for this event`,
      );
      err.statusCode = 400;
      throw err;
    }

    if (event.max_team_size != null && teamSize > event.max_team_size) {
      const err = new Error(
        `team_size cannot exceed ${event.max_team_size} for this event`,
      );
      err.statusCode = 400;
      throw err;
    }

    const requiredAdditionalMembers = Math.max((teamSize ?? 1) - 1, 0);
    const selectedAdditionalMembers = memberUserIds ?? [];

    if (selectedAdditionalMembers.some((memberId) => memberId === userId)) {
      const err = new Error("member_user_ids must not include the captain");
      err.statusCode = 400;
      throw err;
    }

    if (selectedAdditionalMembers.length !== requiredAdditionalMembers) {
      const err = new Error(
        `Add exactly ${requiredAdditionalMembers} team members before registration`,
      );
      err.statusCode = 400;
      throw err;
    }
  }

  const normalizedCustomFieldResponses = normalizeCustomFieldResponsesForEvent(
    event.custom_fields,
    customFieldResponses ?? {},
  );

  const requiredCustomFields = getRequiredCustomFields(event.custom_fields);
  if (requiredCustomFields.length) {
    const missingRequiredFields = requiredCustomFields
      .filter((field) => !hasValue(normalizedCustomFieldResponses[field.key]))
      .map((field) => field.label || field.key);

    if (missingRequiredFields.length) {
      const err = new Error(
        `Required custom form fields are missing: ${missingRequiredFields.join(", ")}`,
      );
      err.statusCode = 400;
      throw err;
    }
  }

  let payment = null;
  if (event.ticket_price_type === "PAID") {
    const perMemberAmount = Number(event.price ?? 0);
    if (!Number.isFinite(perMemberAmount) || perMemberAmount <= 0) {
      const err = new Error("Invalid paid event price configuration");
      err.statusCode = 409;
      throw err;
    }

    const memberCount = participationType === "team" ? (teamSize ?? 1) : 1;
    const totalAmount = Number((perMemberAmount * memberCount).toFixed(2));

    payment = {
      currency: "INR",
      amount_per_member: perMemberAmount,
      member_count: memberCount,
      total_amount: totalAmount,
    };
  }

  let resolvedTeamId = teamId;
  let participantIdsForConversation = [userId];

  if (participationType === "team") {
    const requestedMemberIds = memberUserIds ?? [];
    const allTeamMemberIds = [userId, ...requestedMemberIds];

    const usersCount = await prisma.users.count({
      where: {
        id: { in: allTeamMemberIds },
      },
    });

    if (usersCount !== allTeamMemberIds.length) {
      const err = new Error("One or more team members are invalid");
      err.statusCode = 400;
      throw err;
    }

    if (resolvedTeamId) {
      const existingTeam = await prisma.event_teams.findUnique({
        where: { id: resolvedTeamId },
      });

      if (!existingTeam || existingTeam.event_id !== eventId) {
        const err = new Error("Invalid team_id for this event");
        err.statusCode = 400;
        throw err;
      }
    } else {
      const createdTeam = await prisma.event_teams.create({
        data: {
          event_id: eventId,
          leader_id: userId,
          team_name: teamName,
          metadata: {
            team_size: teamSize,
            member_user_ids: requestedMemberIds,
            source: "event_registration",
          },
        },
      });
      resolvedTeamId = createdTeam.id;
    }

    const conflictingMembers = await prisma.event_team_members.findMany({
      where: {
        event_id: eventId,
        user_id: { in: allTeamMemberIds },
        ...(resolvedTeamId ? { team_id: { not: resolvedTeamId } } : {}),
      },
      include: {
        users: {
          select: {
            username: true,
            first_name: true,
            last_name: true,
          },
        },
        event_teams: {
          select: {
            team_name: true,
          },
        },
      },
      orderBy: {
        joined_at: "asc",
      },
    });

    if (conflictingMembers.length > 0) {
      const conflictingMember = conflictingMembers[0];
      const participantName = formatParticipantDisplayName(conflictingMember);
      const existingTeamName =
        String(conflictingMember?.event_teams?.team_name ?? "").trim() ||
        "another team";

      const err = new Error(
        `${participantName} is already in team ${existingTeamName} for this event`,
      );
      err.statusCode = 409;
      throw err;
    }

    try {
      await prisma.event_team_members.createMany({
        data: allTeamMemberIds.map((memberId) => ({
          event_id: eventId,
          team_id: resolvedTeamId,
          user_id: memberId,
          role: memberId === userId ? "leader" : "member",
        })),
        skipDuplicates: true,
      });
    } catch (error) {
      if (error?.code === "P2002") {
        const err = new Error(
          "One or more participants are already in a team for this event",
        );
        err.statusCode = 409;
        throw err;
      }
      throw error;
    }

    participantIdsForConversation = [
      ...new Set(allTeamMemberIds.filter(Boolean)),
    ];
  }

  const registrationCreateData = {
    event_id: eventId,
    user_id: userId,
    registration_status: "registered",
    team_id: resolvedTeamId ?? null,
    transaction_id: transactionId ?? null,
    custom_field_responses: normalizedCustomFieldResponses,
  };

  const registrationUpdateData = {
    registration_status: "registered",
    registered_at: new Date(),
    ...(resolvedTeamId !== undefined && { team_id: resolvedTeamId }),
    ...(transactionId !== undefined && { transaction_id: transactionId }),
    ...(payload.custom_field_responses !== undefined ?
      { custom_field_responses: normalizedCustomFieldResponses }
    : {}),
  };

  let registrationRecord;
  try {
    registrationRecord = await prisma.event_registrations.upsert({
      where: { event_id_user_id: { event_id: eventId, user_id: userId } },
      create: registrationCreateData,
      update: registrationUpdateData,
    });
  } catch (error) {
    if (error?.code === "P2002") {
      const err = new Error("Registration already exists for this user");
      err.statusCode = 409;
      throw err;
    }
    throw error;
  }

  const linkedConversationId = String(event.conversation_id ?? "").trim();
  if (linkedConversationId) {
    const linkedConversation = await prisma.conversations.findUnique({
      where: { id: linkedConversationId },
      select: { id: true, type: true },
    });

    if (linkedConversation?.type === "group") {
      const uniqueParticipantIds = [
        ...new Set(participantIdsForConversation.filter(Boolean)),
      ];

      if (uniqueParticipantIds.length) {
        await prisma.conversation_members.createMany({
          data: uniqueParticipantIds.map((participantId) => ({
            conversation_id: linkedConversationId,
            user_id: participantId,
          })),
          skipDuplicates: true,
        });
      }
    }
  }

  const updatedEvent = await prisma.events.findUnique({
    where: { id: eventId },
    include: eventInclude(userId),
  });

  return {
    event: mapEvent(updatedEvent, userId),
    registration: {
      id: registrationRecord.id,
      registration_id: registrationRecord.id,
      ...(participationType === "team" ? { team_id: resolvedTeamId } : {}),
      team_size: participationType === "team" ? teamSize : 1,
      ...(payment ? { payment } : {}),
    },
  };
};

export const registerParticipantForEventService = async (
  eventId,
  requesterUserId,
  body = {},
) => {
  if (body != null && !isPlainObject(body)) {
    const err = new Error("Registration payload must be an object");
    err.statusCode = 400;
    throw err;
  }

  const payload = body ?? {};
  const participantUserId = normalizeOptionalString(
    payload.participant_user_id,
    "participant_user_id",
  );

  if (!hasValue(participantUserId)) {
    const err = new Error("participant_user_id is required");
    err.statusCode = 400;
    throw err;
  }

  await assertAttendanceScanner(eventId, requesterUserId);

  const registrationPayload = { ...payload };
  delete registrationPayload.participant_user_id;

  return registerEventService(eventId, participantUserId, registrationPayload);
};

export const getRegistrationInfoService = async (eventId, userId) => {
  const event = await prisma.events.findUnique({
    where: { id: eventId },
    select: {
      id: true,
      title: true,
      event_date: true,
      start_time: true,
      end_time: true,
      venue: true,
      location: true,
      event_status: true,
    },
  });

  if (!event) {
    const err = new Error("Event not found");
    err.statusCode = 404;
    throw err;
  }

  if (event.event_status !== "published") {
    const err = new Error("Ticket is only available for published events");
    err.statusCode = 409;
    throw err;
  }

  const registration = await prisma.event_registrations.findUnique({
    where: {
      event_id_user_id: {
        event_id: eventId,
        user_id: userId,
      },
    },
    include: {
      users: {
        select: {
          id: true,
          username: true,
          first_name: true,
          last_name: true,
        },
      },
    },
  });

  if (
    !registration ||
    registration.registration_status === "cancelled" ||
    !registration.registration_status
  ) {
    const err = new Error("You are not registered for this event");
    err.statusCode = 404;
    throw err;
  }

  return {
    event_id: event.id,
    user_id: registration.users.id,
    registration_id: registration.id,
  };
};

export const getEventAttendeesService = async (
  eventId,
  requesterUserId,
  { status } = {},
) => {
  const event = await assertAttendanceScanner(eventId, requesterUserId);
  const participationType =
    normalizeParticipationType(event.participation_type) ?? "individual";

  const statusFilter = normalizeAttendeeStatusFilter(status);
  const registrations = await prisma.event_registrations.findMany({
    where: {
      event_id: eventId,
      ...(statusFilter === "all" ? {}
      : statusFilter ? { registration_status: statusFilter }
      : {
          registration_status: {
            in: ["registered", "attended"],
          },
        }),
    },
    orderBy: [{ registered_at: "asc" }, { id: "asc" }],
    include: {
      users: {
        select: attendeeUserSelect,
      },
      event_teams: {
        include: {
          users: {
            select: attendeeUserSelect,
          },
          event_team_members: {
            orderBy: [{ joined_at: "asc" }, { id: "asc" }],
            include: {
              users: {
                select: attendeeUserSelect,
              },
            },
          },
        },
      },
    },
  });

  const statusCounts = registrations.reduce(
    (acc, registration) => {
      const currentStatus = registration.registration_status ?? "registered";
      if (currentStatus === "registered") acc.registered += 1;
      if (currentStatus === "attended") acc.attended += 1;
      if (currentStatus === "cancelled") acc.cancelled += 1;
      return acc;
    },
    { registered: 0, attended: 0, cancelled: 0 },
  );

  if (participationType === "team") {
    const teams = registrations.map((registration) => {
      const team = registration.event_teams;
      const members = (team?.event_team_members ?? []).map((member) => ({
        user_id: member.user_id,
        role: member.role,
        joined_at: member.joined_at,
        user: mapAttendeeUser(member.users),
      }));

      return {
        team_id: registration.team_id,
        team_name: team?.team_name ?? null,
        leader_user_id: team?.leader_id ?? registration.user_id,
        leader: mapAttendeeUser(team?.users ?? registration.users),
        registration_id: registration.id,
        registration_status: registration.registration_status,
        registered_at: registration.registered_at,
        member_count: members.length,
        members,
        custom_field_responses: registration.custom_field_responses ?? {},
      };
    });

    const totalMembers = teams.reduce(
      (sum, team) => sum + (team.member_count ?? 0),
      0,
    );

    return {
      event_id: event.id,
      participation_type: participationType,
      attendees: teams,
      summary: {
        total_teams: teams.length,
        total_members: totalMembers,
        registered: statusCounts.registered,
        attended: statusCounts.attended,
        cancelled: statusCounts.cancelled,
      },
    };
  }

  const attendees = registrations.map((registration) => ({
    registration_id: registration.id,
    user_id: registration.user_id,
    user: mapAttendeeUser(registration.users),
    registration_status: registration.registration_status,
    registered_at: registration.registered_at,
    custom_field_responses: registration.custom_field_responses ?? {},
  }));

  return {
    event_id: event.id,
    participation_type: participationType,
    attendees,
    summary: {
      total_attendees: attendees.length,
      registered: statusCounts.registered,
      attended: statusCounts.attended,
      cancelled: statusCounts.cancelled,
    },
  };
};

export const exportEventParticipationXlsxService = async (
  eventId,
  requesterUserId,
) => {
  const event = await assertAttendanceScanner(eventId, requesterUserId);
  const participationType =
    normalizeParticipationType(event.participation_type) ?? "individual";

  const registrations = await prisma.event_registrations.findMany({
    where: {
      event_id: eventId,
      registration_status: {
        in: ["registered", "attended", "cancelled"],
      },
    },
    orderBy: [{ registered_at: "asc" }, { id: "asc" }],
    include: {
      users: {
        select: attendeeUserSelect,
      },
      event_teams: {
        include: {
          users: {
            select: attendeeUserSelect,
          },
          event_team_members: {
            orderBy: [{ joined_at: "asc" }, { id: "asc" }],
            include: {
              users: {
                select: attendeeUserSelect,
              },
            },
          },
        },
      },
    },
  });

  const customFieldDescriptors = getEventCustomFieldDescriptors(
    event.custom_fields,
  );

  const workbook = new ExcelJS.Workbook();
  workbook.creator = "CoNet";
  workbook.created = new Date();

  const sheet = workbook.addWorksheet("Participants");
  const customFieldColumns = customFieldDescriptors.map(
    (descriptor, index) => ({
      header:
        descriptor.label?.trim().length ?
          descriptor.label.trim()
        : `Custom Field ${index + 1}`,
      key: `custom_response_${index + 1}`,
      width: 40,
    }),
  );

  if (participationType === "team") {
    const maxMemberCount = registrations.reduce((max, registration) => {
      const members = (
        registration.event_teams?.event_team_members ?? []
      ).filter((member) => member.role !== "leader");
      return Math.max(max, members.length);
    }, 0);

    const memberColumns = Array.from(
      { length: maxMemberCount },
      (_, index) => ({
        header: `Team Member ${index + 1}`,
        key: `team_member_${index + 1}`,
        width: 28,
      }),
    );

    sheet.columns = [
      { header: "Team Name", key: "team_name", width: 28 },
      { header: "Leader Name", key: "leader_name", width: 28 },
      { header: "Register Date", key: "register_date", width: 16 },
      ...memberColumns,
      ...customFieldColumns,
    ];

    for (const registration of registrations) {
      const team = registration.event_teams;
      const members = (team?.event_team_members ?? []).filter(
        (member) => member.role !== "leader",
      );
      const row = {
        team_name:
          String(team?.team_name ?? "").trim() ||
          `Team-${registration.team_id ?? registration.id}`,
        leader_name: formatUserDisplayName(team?.users ?? registration.users),
        register_date: registration.registered_at ?? null,
      };

      members.forEach((member, index) => {
        row[`team_member_${index + 1}`] = formatUserDisplayName(member.users);
      });

      customFieldDescriptors.forEach((descriptor, index) => {
        const rawValue = findCustomFieldResponseValue(
          registration.custom_field_responses,
          descriptor,
        );
        row[`custom_response_${index + 1}`] = normalizeCellValue(rawValue);
      });

      sheet.addRow(row);
    }
  } else {
    sheet.columns = [
      { header: "Name", key: "name", width: 28 },
      { header: "Register Date", key: "register_date", width: 16 },
      ...customFieldColumns,
    ];

    for (const registration of registrations) {
      const row = {
        name: formatUserDisplayName(registration.users),
        register_date: registration.registered_at ?? null,
      };

      customFieldDescriptors.forEach((descriptor, index) => {
        const rawValue = findCustomFieldResponseValue(
          registration.custom_field_responses,
          descriptor,
        );
        row[`custom_response_${index + 1}`] = normalizeCellValue(rawValue);
      });

      sheet.addRow(row);
    }
  }

  sheet.getColumn("register_date").numFmt = XLSX_DATE_FORMAT;

  sheet.getRow(1).font = { bold: true };

  const safeTitle = sanitizeXlsxFileName(event.title || "event_participants");
  const fileName = `${safeTitle}_participants.xlsx`;

  return { workbook, fileName };
};

export const attendEventService = async (eventId, scannerUserId, body = {}) => {
  await assertAttendanceScanner(eventId, scannerUserId);

  const { event_id, user_id, registration_id } = body;

  if (!event_id || !user_id || !registration_id) {
    const err = new Error("event_id, user_id and registration_id are required");
    err.statusCode = 400;
    throw err;
  }

  if (event_id !== eventId) {
    const err = new Error("event_id does not match route event id");
    err.statusCode = 400;
    throw err;
  }

  const registration = await prisma.event_registrations.findFirst({
    where: { id: registration_id, event_id: eventId, user_id },
  });

  if (!registration || registration.registration_status === "cancelled") {
    const err = new Error("Valid registration not found for this event");
    err.statusCode = 404;
    throw err;
  }

  const alreadyAttended = registration.registration_status === "attended";

  if (!alreadyAttended) {
    await prisma.event_registrations.update({
      where: { id: registration_id },
      data: {
        registration_status: "attended",
      },
    });

    return {
      success: true,
      message: "Attendance updated successfully",
    };
  }

  return {
    success: true,
    message: "User already marked as attended",
  };
};

export const saveEventService = async (eventId, userId) => {
  const event = await prisma.events.findUnique({ where: { id: eventId } });

  if (!event) {
    const err = new Error("Event not found");
    err.statusCode = 404;
    throw err;
  }

  if (event.event_status !== "published") {
    const err = new Error("Only published events can be saved");
    err.statusCode = 409;
    throw err;
  }

  const existingBookmark = await prisma.event_bookmarks.findUnique({
    where: {
      event_id_user_id: {
        event_id: eventId,
        user_id: userId,
      },
    },
  });

  if (existingBookmark) {
    await prisma.event_bookmarks.delete({
      where: {
        event_id_user_id: {
          event_id: eventId,
          user_id: userId,
        },
      },
    });

    return {
      success: true,
      message: "Event removed from saved",
    };
  }

  await prisma.event_bookmarks.create({
    data: {
      event_id: eventId,
      user_id: userId,
    },
  });

  return {
    success: true,
    message: "Event saved successfully",
  };
};

// ─── List published events (cursor-paginated, filterable) ───────────────────

export const listPublishedEventsService = async ({
  viewerId,
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
    select: eventSummarySelect(viewerId),
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
    events: rows.map((row) => mapEventSummary(row, viewerId)),
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
    ...(status && { event_status: status }),
    AND: [
      {
        OR: [
          { organizer_id: organizerId },
          { event_cohosts: { some: { user_id: organizerId } } },
        ],
      },
      ...(parsedCursor ?
        [
          {
            OR: [
              { created_at: { lt: parsedCursor.createdAt } },
              {
                created_at: parsedCursor.createdAt,
                id: { lt: parsedCursor.id },
              },
            ],
          },
        ]
      : []),
    ],
  };

  const rows = await prisma.events.findMany({
    where,
    take: safePageSize + 1,
    orderBy: [{ created_at: "desc" }, { id: "desc" }],
    select: eventSummarySelect(organizerId),
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
    events: rows.map((row) => mapEventSummary(row, organizerId)),
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
    select: eventSummarySelect(userId),
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
    events: rows.map((row) => mapEventSummary(row, userId)),
    nextCursor,
    hasMore,
    pageSize: safePageSize,
  };
};

// ─── Co-host management ───────────────────────────────────────────────────────

const getCohostManagerAccess = async (eventId, requesterId) => {
  const existing = await assertEventExists(eventId);

  if (requesterId === existing.organizer_id) {
    return { existing, isManager: true };
  }

  const requesterCohost = await prisma.event_cohosts.findUnique({
    where: {
      event_id_user_id: {
        event_id: eventId,
        user_id: requesterId,
      },
    },
  });

  if (requesterCohost?.role === "organizer") {
    return { existing, isManager: true };
  }

  return { existing, isManager: false };
};

export const addCohostService = async (eventId, organizerId, cohostUserId) => {
  const { existing, isManager } = await getCohostManagerAccess(
    eventId,
    organizerId,
  );

  if (!isManager) {
    const err = new Error(
      "Only the organizer or organizer-role co-host can perform this action",
    );
    err.statusCode = 403;
    throw err;
  }

  if (cohostUserId === organizerId) {
    const err = new Error("Requester cannot add themselves as a co-host");
    err.statusCode = 400;
    throw err;
  }

  if (cohostUserId === existing.organizer_id) {
    const err = new Error("Event organizer cannot be added as a co-host");
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
  const { isManager } = await getCohostManagerAccess(eventId, organizerId);

  if (!isManager) {
    const err = new Error(
      "Only the organizer or organizer-role co-host can perform this action",
    );
    err.statusCode = 403;
    throw err;
  }

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

export const promoteCohostService = async (
  eventId,
  requesterId,
  cohostUserId,
) => {
  const { existing, isManager } = await getCohostManagerAccess(
    eventId,
    requesterId,
  );

  if (!isManager) {
    const err = new Error(
      "Only the organizer or organizer-role co-host can perform this action",
    );
    err.statusCode = 403;
    throw err;
  }

  if (cohostUserId === existing.organizer_id) {
    const err = new Error("Organizer is already an organizer");
    err.statusCode = 400;
    throw err;
  }

  const cohost = await prisma.event_cohosts.findUnique({
    where: { event_id_user_id: { event_id: eventId, user_id: cohostUserId } },
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

  if (!cohost) {
    const err = new Error("Co-host not found for this event");
    err.statusCode = 404;
    throw err;
  }

  if (cohost.role === "organizer") {
    return mapCohost(cohost);
  }

  const updated = await prisma.event_cohosts.update({
    where: { event_id_user_id: { event_id: eventId, user_id: cohostUserId } },
    data: { role: "organizer" },
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

  return mapCohost(updated);
};

export const listCohostsService = async (eventId, requesterId) => {
  const { existing, isManager } = await getCohostManagerAccess(
    eventId,
    requesterId,
  );

  // Non-organizer can only see cohosts of published events
  if (!isManager && existing.event_status !== "published") {
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
