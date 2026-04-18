import { beforeEach, describe, expect, it, mock } from "bun:test";
import request from "supertest";
import {
  makeAuthHeader,
  TEST_JWT_SECRET,
  TEST_USER,
  TEST_USER_B,
} from "../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../mocks/prismaMock.js";

mock.module("../../config/prisma.js", () => ({ default: prismaMock }));
mock.module("../../config/queue.js", () => ({
  notificationQueue: {
    add: mock(() => Promise.resolve({ id: "job-1" })),
  },
  connection: {
    quit: mock(() => Promise.resolve()),
  },
}));

process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
process.env.NODE_ENV = "test";

import { createApp } from "../../app.js";

const app = createApp();

const EVENT_ID = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee";
const REGISTRATION_ID = "rrrrrrrr-rrrr-rrrr-rrrr-rrrrrrrrrrrr";

const makeEventRow = (override = {}) => ({
  id: EVENT_ID,
  organizer_id: TEST_USER.id,
  title: "Campus Hack Night",
  category: "Technology",
  about: "Build and ship with your team",
  event_date: new Date("2026-06-15T00:00:00.000Z"),
  start_time: new Date("1970-01-01T09:00:00.000Z"),
  end_time: new Date("1970-01-01T11:00:00.000Z"),
  location_type: "ONLINE",
  location: null,
  meeting_link: "https://meet.example/hacknight",
  ticket_price_type: "FREE",
  price: null,
  max_participant: 100,
  event_status: "published",
  eligibility: null,
  event_image_url: null,
  created_at: new Date("2026-03-28T00:00:00.000Z"),
  venue: "Innovation Hub",
  registration_deadline: null,
  participation_type: "individual",
  min_team_size: 1,
  max_team_size: 1,
  upi_id: null,
  custom_fields: [],
  users: {
    id: TEST_USER.id,
    username: "alice",
    first_name: "Alice",
    last_name: "Smith",
    profile_pic_url: null,
  },
  event_cohosts: [],
  event_activity: [],
  event_prizes: [],
  event_faqs: [],
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
  event_date: new Date("2026-06-15T00:00:00.000Z"),
  venue: "Innovation Hub",
  location: null,
  created_at: new Date("2026-03-28T00:00:00.000Z"),
  ...override,
});

beforeEach(() => {
  resetPrismaMocks();

  prismaMock.events.findMany.mockResolvedValue([]);
  prismaMock.events.findUnique.mockResolvedValue(null);
  prismaMock.events.create.mockResolvedValue(makeEventRow());
  prismaMock.events.update.mockResolvedValue(makeEventRow());

  prismaMock.event_registrations.count.mockResolvedValue(0);
  prismaMock.event_registrations.findUnique.mockResolvedValue(null);
  prismaMock.event_registrations.findFirst.mockResolvedValue(null);
  prismaMock.event_registrations.findMany.mockResolvedValue([]);
  prismaMock.event_registrations.upsert.mockResolvedValue({
    id: REGISTRATION_ID,
  });
  prismaMock.event_registrations.update.mockResolvedValue({
    id: REGISTRATION_ID,
  });

  prismaMock.event_teams.create.mockResolvedValue({
    id: "team-generated-1",
    event_id: EVENT_ID,
    leader_id: TEST_USER_B.id,
  });
  prismaMock.event_teams.findUnique.mockResolvedValue(null);
  prismaMock.event_team_members.createMany.mockResolvedValue({ count: 0 });

  prismaMock.event_cohosts.findUnique.mockResolvedValue(null);
  prismaMock.event_cohosts.findMany.mockResolvedValue([]);
  prismaMock.event_cohosts.delete.mockResolvedValue({ id: "cohost-1" });

  prismaMock.users.findUnique.mockResolvedValue({
    id: TEST_USER_B.id,
    username: "bob",
    first_name: "Bob",
    last_name: "Jones",
    profile_pic_url: null,
  });
  prismaMock.users.count.mockImplementation(({ where }) =>
    Promise.resolve(where?.id?.in?.length ?? 0),
  );
});

describe("Event routes auth", () => {
  it("401 - rejects unauthenticated requests", async () => {
    const res = await request(app).get("/api/events");

    expect(res.status).toBe(401);
    expect(res.body.title).toBe("Unauthorized");
  });
});

describe("GET /api/events", () => {
  it("200 - returns published events payload", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    const res = await request(app)
      .get("/api/events")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.events)).toBe(true);
    expect(res.body.events).toHaveLength(1);
  });

  it("200 - parses query params and clamps page_size", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    const res = await request(app)
      .get(
        "/api/events?category=Tech&location_type=ONLINE&date_from=2026-01-01&date_to=2026-12-31&search=hack&page_size=250",
      )
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(prismaMock.events.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        take: 101,
        orderBy: [{ event_date: "asc" }, { id: "asc" }],
        where: expect.objectContaining({
          event_status: "published",
          category: "Tech",
          location_type: "ONLINE",
        }),
      }),
    );
  });

  it("400 - rejects invalid page_size", async () => {
    const res = await request(app)
      .get("/api/events?page_size=0")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
    expect(prismaMock.events.findMany).not.toHaveBeenCalled();
  });
});

