import { describe, expect, it, mock } from "bun:test";

import {
  addCohost,
  listMyEvents,
  listMyOrganizedEvents,
  listPublishedEvents,
} from "../../../controllers/eventController.js";

const makeReq = (override = {}) => ({
  user: { id: "11111111-1111-1111-1111-111111111111" },
  body: {},
  params: {},
  query: {},
  ...override,
});

const makeRes = () => ({
  statusCode: 200,
  status(code) {
    this.statusCode = code;
    return this;
  },
  json() {
    return this;
  },
});

describe("eventController validation paths", () => {
  it("listPublishedEvents rejects non-positive page_size", async () => {
    const req = makeReq({ query: { page_size: "0" } });
    const res = makeRes();
    const next = mock(() => {});

    await listPublishedEvents(req, res, next);

    expect(res.statusCode).toBe(400);
    expect(next).toHaveBeenCalledWith(expect.any(Error));
    expect(next.mock.calls[0][0].message).toBe(
      "page_size must be a positive integer",
    );
  });

  it("listMyOrganizedEvents rejects invalid page_size", async () => {
    const req = makeReq({ query: { page_size: "abc" } });
    const res = makeRes();
    const next = mock(() => {});

    await listMyOrganizedEvents(req, res, next);

    expect(res.statusCode).toBe(400);
    expect(next).toHaveBeenCalledWith(expect.any(Error));
  });

  it("listMyEvents rejects invalid page_size", async () => {
    const req = makeReq({ query: { page_size: "-5" } });
    const res = makeRes();
    const next = mock(() => {});

    await listMyEvents(req, res, next);

    expect(res.statusCode).toBe(400);
    expect(next).toHaveBeenCalledWith(expect.any(Error));
  });

  it("addCohost requires user_id in body", async () => {
    const req = makeReq({ params: { id: "event-1" }, body: {} });
    const res = makeRes();
    const next = mock(() => {});

    await addCohost(req, res, next);

    expect(res.statusCode).toBe(400);
    expect(next).toHaveBeenCalledWith(expect.any(Error));
    expect(next.mock.calls[0][0].message).toBe("user_id is required");
  });
});
