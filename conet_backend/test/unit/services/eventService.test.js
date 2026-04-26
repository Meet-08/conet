import { beforeEach, describe, expect, it, mock } from "bun:test";
import { TEST_USER, TEST_USER_B } from "../../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../../mocks/prismaMock.js";

mock.module("../../../config/prisma.js", () => ({ default: prismaMock }));

import {
  addCohostService,
  attendEventService,
  createEventService,
  exportEventParticipationXlsxService,
  getEventAttendeesService,
  getRegistrationInfoService,
  listCohostsService,
  listMyEventsService,
  listMyOrganizedEventsService,
  listPublishedEventsService,
  promoteCohostService,
  publishEventService,
  registerEventService,
  registerParticipantForEventService,
  removeCohostService,
  saveEventService,
} from "../../../services/eventService.js";

const ORGANIZER_ID = TEST_USER.id;
const ATTENDEE_ID = TEST_USER_B.id;
const COHOST_ORGANIZER_ID = "cccccccc-cccc-cccc-cccc-cccccccccccc";
const COHOST_MEMBER_ID = "dddddddd-dddd-dddd-dddd-dddddddddddd";
const EVENT_ID = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee";
const REGISTRATION_ID = "rrrrrrrr-rrrr-rrrr-rrrr-rrrrrrrrrrrr";

const makeEventRow = (override = {}) => ({
  id: EVENT_ID,
  organizer_id: ORGANIZER_ID,
  title: "Campus Hack Night",
  category: "Technology",
  about: "Build, ship, and network",
  event_date: new Date("2026-05-10T00:00:00.000Z"),
  start_time: new Date("1970-01-01T09:00:00.000Z"),
  end_time: new Date("1970-01-01T11:00:00.000Z"),
  location_type: "ONLINE",
  location: null,
  meeting_link: "https://meet.example/hacknight",
  ticket_price_type: "FREE",
  price: null,
  max_participant: 100,
  event_status: "draft",
  eligibility: null,
  event_image_url: null,
  venue: "Main Hall",
  registration_deadline: null,
  participation_type: "individual",
  min_team_size: 1,
  max_team_size: 1,
  upi_id: null,
  custom_fields: [],
  created_at: new Date("2026-03-28T00:00:00.000Z"),
  users: {
    id: ORGANIZER_ID,
    username: "alice",
    first_name: "Alice",
    last_name: "Smith",
    profile_pic_url: null,
  },
  event_activity: [],
  event_prizes: [],
  event_faqs: [],
  event_cohosts: [],
  event_registrations: [],
  event_bookmarks: [],
  _count: { event_registrations: 0 },
  ...override,
});

const makeSummaryRow = (override = {}) => ({
  id: EVENT_ID,
  event_image_url: null,
  title: "Campus Hack Night",
  category: "Technology",
  ticket_price_type: "FREE",
  price: null,
  event_date: new Date("2026-05-10T00:00:00.000Z"),
  venue: "Main Hall",
  location: null,
  created_at: new Date("2026-03-28T00:00:00.000Z"),
  ...override,
});

beforeEach(() => {
  resetPrismaMocks();

  prismaMock.events.findUnique.mockResolvedValue(null);
  prismaMock.events.findMany.mockResolvedValue([]);
  prismaMock.events.create.mockResolvedValue(makeEventRow());
  prismaMock.events.update.mockResolvedValue(makeEventRow());

  prismaMock.event_registrations.count.mockResolvedValue(0);
  prismaMock.event_registrations.create.mockResolvedValue({
    id: REGISTRATION_ID,
  });
  prismaMock.event_registrations.updateMany.mockResolvedValue({ count: 1 });
  prismaMock.event_registrations.findUnique.mockResolvedValue(null);
  prismaMock.event_registrations.findFirst.mockResolvedValue(null);
  prismaMock.event_registrations.findMany.mockResolvedValue([]);
  prismaMock.event_registrations.update.mockResolvedValue({
    id: REGISTRATION_ID,
  });

  prismaMock.event_teams.create.mockResolvedValue({
    id: "team-generated-1",
    event_id: EVENT_ID,
    leader_id: ATTENDEE_ID,
  });
  prismaMock.event_teams.findUnique.mockResolvedValue(null);
  prismaMock.event_team_members.findMany.mockResolvedValue([]);
  prismaMock.event_team_members.createMany.mockResolvedValue({ count: 0 });
  prismaMock.conversations.findUnique.mockResolvedValue(null);
  prismaMock.conversation_members.createMany.mockResolvedValue({ count: 0 });

  prismaMock.event_bookmarks.findUnique.mockResolvedValue(null);
  prismaMock.event_bookmarks.create.mockResolvedValue({
    id: "bookmark-1",
    event_id: EVENT_ID,
    user_id: ATTENDEE_ID,
  });

  prismaMock.event_cohosts.findUnique.mockResolvedValue(null);
  prismaMock.event_cohosts.findMany.mockResolvedValue([]);
  prismaMock.event_cohosts.upsert.mockResolvedValue({
    id: "cohost-1",
    event_id: EVENT_ID,
    user_id: ATTENDEE_ID,
    users: {
      id: ATTENDEE_ID,
      username: "bob",
      first_name: "Bob",
      last_name: "Jones",
      profile_pic_url: null,
    },
  });

  prismaMock.users.findUnique.mockResolvedValue({ id: ATTENDEE_ID });
  prismaMock.users.count.mockImplementation(({ where }) =>
    Promise.resolve(where?.id?.in?.length ?? 0),
  );
});