describe("GET /api/events/organized", () => {
  it("200 - filters by organizer or co-host membership and status", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    const res = await request(app)
      .get("/api/events/organized?status=published")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(prismaMock.events.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          event_status: "published",
          AND: [
            {
              OR: [
                { organizer_id: TEST_USER.id },
                { event_cohosts: { some: { user_id: TEST_USER.id } } },
              ],
            },
          ],
        }),
        take: 21,
        orderBy: [{ created_at: "desc" }, { id: "desc" }],
      }),
    );
  });

  it("200 - searches organized events by title only", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    const res = await request(app)
      .get("/api/events/organized?search=hackathon")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(prismaMock.events.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          AND: expect.arrayContaining([
            expect.objectContaining({
              title: {
                contains: "hackathon",
                mode: "insensitive",
              },
            }),
          ]),
        }),
      }),
    );
  });

  it("400 - rejects invalid page_size", async () => {
    const res = await request(app)
      .get("/api/events/organized?page_size=abc")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
    expect(prismaMock.events.findMany).not.toHaveBeenCalled();
  });
});

describe("GET /api/events/my", () => {
  it("200 - defaults to upcoming type", async () => {
    prismaMock.events.findMany.mockResolvedValue([makeSummaryRow()]);

    const res = await request(app)
      .get("/api/events/my")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(prismaMock.events.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        take: 21,
        orderBy: [{ event_date: "asc" }, { id: "asc" }],
      }),
    );
  });

  it("400 - rejects unsupported type", async () => {
    const res = await request(app)
      .get("/api/events/my?type=organizing")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
    expect(res.body.message).toBe("type must be one of: upcoming, past, saved");
  });
});

