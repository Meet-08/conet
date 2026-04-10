import { beforeEach, describe, expect, it, mock } from "bun:test";
import { TEST_USER, TEST_USER_B } from "../../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../../mocks/prismaMock.js";

mock.module("../../../config/prisma.js", () => ({ default: prismaMock }));

import {
  addCohostService,
  attendEventService,
  createEventService,
  getEventAttendeesService,
  getRegistrationInfoService,
  listCohostsService,
  listMyEventsService,
  listMyOrganizedEventsService,
  listPublishedEventsService,
  publishEventService,
  registerEventService,
  removeCohostService,
  saveEventService,
} from "../../../services/eventService.js";

const ORGANIZER_ID = TEST_USER.id;
const ATTENDEE_ID = TEST_USER_B.id;
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
  prismaMock.event_registrations.upsert.mockResolvedValue({
    id: REGISTRATION_ID,
  });
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
  prismaMock.event_team_members.createMany.mockResolvedValue({ count: 0 });

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

  it("throws 400 when organizer attempts self-registration", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );

    await expect(
      registerEventService(EVENT_ID, ORGANIZER_ID),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Organizer cannot register for their own event",
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

  it("upserts registration and returns mapped event", async () => {
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

    expect(prismaMock.event_registrations.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          event_id_user_id: {
            event_id: EVENT_ID,
            user_id: ATTENDEE_ID,
          },
        },
      }),
    );
    expect(result.event.is_registered).toBe(true);
    expect(result.event.registration_count).toBe(1);
    expect(result.registration.team_size).toBe(1);
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
        team_size: 4,
        member_user_ids: ["member-1", "member-2"],
      }),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Add exactly 3 team members before registration",
    });
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
      team_size: 2,
      payment_proof_url: "https://cdn.example/proof.png",
      transaction_id: "TXN-123",
      member_user_ids: ["member-1"],
    });

    expect(result.registration.payment).toEqual({
      currency: "INR",
      amount_per_member: 20,
      member_count: 2,
      total_amount: 40,
    });
    expect(result.registration.team_id).toBe("team-generated-1");
    expect(prismaMock.event_registrations.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({
          team_id: "team-generated-1",
          transaction_id: "TXN-123",
          custom_field_responses: {},
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
  it("addCohostService throws 400 when organizer adds self", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());

    await expect(
      addCohostService(EVENT_ID, ORGANIZER_ID, ORGANIZER_ID),
    ).rejects.toMatchObject({
      statusCode: 400,
      message: "Organizer cannot add themselves as a co-host",
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

  it("listCohostsService hides draft event from non-organizer", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "draft" }),
    );

    await expect(
      listCohostsService(EVENT_ID, ATTENDEE_ID),
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
        username: "bob",
        profile_pic_url: null,
        first_name: "Bob",
        last_name: "Jones",
      },
    ]);
  });
});