describe("createEventService", () => {
  it("throws 400 when required fields are missing", async () => {
    await expect(createEventService(ORGANIZER_ID, {})).rejects.toMatchObject({
      statusCode: 400,
      message:
        "title, category, event_date, start_time, end_time, location_type, and event_image_url are required",
    });
  });

  it("throws 400 when offline event omits location", async () => {
    await expect(
      createEventService(ORGANIZER_ID, {
        title: "Offline meetup",
        category: "Networking",
        event_date: "2026-05-10",
        start_time: "10:00",
        end_time: "11:00",
        location_type: "OFFLINE",
        event_image_url: "https://cdn.example.com/events/offline-banner.jpg",
      }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "location is required for offline events",
    });
  });

  it("creates a published event and parses time fields", async () => {
    prismaMock.events.create.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );

    const result = await createEventService(ORGANIZER_ID, {
      title: "Launch Day",
      category: "Technology",
      event_date: "2026-06-01",
      start_time: "09:30",
      end_time: "11:30",
      location_type: "ONLINE",
      meeting_link: "https://meet.example/launch",
      event_image_url: "https://cdn.example.com/events/launch-banner.jpg",
      publish: true,
      activity: [
        { activity_time: "2026-06-01T09:45:00.000Z", activity_title: "Intro" },
      ],
    });

    const createArg = prismaMock.events.create.mock.calls[0][0];
    expect(createArg.data.event_status).toBe("published");
    expect(createArg.data.start_time).toBeInstanceOf(Date);
    expect(createArg.data.end_time).toBeInstanceOf(Date);
    expect(createArg.data.event_activity.create).toHaveLength(1);
    expect(result.event_status).toBe("published");
  });

  it("accepts HH:MM(:SS) activity_time payloads", async () => {
    prismaMock.events.create.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );

    await createEventService(ORGANIZER_ID, {
      title: "Demo Event",
      category: "hackathon",
      event_date: "2026-06-01",
      start_time: "09:30",
      end_time: "11:30",
      location_type: "OFFLINE",
      location: "Main Campus",
      event_image_url: "https://cdn.example.com/events/demo-banner.jpg",
      activity: [
        {
          activity_time: "09:45:00",
          activity_title: "Onboarding",
        },
      ],
    });

    const createArg = prismaMock.events.create.mock.calls[0][0];
    expect(createArg.data.event_activity.create).toHaveLength(1);
    expect(
      createArg.data.event_activity.create[0].activity_time,
    ).toBeInstanceOf(Date);
    expect(
      createArg.data.event_activity.create[0].activity_time.toISOString(),
    ).toBe("1970-01-01T09:45:00.000Z");
  });

  it("throws 400 for invalid activity_time values", async () => {
    await expect(
      createEventService(ORGANIZER_ID, {
        title: "Broken Activity Event",
        category: "Technology",
        event_date: "2026-06-01",
        start_time: "09:30",
        end_time: "11:30",
        location_type: "ONLINE",
        meeting_link: "https://meet.example/demo",
        event_image_url: "https://cdn.example.com/events/demo-banner.jpg",
        activity: [
          {
            activity_time: "not-a-time",
            activity_title: "Intro",
          },
        ],
      }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message:
        "activity[0].activity_time must be a valid ISO date-time or HH:MM(:SS)",
    });
  });

  it("normalizes image custom fields and stores image_url", async () => {
    await createEventService(ORGANIZER_ID, {
      title: "Image Field Event",
      category: "Technology",
      event_date: "2026-06-01",
      start_time: "09:30",
      end_time: "11:30",
      location_type: "ONLINE",
      meeting_link: "https://meet.example/image-field",
      event_image_url: "https://cdn.example.com/events/banner.jpg",
      custom_fields: [
        {
          key: "rules_banner",
          label: "Rules Banner",
          type: "image",
          required: true,
          image_url: "https://cdn.example.com/events/rules.jpg",
        },
      ],
    });

    const createArg = prismaMock.events.create.mock.calls[0][0];
    expect(createArg.data.custom_fields).toEqual([
      {
        key: "rules_banner",
        label: "Rules Banner",
        type: "image",
        required: false,
        image_url: "https://cdn.example.com/events/rules.jpg",
      },
    ]);
  });

  it("throws 400 when image custom field omits image_url", async () => {
    await expect(
      createEventService(ORGANIZER_ID, {
        title: "Broken Image Field Event",
        category: "Technology",
        event_date: "2026-06-01",
        start_time: "09:30",
        end_time: "11:30",
        location_type: "ONLINE",
        meeting_link: "https://meet.example/image-field",
        event_image_url: "https://cdn.example.com/events/banner.jpg",
        custom_fields: [
          {
            key: "rules_banner",
            label: "Rules Banner",
            type: "image",
          },
        ],
      }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "custom_fields[0].image_url is required for image fields",
    });
  });
});

describe("publishEventService", () => {
  it("throws 409 when event is already published", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );

    await expect(
      publishEventService(EVENT_ID, ORGANIZER_ID),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "Event is already published",
    });
  });
});

