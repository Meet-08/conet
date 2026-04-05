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
    const err = new Error("participation_type must be either individual or team");
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
    const type = String(field.type ?? field.field_type ?? "text")
      .trim()
      .toLowerCase();
    const options =
      Array.isArray(field.options) ?
        field.options.map((option) => String(option).trim()).filter(Boolean)
      : undefined;

    return {
      ...field,
      key,
      label: label || key,
      type: type || "text",
      required: Boolean(field.required),
      ...(options ? { options } : {}),
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
    .filter((field) => isPlainObject(field) && Boolean(field.required))
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
    upi_id,
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
  const normalizedUpiId = normalizeOptionalString(upi_id, "upi_id");
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
      participation_type: normalizedParticipationType,
      min_team_size: resolvedMinTeamSize,
      max_team_size: resolvedMaxTeamSize,
      upi_id: normalizedUpiId ?? null,
      custom_fields: normalizedCustomFields ?? [],
      ...(normalizedConversationId !== undefined && {
        conversation_id: normalizedConversationId,
      }),
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
    upi_id,
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
  const normalizedUpiId =
    upi_id !== undefined ? normalizeOptionalString(upi_id, "upi_id") : undefined;
  const normalizedConversationId =
    hasConversationIdField ?
      normalizeOptionalString(rawConversationId, "conversation_id")
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
    ...(venue !== undefined && { venue }),
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
    ...(normalizedUpiId !== undefined && { upi_id: normalizedUpiId }),
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

  if (body != null && !isPlainObject(body)) {
    const err = new Error("Registration payload must be an object");
    err.statusCode = 400;
    throw err;
  }

  const payload = body ?? {};
  const participationType =
    normalizeParticipationType(event.participation_type) ?? "individual";

  const teamId = normalizeOptionalString(payload.team_id, "team_id");
  const enrollmentNumber = normalizeOptionalString(
    payload.enrollment_number,
    "enrollment_number",
  );
  const contactNumber = normalizeOptionalString(
    payload.contact_number,
    "contact_number",
  );
  const semester = normalizeOptionalPositiveInteger(payload.semester, "semester");
  const branch = normalizeOptionalString(payload.branch, "branch");
  const paymentProofUrl = normalizeOptionalString(
    payload.payment_proof_url,
    "payment_proof_url",
  );
  const transactionId = normalizeOptionalString(
    payload.transaction_id,
    "transaction_id",
  );
  const teamSize = normalizeOptionalPositiveInteger(payload.team_size, "team_size");

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

    const missingTeamFields = [];
    if (!hasValue(enrollmentNumber)) missingTeamFields.push("enrollment_number");
    if (!hasValue(branch)) missingTeamFields.push("branch");

    if (missingTeamFields.length) {
      const err = new Error(
        `${missingTeamFields.join(", ")} are required for team event registration`,
      );
      err.statusCode = 400;
      throw err;
    }
  }

  const requiredCustomFields = getRequiredCustomFields(event.custom_fields);
  if (requiredCustomFields.length) {
    const responses = customFieldResponses ?? {};
    if (!isPlainObject(responses)) {
      const err = new Error("custom_field_responses must be an object");
      err.statusCode = 400;
      throw err;
    }

    const missingRequiredFields = requiredCustomFields
      .filter(
        (field) => !hasValue(findCustomFieldResponseValue(responses, field)),
      )
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
    const missingPaymentFields = [];
    if (!hasValue(transactionId)) missingPaymentFields.push("transaction_id");
    if (!hasValue(paymentProofUrl)) missingPaymentFields.push("payment_proof_url");

    if (missingPaymentFields.length) {
      const err = new Error(
        `${missingPaymentFields.join(", ")} are required for paid event registration`,
      );
      err.statusCode = 400;
      throw err;
    }

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

  const mergedCustomFieldResponses = {
    ...(customFieldResponses ?? {}),
    ...(teamSize != null ? { team_size: teamSize } : {}),
  };

  const registrationCreateData = {
    event_id: eventId,
    user_id: userId,
    registration_status: "registered",
    team_id: teamId ?? null,
    enrollment_number: enrollmentNumber ?? null,
    contact_number: contactNumber ?? null,
    semester: semester ?? null,
    branch: branch ?? null,
    payment_proof_url: paymentProofUrl ?? null,
    transaction_id: transactionId ?? null,
    custom_field_responses: mergedCustomFieldResponses,
  };

  const registrationUpdateData = {
    registration_status: "registered",
    registered_at: new Date(),
    ...(teamId !== undefined && { team_id: teamId }),
    ...(enrollmentNumber !== undefined && {
      enrollment_number: enrollmentNumber,
    }),
    ...(contactNumber !== undefined && { contact_number: contactNumber }),
    ...(semester !== undefined && { semester }),
    ...(branch !== undefined && { branch }),
    ...(paymentProofUrl !== undefined && { payment_proof_url: paymentProofUrl }),
    ...(transactionId !== undefined && { transaction_id: transactionId }),
    ...(payload.custom_field_responses !== undefined || teamSize != null ?
      { custom_field_responses: mergedCustomFieldResponses }
    : {}),
  };

  try {
    await prisma.event_registrations.upsert({
      where: { event_id_user_id: { event_id: eventId, user_id: userId } },
      create: registrationCreateData,
      update: registrationUpdateData,
    });
  } catch (error) {
    if (error?.code === "P2002") {
      const err = new Error(
        "Enrollment number is already registered for this event",
      );
      err.statusCode = 409;
      throw err;
    }
    throw error;
  }

  const updatedEvent = await prisma.events.findUnique({
    where: { id: eventId },
    include: eventInclude(userId),
  });

  return {
    event: mapEvent(updatedEvent, userId),
    registration: {
      team_size: participationType === "team" ? teamSize : 1,
      ...(payment ? { payment } : {}),
    },
  };
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