describe("Event lifecycle routes", () => {
  it("201 - creates event", async () => {
    prismaMock.events.create.mockResolvedValue(
      makeEventRow({ event_status: "draft" }),
    );

    const res = await request(app)
      .post("/api/events")
      .set("Authorization", makeAuthHeader())
      .send({
        title: "Hackathon",
        category: "Technology",
        event_date: "2026-06-15",
        start_time: "09:00",
        end_time: "11:00",
        location_type: "ONLINE",
        meeting_link: "https://meet.example/hackathon",
        event_image_url: "https://cdn.example.com/events/hackathon-banner.jpg",
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(prismaMock.events.create).toHaveBeenCalled();
  });

  it("409 - rejects publishing already published event", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );

    const res = await request(app)
      .patch(`/api/events/${EVENT_ID}/publish`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(409);
    expect(res.body.message).toBe("Event is already published");
  });

  it("200 - gets event details", async () => {
    prismaMock.events.findUnique.mockResolvedValue(makeEventRow());

    const res = await request(app)
      .get(`/api/events/${EVENT_ID}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.event.id).toBe(EVENT_ID);
  });
});

describe("Registration and attendance routes", () => {
  it("200 - registers for event", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }));

    const res = await request(app)
      .post(`/api/events/${EVENT_ID}/register`)
      .set("Authorization", makeAuthHeader(TEST_USER_B));

    expect(res.status).toBe(200);
    expect(prismaMock.event_registrations.upsert).toHaveBeenCalled();
    expect(res.body.registration.id).toBe(REGISTRATION_ID);
    expect(res.body.registration.registration_id).toBe(REGISTRATION_ID);
  });

  it("200 - organizer registers participant", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }))
      .mockResolvedValueOnce(makeEventRow({ event_status: "published" }));

    const res = await request(app)
      .post(`/api/events/${EVENT_ID}/register-participant`)
      .set("Authorization", makeAuthHeader(TEST_USER))
      .send({ participant_user_id: TEST_USER_B.id });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe("Participant registered successfully");
    expect(prismaMock.event_registrations.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          event_id_user_id: {
            event_id: EVENT_ID,
            user_id: TEST_USER_B.id,
          },
        },
      }),
    );
  });

  it("403 - non organizer/co-host cannot register participant", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );

    const res = await request(app)
      .post(`/api/events/${EVENT_ID}/register-participant`)
      .set("Authorization", makeAuthHeader(TEST_USER_B))
      .send({ participant_user_id: "member-1" });

    expect(res.status).toBe(403);
    expect(res.body.message).toBe("Only organizer or co-host can scan tickets");
  });

  it("200 - generates team_id for team registrations", async () => {
    prismaMock.events.findUnique
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          participation_type: "team",
          min_team_size: 2,
          max_team_size: 5,
        }),
      )
      .mockResolvedValueOnce(
        makeEventRow({
          event_status: "published",
          participation_type: "team",
          min_team_size: 2,
          max_team_size: 5,
        }),
      );

    const res = await request(app)
      .post(`/api/events/${EVENT_ID}/register`)
      .set("Authorization", makeAuthHeader(TEST_USER_B))
      .send({
        team_name: "Alpha",
        team_size: 2,
        member_user_ids: ["member-1"],
      });

    expect(res.status).toBe(200);
    expect(res.body.registration.team_id).toBe("team-generated-1");
    expect(prismaMock.event_teams.create).toHaveBeenCalled();
    expect(prismaMock.event_team_members.createMany).toHaveBeenCalled();
  });

  it("409 - rejects team registration when participant already belongs to another team", async () => {
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

    const res = await request(app)
      .post(`/api/events/${EVENT_ID}/register`)
      .set("Authorization", makeAuthHeader(TEST_USER_B))
      .send({
        team_name: "Beta",
        team_size: 2,
        member_user_ids: ["member-1"],
      });

    expect(res.status).toBe(409);
    expect(res.body.message).toBe(
      "Mike Ross is already in team Alpha for this event",
    );

    expect(prismaMock.event_team_members.createMany).not.toHaveBeenCalled();
    expect(prismaMock.event_registrations.upsert).not.toHaveBeenCalled();
  });

  it("200 - returns registration info", async () => {
    prismaMock.events.findUnique.mockResolvedValue({
      id: EVENT_ID,
      title: "Campus Hack Night",
      event_date: new Date("2026-06-15T00:00:00.000Z"),
      start_time: new Date("1970-01-01T09:00:00.000Z"),
      end_time: new Date("1970-01-01T11:00:00.000Z"),
      venue: "Innovation Hub",
      location: null,
      event_status: "published",
    });
    prismaMock.event_registrations.findUnique.mockResolvedValue({
      id: REGISTRATION_ID,
      registration_status: "registered",
      users: {
        id: TEST_USER_B.id,
        username: "bob",
        first_name: "Bob",
        last_name: "Jones",
      },
    });

    const res = await request(app)
      .get(`/api/events/${EVENT_ID}/registration-info`)
      .set("Authorization", makeAuthHeader(TEST_USER_B));

    expect(res.status).toBe(200);
    expect(res.body.registration.registration_id).toBe(REGISTRATION_ID);
  });

  it("200 - marks attendance", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published", organizer_id: TEST_USER.id }),
    );
    prismaMock.event_registrations.findFirst.mockResolvedValue({
      id: REGISTRATION_ID,
      event_id: EVENT_ID,
      user_id: TEST_USER_B.id,
      registration_status: "registered",
    });

    const res = await request(app)
      .post(`/api/events/${EVENT_ID}/attend`)
      .set("Authorization", makeAuthHeader(TEST_USER))
      .send({
        event_id: EVENT_ID,
        user_id: TEST_USER_B.id,
        registration_id: REGISTRATION_ID,
      });

    expect(res.status).toBe(200);
    expect(res.body.message).toBe("Attendance updated successfully");
    expect(prismaMock.event_registrations.update).toHaveBeenCalledWith({
      where: { id: REGISTRATION_ID },
      data: { registration_status: "attended" },
    });
  });

  it("200 - returns attendees for organizer", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({
        event_status: "published",
        participation_type: "individual",
        organizer_id: TEST_USER.id,
      }),
    );
    prismaMock.event_registrations.findMany.mockResolvedValue([
      {
        id: REGISTRATION_ID,
        event_id: EVENT_ID,
        user_id: TEST_USER_B.id,
        registration_status: "registered",
        registered_at: new Date("2026-04-01T10:00:00.000Z"),
        users: {
          id: TEST_USER_B.id,
          username: "bob",
          first_name: "Bob",
          last_name: "Jones",
          profile_pic_url: null,
        },
        event_teams: null,
      },
    ]);

    const res = await request(app)
      .get(`/api/events/${EVENT_ID}/attendees`)
      .set("Authorization", makeAuthHeader(TEST_USER));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.participation_type).toBe("individual");
    expect(Array.isArray(res.body.attendees)).toBe(true);
    expect(res.body.attendees).toHaveLength(1);
    expect(res.body.summary).toEqual({
      total_attendees: 1,
      registered: 1,
      attended: 0,
      cancelled: 0,
    });
  });
});

describe("Cohost routes", () => {
  it("400 - rejects cohost add when user_id is missing", async () => {
    const res = await request(app)
      .post(`/api/events/${EVENT_ID}/cohosts`)
      .set("Authorization", makeAuthHeader())
      .send({});

    expect(res.status).toBe(400);
    expect(prismaMock.event_cohosts.upsert).not.toHaveBeenCalled();
  });

  it("200 - lists cohosts", async () => {
    prismaMock.events.findUnique.mockResolvedValue(
      makeEventRow({ event_status: "published" }),
    );
    prismaMock.event_cohosts.findMany.mockResolvedValue([
      {
        id: "cohost-1",
        event_id: EVENT_ID,
        user_id: TEST_USER_B.id,
        users: {
          id: TEST_USER_B.id,
          username: "bob",
          first_name: "Bob",
          last_name: "Jones",
          profile_pic_url: null,
        },
      },
    ]);

    const res = await request(app)
      .get(`/api/events/${EVENT_ID}/cohosts`)
      .set("Authorization", makeAuthHeader(TEST_USER_B));

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.cohosts)).toBe(true);
    expect(res.body.cohosts).toHaveLength(1);
  });
});