describe("registerEventService", () => {
  it("throws 409 when event is not published", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "draft" }),
    );

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "Only published events can be registered",
    });
  });

  it("throws 409 when registration deadline is passed", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        registration_deadline: new Date("2020-01-01T00:00:00.000Z"),
      }),
    );

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "Registration deadline has passed",
    });
  });

  it("throws 409 when event capacity is full", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published", max_participant: 1 }),
    );
    prismaMock.event_registrations.count.mockResolvedValue(1);

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "Event registration is full",
    });
  });

  it("creates registration and returns mapped event", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          event_registrations: [{ user_id: ATTENDEE_ID }],
          _count: { event_registrations: 1 },
        }),
      );

    const result = await registerEventService(EVENT_ID, ATTENDEE_ID);

    expect(prismaMock.event_registrations.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          event_id: EVENT_ID,
          user_id: ATTENDEE_ID,
        }),
      }),
    );
    expect(result.event.is_registered).toBe(true);
    expect(result.event.registration_count).toBe(1);
    expect(result.registration.id).toBe(REGISTRATION_ID);
    expect(result.registration.registration_id).toBe(REGISTRATION_ID);
    expect(result.registration.team_size).toBe(1);
  });

  it("adds individual registrant to linked event conversation", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          conversation_id: "conversation-1",
        }),
      )
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          conversation_id: "conversation-1",
        }),
      );
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: "conversation-1",
      type: "group",
    });

    await registerEventService(EVENT_ID, ATTENDEE_ID);

    expect(prismaMock.conversation_members.createMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: [
          {
            conversation_id: "conversation-1",
            user_id: ATTENDEE_ID,
          },
        ],
        skipDuplicates: true,
      }),
    );
  });

  it("adds all team members to linked event conversation", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          participation_type: "team",
          min_team_size: 2,
          max_team_size: 5,
          conversation_id: "conversation-1",
        }),
      )
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          participation_type: "team",
          min_team_size: 2,
          max_team_size: 5,
          conversation_id: "conversation-1",
        }),
      );
    prismaMock.event_team_members.findMany
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([
        { user_id: ATTENDEE_ID },
        { user_id: "member-1" },
      ]);
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: "conversation-1",
      type: "group",
    });

    await registerEventService(EVENT_ID, ATTENDEE_ID, {
      team_name: "Alpha",
      team_size: 2,
      member_user_ids: ["member-1"],
    });

    expect(prismaMock.conversation_members.createMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.arrayContaining([
          {
            conversation_id: "conversation-1",
            user_id: ATTENDEE_ID,
          },
          {
            conversation_id: "conversation-1",
            user_id: "member-1",
          },
        ]),
        skipDuplicates: true,
      }),
    );
  });

  it("throws 400 when required team members are not added", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "team",
        min_team_size: 4,
        max_team_size: 6,
      }),
    );

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID, {
        team_name: "Alpha",
        team_size: 4,
        member_user_ids: ["member-1", "member-2"],
      }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Add exactly 3 team members before registration",
    });
  });

  it("throws 400 when team_name is missing for team events", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "team",
        min_team_size: 2,
        max_team_size: 5,
      }),
    );

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID, {
        team_size: 2,
        member_user_ids: ["member-1"],
      }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "team_name is required for team events",
    });
  });

  it("throws 409 with participant and team name when member already belongs to another team", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "team",
        min_team_size: 2,
        max_team_size: 5,
      }),
    );
    prismaMock.event_team_members.findMany.mockResolvedValue([
      {
        user_id: "member-1",
        users: {
          username: "mike",
          first_name: "Mike",
          last_name: "Ross",
        },
        event_teams: {
          team_name: "Alpha",
        },
      },
    ]);

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID, {
        team_name: "Beta",
        team_size: 2,
        member_user_ids: ["member-1"],
      }),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "Mike Ross is already in team Alpha for this event",
    });

    expect(prismaMock.event_team_members.createMany).not.toHaveBeenCalled();
    expect(prismaMock.event_registrations.create).not.toHaveBeenCalled();
  });

  it("throws 409 when user is already registered", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: REGISTRATION_ID,
      registration_status: "registered",
    });

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "User is already registered for this event",
    });

    expect(prismaMock.event_registrations.create).not.toHaveBeenCalled();
  });

  it("throws 409 when registration already exists even with different custom_field_responses", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: REGISTRATION_ID,
      registration_status: "cancelled",
    });

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID, {
        custom_field_responses: {
          college_id: "A-101",
        },
      }),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "User is already registered for this event",
    });

    expect(prismaMock.event_registrations.create).not.toHaveBeenCalled();
    expect(prismaMock.event_registrations.updateMany).not.toHaveBeenCalled();
  });

  it("throws 400 when required custom form fields are missing", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        custom_fields: [
          {
            key: "college_id",
            label: "College ID",
            required: true,
            type: "text",
          },
        ],
      }),
    );

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID, {
        custom_field_responses: {},
      }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Required custom form fields are missing: College ID",
    });
  });

  it("throws 400 when custom_field_responses includes unknown keys", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        custom_fields: [
          {
            key: "college_id",
            label: "College ID",
            required: false,
            type: "text",
          },
        ],
      }),
    );

    await expect(
      registerEventService(EVENT_ID, ATTENDEE_ID, {
        custom_field_responses: {
          random_key: "value",
        },
      }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Unknown custom form fields in response: random_key",
    });
  });

  it("does not require responses for image custom fields", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          custom_fields: [
            {
              key: "rules_banner",
              label: "Rules Banner",
              type: "image",
              required: true,
              image_url: "https://cdn.example.com/events/rules.jpg",
            },
          ],
        }),
      )
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          custom_fields: [
            {
              key: "rules_banner",
              label: "Rules Banner",
              type: "image",
              required: false,
              image_url: "https://cdn.example.com/events/rules.jpg",
            },
          ],
        }),
      );

    const result = await registerEventService(EVENT_ID, ATTENDEE_ID, {
      custom_field_responses: {},
    });

    expect(result.registration.id).toBe(REGISTRATION_ID);
    expect(prismaMock.event_registrations.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          custom_field_responses: {},
        }),
      }),
    );
  });

  it("returns per-member payment summary for paid team events", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          participation_type: "team",
          min_team_size: 2,
          max_team_size: 5,
          ticket_price_type: "PAID",
          price: 20,
        }),
      )
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          participation_type: "team",
          min_team_size: 2,
          max_team_size: 5,
          ticket_price_type: "PAID",
          price: 20,
        }),
      );

    const result = await registerEventService(EVENT_ID, ATTENDEE_ID, {
      team_name: "Alpha",
      team_size: 2,
      member_user_ids: ["member-1"],
    });

    expect(result.registration.payment).toEqual({
      currency: "INR",
      amount_per_member: 20,
      member_count: 2,
      total_amount: 40,
    });
    expect(result.registration.team_id).toBe("team-generated-1");
    expect(prismaMock.event_registrations.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          team_id: "team-generated-1",
          transaction_id: null,
          custom_field_responses: {},
        }),
      }),
    );
    expect(prismaMock.event_teams.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          team_name: "Alpha",
        }),
      }),
    );
    expect(prismaMock.event_team_members.createMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.arrayContaining([
          expect.objectContaining({
            user_id: ATTENDEE_ID,
            role: "leader",
            team_id: "team-generated-1",
          }),
          expect.objectContaining({
            user_id: "member-1",
            role: "member",
            team_id: "team-generated-1",
          }),
        ]),
        skipDuplicates: true,
      }),
    );
  });
});

describe("registerParticipantForEventService", () => {
  it("allows organizer to register another participant", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          event_registrations: [{ user_id: ATTENDEE_ID }],
          _count: { event_registrations: 1 },
        }),
      );

    const result = await registerParticipantForEventService(
      EVENT_ID,
      ORGANIZER_ID,
      {
        participant_user_id: ATTENDEE_ID,
      },
    );

    expect(prismaMock.event_registrations.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          event_id: EVENT_ID,
          user_id: ATTENDEE_ID,
        }),
      }),
    );
    expect(result.registration.id).toBe(REGISTRATION_ID);
  });

  it("allows organizer or co-host to register themselves", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          event_registrations: [{ user_id: ORGANIZER_ID }],
          _count: { event_registrations: 1 },
        }),
      );

    const result = await registerParticipantForEventService(
      EVENT_ID,
      ORGANIZER_ID,
      {
        participant_user_id: ORGANIZER_ID,
      },
    );

    expect(prismaMock.event_registrations.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          event_id: EVENT_ID,
          user_id: ORGANIZER_ID,
        }),
      }),
    );
    expect(result.registration.id).toBe(REGISTRATION_ID);
  });

  it("throws 409 when host tries to re-register the same participant", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }));
    prismaMock.event_registrations.findUnique.mockResolvedValueOnce({
      id: REGISTRATION_ID,
      registration_status: "registered",
    });

    await expect(
      registerParticipantForEventService(EVENT_ID, ORGANIZER_ID, {
        participant_user_id: ATTENDEE_ID,
      }),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "User is already registered for this event",
    });

    expect(prismaMock.event_registrations.create).not.toHaveBeenCalled();
  });

  it("throws 409 for host registration when participant already has registration with different custom_field_responses", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }));
    prismaMock.event_registrations.findUnique.mockResolvedValueOnce({
      id: REGISTRATION_ID,
      registration_status: "cancelled",
    });

    await expect(
      registerParticipantForEventService(EVENT_ID, ORGANIZER_ID, {
        participant_user_id: ATTENDEE_ID,
        custom_field_responses: {
          tshirt_size: "L",
        },
      }),
    ).rejects.toMatchObject({
      statusCode: 409,
      message: "User is already registered for this event",
    });

    expect(prismaMock.event_registrations.create).not.toHaveBeenCalled();
  });

  it("throws 403 when requester is not organizer or co-host", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );

    await expect(
      registerParticipantForEventService(EVENT_ID, ATTENDEE_ID, {
        participant_user_id: "member-1",
      }),
    ).rejects.toMatchObject({
      statusCode: 403,
      message: "Only organizer or co-host can scan tickets",
    });
  });
});

describe("getRegistrationInfoService", () => {
  it("throws 404 when user has no registration", async () => {
    prismaMock.events.findUnique.mockResolvedValue({
      id: EVENT_ID,
      title: "Campus Hack Night",
      event_date: new Date("2026-05-10T00:00:00.000Z"),
      start_time: new Date("1970-01-01T09:00:00.000Z"),
      end_time: new Date("1970-01-01T11:00:00.000Z"),
      venue: "Main Hall",
      location: null,
      event_status: "published",
    });
    prismaMock.event_registrations.findUnique.mockResolvedValue(null);

    await expect(
      getRegistrationInfoService(EVENT_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 404,
      message: "You are not registered for this event",
    });
  });

  it("returns registration ticket payload when registered", async () => {
    prismaMock.events.findUnique.mockResolvedValue({
      id: EVENT_ID,
      title: "Campus Hack Night",
      event_date: new Date("2026-05-10T00:00:00.000Z"),
      start_time: new Date("1970-01-01T09:00:00.000Z"),
      end_time: new Date("1970-01-01T11:00:00.000Z"),
      venue: "Main Hall",
      location: null,
      event_status: "published",
    });
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: REGISTRATION_ID,
      registration_status: "registered",
      users: {
        id: ATTENDEE_ID,
        username: "bob",
        first_name: "Bob",
        last_name: "Jones",
      },
    });

    const result = await getRegistrationInfoService(EVENT_ID, ATTENDEE_ID);

    expect(result).toEqual({
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      registration_id: REGISTRATION_ID,
    });
  });
});

describe("getEventAttendeesService", () => {
  it("throws 403 when requester is neither organizer nor cohost", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );
    prismaMock.event_cohosts.findUnique.mockResolvedValue(null);

    await expect(
      getEventAttendeesService(EVENT_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 403,
      message: "Only organizer or co-host can scan tickets",
    });
  });

  it("returns attendee list and summary for individual events", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "individual",
      }),
    );
    prismaMock.event_registrations.findMany.mockResolvedValue([
      {
        id: "registration-1",
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
        registration_status: "registered",
        registered_at: new Date("2026-04-01T10:00:00.000Z"),
        users: {
          id: ATTENDEE_ID,
          username: "bob",
          first_name: "Bob",
          last_name: "Jones",
          profile_pic_url: null,
        },
        event_teams: null,
      },
      {
        id: "registration-2",
        event_id: EVENT_ID,
        user_id: "member-2",
        registration_status: "attended",
        registered_at: new Date("2026-04-01T11:00:00.000Z"),
        users: {
          id: "member-2",
          username: "clara",
          first_name: "Clara",
          last_name: "Ray",
          profile_pic_url: null,
        },
        event_teams: null,
      },
    ]);

    const result = await getEventAttendeesService(EVENT_ID, ORGANIZER_ID);

    expect(prismaMock.event_registrations.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          event_id: EVENT_ID,
          registration_status: { in: ["registered", "attended"] },
        },
      }),
    );
    expect(result.participation_type).toBe("individual");
    expect(result.attendees).toHaveLength(2);
    expect(result.summary).toEqual({
      total_attendees: 2,
      registered: 1,
      attended: 1,
      cancelled: 0,
    });
  });

  it("returns team attendee groups for team events", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "team",
      }),
    );
    prismaMock.event_registrations.findMany.mockResolvedValue([
      {
        id: "registration-team-1",
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
        team_id: "team-1",
        registration_status: "registered",
        registered_at: new Date("2026-04-02T10:00:00.000Z"),
        users: {
          id: ATTENDEE_ID,
          username: "bob",
          first_name: "Bob",
          last_name: "Jones",
          profile_pic_url: null,
        },
        event_teams: {
          id: "team-1",
          team_name: "Alpha",
          leader_id: ATTENDEE_ID,
          users: {
            id: ATTENDEE_ID,
            username: "bob",
            first_name: "Bob",
            last_name: "Jones",
            profile_pic_url: null,
          },
          event_team_members: [
            {
              id: "member-row-1",
              user_id: ATTENDEE_ID,
              role: "leader",
              joined_at: new Date("2026-04-02T10:00:00.000Z"),
              users: {
                id: ATTENDEE_ID,
                username: "bob",
                first_name: "Bob",
                last_name: "Jones",
                profile_pic_url: null,
              },
            },
            {
              id: "member-row-2",
              user_id: "member-2",
              role: "member",
              joined_at: new Date("2026-04-02T10:00:00.000Z"),
              users: {
                id: "member-2",
                username: "clara",
                first_name: "Clara",
                last_name: "Ray",
                profile_pic_url: null,
              },
            },
          ],
        },
      },
    ]);

    const result = await getEventAttendeesService(EVENT_ID, ORGANIZER_ID, {
      status: "registered",
    });

    expect(prismaMock.event_registrations.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          event_id: EVENT_ID,
          registration_status: "registered",
        },
      }),
    );
    expect(result.participation_type).toBe("team");
    expect(result.attendees).toHaveLength(1);
    expect(result.attendees[0]).toMatchObject({
      team_id: "team-1",
      team_name: "Alpha",
      member_count: 2,
      registration_id: "registration-team-1",
    });
    expect(result.summary).toEqual({
      total_teams: 1,
      total_members: 2,
      registered: 1,
      attended: 0,
      cancelled: 0,
    });
  });
});

describe("attendEventService", () => {
  it("throws 400 when required fields are missing", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );

    await expect(
      attendEventService(EVENT_ID, ORGANIZER_ID, {}),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "event_id, user_id and registration_id are required",
    });
  });

  it("throws 403 when scanner is neither organizer nor cohost", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );
    prismaMock.event_cohosts.findUnique.mockResolvedValue(null);

    await expect(
      attendEventService(EVENT_ID, ATTENDEE_ID, {
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
        registration_id: REGISTRATION_ID,
      }),
    ).rejects.toMatchObject({
      statusCode: 403,
      message: "Only organizer or co-host can scan tickets",
    });
  });

  it("updates registration status to attended", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published", organizer_id: ORGANIZER_ID }),
    );
    prismaMock.event_registrations.findFirst.mockResolvedValue({
      id: REGISTRATION_ID,
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      registration_status: "registered",
    });

    const result = await attendEventService(EVENT_ID, ORGANIZER_ID, {
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      registration_id: REGISTRATION_ID,
    });

    expect(prismaMock.event_registrations.update).toHaveBeenCalledWith({
      where: { id: REGISTRATION_ID },
      data: { registration_status: "attended" },
    });
    expect(result.message).toBe("Attendance updated successfully");
  });

  it("returns idempotent message when attendee is already marked", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published", organizer_id: ORGANIZER_ID }),
    );
    prismaMock.event_registrations.findFirst.mockResolvedValue({
      id: REGISTRATION_ID,
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      registration_status: "attended",
    });

    const result = await attendEventService(EVENT_ID, ORGANIZER_ID, {
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      registration_id: REGISTRATION_ID,
    });

    expect(prismaMock.event_registrations.update).not.toHaveBeenCalled();
    expect(result.message).toBe("User already marked as attended");
  });
});

describe("exportEventParticipationXlsxService", () => {
  it("exports registered_at with DD/MM/YYYY formatting for individual attendees", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "individual",
      }),
    );
    prismaMock.event_registrations.findMany.mockResolvedValue([
      {
        id: "registration-1",
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
        registration_status: "registered",
        registered_at: new Date("2026-04-01T10:00:00.000Z"),
        users: {
          id: ATTENDEE_ID,
          username: "bob",
          first_name: "Bob",
          last_name: "Jones",
          profile_pic_url: null,
        },
        event_teams: null,
        custom_field_responses: {},
      },
    ]);

    const result = await exportEventParticipationXlsxService(
      EVENT_ID,
      ORGANIZER_ID,
    );

    expect(result.fileName).toBe("Campus_Hack_Night_participants.xlsx");
    const sheet = result.workbook.getWorksheet("Participants");
    expect(sheet.getColumn("register_date").numFmt).toBe("dd/mm/yyyy");
    expect(sheet.getRow(2).getCell("register_date").value).toEqual(
      new Date("2026-04-01T10:00:00.000Z"),
    );
    expect(sheet.getRow(2).getCell("status").value).toBe("registered");
  });

  it("exports registered_at with DD/MM/YYYY formatting for team attendees", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "team",
      }),
    );
    prismaMock.event_registrations.findMany.mockResolvedValue([
      {
        id: "registration-team-1",
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
        team_id: "team-1",
        registration_status: "registered",
        registered_at: new Date("2026-04-02T10:00:00.000Z"),
        users: {
          id: ATTENDEE_ID,
          username: "bob",
          first_name: "Bob",
          last_name: "Jones",
          profile_pic_url: null,
        },
        event_teams: {
          id: "team-1",
          team_name: "Alpha",
          users: {
            id: ATTENDEE_ID,
            username: "bob",
            first_name: "Bob",
            last_name: "Jones",
            profile_pic_url: null,
          },
          event_team_members: [],
        },
        custom_field_responses: {},
      },
    ]);

    const result = await exportEventParticipationXlsxService(
      EVENT_ID,
      ORGANIZER_ID,
    );

    const sheet = result.workbook.getWorksheet("Participants");
    expect(sheet.getColumn("register_date").numFmt).toBe("dd/mm/yyyy");
    expect(sheet.getRow(2).getCell("register_date").value).toEqual(
      new Date("2026-04-02T10:00:00.000Z"),
    );
    expect(sheet.getRow(2).getCell("status").value).toBe("registered");
  });

  it("uses event title for filename when title is non-ASCII", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "individual",
        title: "\u0939\u0948\u0915\u093E\u0925\u0949\u0928 2026",
      }),
    );
    prismaMock.event_registrations.findMany.mockResolvedValue([]);

    const result = await exportEventParticipationXlsxService(
      EVENT_ID,
      ORGANIZER_ID,
    );

    expect(result.fileName).toBe(
      "\u0939\u0948\u0915\u093E\u0925\u0949\u0928_2026_participants.xlsx",
    );
  });
});

describe("saveEventService", () => {
  it("throws 404 when event does not exist", async () => {
    prismaMock.events.findUnique.mockResolvedValue(null);

    await expect(saveEventService(EVENT_ID, ATTENDEE_ID)).rejects.toMatchObject(
      {
        statusCode: 404,
        message: "Event not found",
      },
    );
  });

  it("throws 409 when event is not published", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "draft" }),
    );

    await expect(saveEventService(EVENT_ID, ATTENDEE_ID)).rejects.toMatchObject(
      {
        statusCode: 409,
        message: "Only published events can be saved",
      },
    );
  });

  it("returns idempotent success when event is already saved", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );
    prismaMock.event_bookmarks.findUnique.mockResolvedValue({
      id: "bookmark-1",
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
    });

    const result = await saveEventService(EVENT_ID, ATTENDEE_ID);

    expect(prismaMock.event_bookmarks.create).not.toHaveBeenCalled();
    expect(prismaMock.event_bookmarks.delete).toHaveBeenCalledWith({
      where: {
        event_id_user_id: {
          event_id: EVENT_ID,
          user_id: ATTENDEE_ID,
        },
      },
    });
    expect(result).toEqual({
      success: true,
      message: "Event removed from saved",
    });
  });

  it("creates bookmark and returns success message", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );
    prismaMock.event_bookmarks.findUnique.mockResolvedValue(null);

    const result = await saveEventService(EVENT_ID, ATTENDEE_ID);

    expect(prismaMock.event_bookmarks.create).toHaveBeenCalledWith({
      data: {
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
      },
    });
    expect(result).toEqual({
      success: true,
      message: "Event saved successfully",
    });
  });
});

describe("listPublishedEventsService", () => {
  it("throws 400 when cursor format is invalid", async () => {
    await expect(
      listPublishedEventsService({ cursor: "not-a-valid-cursor" }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Invalid cursor format",
    });
  });

  it("returns paginated event summaries with nextCursor", async () => {
    prismaMock.events.findMany.mockResolvedValue([
      makeSummaryRow({
        id: "event-1",
        event_date: new Date("2026-05-10T00:00:00.000Z"),
      }),
      makeSummaryRow({
        id: "event-2",
        event_date: new Date("2026-05-11T00:00:00.000Z"),
      }),
      makeSummaryRow({
        id: "event-3",
        event_date: new Date("2026-05-12T00:00:00.000Z"),
      }),
    ]);

    const result = await listPublishedEventsService({
      category: "Technology",
      location_type: "ONLINE",
      search: "hack",
      page_size: 2,
    });

    expect(prismaMock.events.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        take: 3,
        orderBy: [{ event_date: "asc" }, { id: "asc" }],
      }),
    );
    expect(result.events).toHaveLength(2);
    expect(result.hasMore).toBe(true);
    expect(typeof result.nextCursor).toBe("string");
  });
});

describe("listMyOrganizedEventsService", () => {
  it("throws 400 when organizer cursor is invalid", async () => {
    await expect(
      listMyOrganizedEventsService(ORGANIZER_ID, { cursor: "bad-cursor" }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Invalid cursor format",
    });
  });

  it("applies status filter and descending sort", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    await listMyOrganizedEventsService(ORGANIZER_ID, {
      status: "draft",
      page_size: 10,
    });

    const arg = prismaMock.events.findMany.mock.calls[0][0];
    expect(arg.where).toMatchObject({
      event_status: "draft",
      AND: [
        {
          OR: [
            { organizer_id: ORGANIZER_ID },
            { event_cohosts: { some: { user_id: ORGANIZER_ID } } },
          ],
        },
      ],
    });
    expect(arg.orderBy).toEqual([{ created_at: "desc" }, { id: "desc" }]);
  });

  it("filters organized events by title only when search is provided", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    await listMyOrganizedEventsService(ORGANIZER_ID, {
      search: "hackathon",
      page_size: 10,
    });

    const arg = prismaMock.events.findMany.mock.calls[0][0];
    expect(arg.where.AND).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          title: {
            contains: "hackathon",
            mode: "insensitive",
          },
        }),
      ]),
    );
    expect(arg.where.AND).not.toEqual(
      expect.arrayContaining([
        expect.objectContaining({ category: expect.anything() }),
      ]),
    );
  });
});

describe("listMyEventsService", () => {
  it("throws 400 when type is invalid", async () => {
    await expect(
      listMyEventsService(ORGANIZER_ID, { type: "organizing" }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "type must be one of: upcoming, past, saved",
    });
  });

  it("uses bookmark filter for saved type", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    await listMyEventsService(ORGANIZER_ID, {
      type: "saved",
      page_size: 5,
    });

    const arg = prismaMock.events.findMany.mock.calls[0][0];
    expect(arg.where.event_bookmarks).toEqual({
      some: { user_id: ORGANIZER_ID },
    });
    expect(arg.orderBy).toEqual([{ event_date: "asc" }, { id: "asc" }]);
  });

  it("uses descending order for past events", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    await listMyEventsService(ORGANIZER_ID, {
      type: "past",
      page_size: 5,
    });

    const arg = prismaMock.events.findMany.mock.calls[0][0];
    expect(arg.orderBy).toEqual([{ event_date: "desc" }, { id: "desc" }]);
  });
});

describe("cohost services", () => {
  it("promoteCohostService allows organizer-role cohost requester", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.event_cohosts.findUnique
      .mockResolvedValueOnce({
        id: "cohost-organizer-1",
        event_id: EVENT_ID,
        user_id: COHOST_ORGANIZER_ID,
        role: "organizer",
      })
      .mockResolvedValueOnce({
        id: "cohost-1",
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
        role: "cohost",
        users: {
          id: ATTENDEE_ID,
          username: "bob",
          first_name: "Bob",
          last_name: "Jones",
          profile_pic_url: null,
        },
      });
    prismaMock.event_cohosts.update.mockResolvedValue({
      id: "cohost-1",
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      role: "organizer",
      users: {
        id: ATTENDEE_ID,
        username: "bob",
        first_name: "Bob",
        last_name: "Jones",
        profile_pic_url: null,
      },
    });

    const result = await promoteCohostService(
      EVENT_ID,
      COHOST_ORGANIZER_ID,
      ATTENDEE_ID,
    );

    expect(result.role).toBe("organizer");
    expect(prismaMock.event_cohosts.update).toHaveBeenCalledTimes(1);
  });

  it("promoteCohostService throws 403 for non-organizer-role cohost requester", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.event_cohosts.findUnique.mockResolvedValue({
      id: "cohost-member-1",
      event_id: EVENT_ID,
      user_id: COHOST_MEMBER_ID,
      role: "cohost",
    });

    await expect(
      promoteCohostService(EVENT_ID, COHOST_MEMBER_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 403,
      message:
        "Only the organizer or organizer-role co-host can perform this action",
    });
  });

  it("addCohostService throws 400 when organizer adds self", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());

    await expect(
      addCohostService(EVENT_ID, ORGANIZER_ID, ORGANIZER_ID),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Requester cannot add themselves as a co-host",
    });
  });

  it("addCohostService allows organizer-role cohost requester", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.event_cohosts.findUnique.mockResolvedValue({
      id: "cohost-organizer-1",
      event_id: EVENT_ID,
      user_id: COHOST_ORGANIZER_ID,
      role: "organizer",
    });
    prismaMock.users.findUnique.mockResolvedValue({ id: ATTENDEE_ID });
    prismaMock.event_cohosts.upsert.mockResolvedValue({
      id: "cohost-2",
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      role: "cohost",
      users: {
        id: ATTENDEE_ID,
        username: "bob",
        first_name: "Bob",
        last_name: "Jones",
        profile_pic_url: null,
      },
    });

    const result = await addCohostService(
      EVENT_ID,
      COHOST_ORGANIZER_ID,
      ATTENDEE_ID,
    );

    expect(result.user_id).toBe(ATTENDEE_ID);
    expect(prismaMock.event_cohosts.upsert).toHaveBeenCalledTimes(1);
  });

  it("addCohostService throws 403 for regular cohost requester", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.event_cohosts.findUnique.mockResolvedValue({
      id: "cohost-member-1",
      event_id: EVENT_ID,
      user_id: COHOST_MEMBER_ID,
      role: "cohost",
    });

    await expect(
      addCohostService(EVENT_ID, COHOST_MEMBER_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 403,
      message:
        "Only the organizer or organizer-role co-host can perform this action",
    });
  });

  it("addCohostService throws 404 when target user is missing", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.users.findUnique.mockResolvedValue(null);

    await expect(
      addCohostService(EVENT_ID, ORGANIZER_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 404,
      message: "User not found",
    });
  });

  it("removeCohostService allows organizer-role cohost requester", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.event_cohosts.findUnique
      .mockResolvedValueOnce({
        id: "cohost-organizer-1",
        event_id: EVENT_ID,
        user_id: COHOST_ORGANIZER_ID,
        role: "organizer",
      })
      .mockResolvedValueOnce({
        id: "cohost-1",
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
        role: "cohost",
      });

    await removeCohostService(EVENT_ID, COHOST_ORGANIZER_ID, ATTENDEE_ID);

    expect(prismaMock.event_cohosts.delete).toHaveBeenCalledWith({
      where: { event_id_user_id: { event_id: EVENT_ID, user_id: ATTENDEE_ID } },
    });
  });

  it("removeCohostService throws 403 for regular cohost requester", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.event_cohosts.findUnique.mockResolvedValue({
      id: "cohost-member-1",
      event_id: EVENT_ID,
      user_id: COHOST_MEMBER_ID,
      role: "cohost",
    });

    await expect(
      removeCohostService(EVENT_ID, COHOST_MEMBER_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 403,
      message:
        "Only the organizer or organizer-role co-host can perform this action",
    });
  });

  it("removeCohostService throws 404 when cohost is missing", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.event_cohosts.findUnique.mockResolvedValue(null);

    await expect(
      removeCohostService(EVENT_ID, ORGANIZER_ID, ATTENDEE_ID),
    ).rejects.toMatchObject({
      statusCode: 404,
      message: "Co-host not found for this event",
    });
  });

  it("listCohostsService allows organizer-role cohost on draft event", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "draft" }),
    );
    prismaMock.event_cohosts.findUnique.mockResolvedValue({
      id: "cohost-organizer-1",
      event_id: EVENT_ID,
      user_id: COHOST_ORGANIZER_ID,
      role: "organizer",
    });
    prismaMock.event_cohosts.findMany.mockResolvedValue([]);

    const result = await listCohostsService(EVENT_ID, COHOST_ORGANIZER_ID);

    expect(result).toEqual([]);
  });

  it("listCohostsService hides draft event from non-organizer", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "draft" }),
    );
    prismaMock.event_cohosts.findUnique.mockResolvedValue({
      id: "cohost-member-1",
      event_id: EVENT_ID,
      user_id: COHOST_MEMBER_ID,
      role: "cohost",
    });

    await expect(
      listCohostsService(EVENT_ID, COHOST_MEMBER_ID),
    ).rejects.toMatchObject({
      statusCode: 404,
      message: "Event not found",
    });
  });

  it("listCohostsService returns mapped cohosts for published event", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );
    prismaMock.event_cohosts.findMany.mockResolvedValue([
      {
        id: "cohost-1",
        event_id: EVENT_ID,
        user_id: ATTENDEE_ID,
        role: "cohost",
        users: {
          id: ATTENDEE_ID,
          username: "bob",
          first_name: "Bob",
          last_name: "Jones",
          profile_pic_url: null,
        },
      },
    ]);

    const result = await listCohostsService(EVENT_ID, ATTENDEE_ID);

    expect(result).toEqual([
      {
        id: "cohost-1",
        user_id: ATTENDEE_ID,
        role: "cohost",
        username: "bob",
        profile_pic_url: null,
        first_name: "Bob",
        last_name: "Jones",
      },
    ]);
  });

  it("promoteCohostService updates role to organizer and keeps event organizer unchanged", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());
    prismaMock.event_cohosts.findUnique.mockResolvedValue({
      id: "cohost-1",
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      role: "cohost",
      users: {
        id: ATTENDEE_ID,
        username: "bob",
        first_name: "Bob",
        last_name: "Jones",
        profile_pic_url: null,
      },
    });
    prismaMock.event_cohosts.update.mockResolvedValue({
      id: "cohost-1",
      event_id: EVENT_ID,
      user_id: ATTENDEE_ID,
      role: "organizer",
      users: {
        id: ATTENDEE_ID,
        username: "bob",
        first_name: "Bob",
        last_name: "Jones",
        profile_pic_url: null,
      },
    });

    const result = await promoteCohostService(
      EVENT_ID,
      ORGANIZER_ID,
      ATTENDEE_ID,
    );

    expect(prismaMock.event_cohosts.update).toHaveBeenCalledWith({
      where: { event_id_user_id: { event_id: EVENT_ID, user_id: ATTENDEE_ID } },
      data: { role: "organizer" },
      include: expect.any(Object),
    });
    expect(result).toEqual({
      id: "cohost-1",
      user_id: ATTENDEE_ID,
      role: "organizer",
      username: "bob",
      profile_pic_url: null,
      first_name: "Bob",
      last_name: "Jones",
    });
  });
});
