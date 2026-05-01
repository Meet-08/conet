/**
 * Integration tests – /api/groups routes
 *
 * Covers:
 *  ✓ POST   /api/groups                          – create group
 *  ✓ PATCH  /api/groups/:groupId                 – update group (admin only)
 *  ✓ DELETE /api/groups/:groupId                 – delete group (admin only)
 *  ✓ GET    /api/groups/:groupId/members         – list members
 *  ✓ POST   /api/groups/:groupId/members         – add member (admin only)
 *  ✓ DELETE /api/groups/:groupId/members/:userId – remove / leave
 *  ✓ POST   /api/groups/:groupId/members/:userId/promote – promote member to admin
 *  ✓ POST   /api/groups/:groupId/members/:userId/demote  – demote admin to member
 *  ✓ GET    /api/conversations?type=group        – filter by type
 *  ✓ Auth required on every route
 *  ✓ Authorization rules (non-admin rejection)
 *  ✓ Validation rejects bad input
 */

import { beforeEach, describe, expect, it, mock } from "bun:test";
import request from "supertest";
import {
  makeAuthHeader,
  TEST_JWT_SECRET,
  TEST_USER,
  TEST_USER_B,
} from "../mocks/authMock.js";
import { prismaMock, resetPrismaMocks } from "../mocks/prismaMock.js";

mock.module("../../config/queue.js", () => ({
  notificationQueue: {
    add: mock(() => Promise.resolve()),
  },
}));

mock.module("../../config/prisma.js", () => ({ default: prismaMock }));

process.env.SUPABASE_JWT_SECRET = TEST_JWT_SECRET;
process.env.NODE_ENV = "test";

import { createApp } from "../../app.js";

const app = createApp();

// ─── Fixtures ───────────────────────────────────────────────────────────────

const GROUP_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const USER_C_ID = "33333333-3333-3333-3333-333333333333";
const MSG_ID = "dddddddd-dddd-dddd-dddd-dddddddddddd";

const mockUserC = {
  id: USER_C_ID,
  email: "carol@test.edu",
  username: "carol",
  first_name: "Carol",
  last_name: "White",
  profile_pic_url: null,
  user_role: "user",
  is_verified: false,
};

/** A group conversation row from Prisma (with members included). */
const mockGroupConversation = {
  id: GROUP_ID,
  type: "group",
  name: "Study Crew",
  description: "Core semester prep group",
  group_image_url: null,
  only_admin_add_members: true,
  only_admin_remove_members: true,
  only_admin_edit_group: true,
  only_admin_send_messages: true,
  created_by: TEST_USER.id,
  created_at: new Date(),
  updated_at: new Date(),
  last_message_id: null,
  messages_conversations_last_message_idTomessages: null,
  conversation_members: [
    {
      user_id: TEST_USER.id,
      role: "admin",
      joined_at: new Date(),
      users: {
        id: TEST_USER.id,
        email: TEST_USER.email,
        username: "alice",
        first_name: "Alice",
        last_name: "Smith",
        profile_pic_url: null,
        user_role: "user",
        is_verified: false,
      },
    },
    {
      user_id: TEST_USER_B.id,
      role: "member",
      joined_at: new Date(),
      users: {
        id: TEST_USER_B.id,
        email: TEST_USER_B.email,
        username: "bob",
        first_name: "Bob",
        last_name: "Jones",
        profile_pic_url: null,
        user_role: "user",
        is_verified: false,
      },
    },
  ],
};

/** Same group but with a last_message (used for list tests). */
const mockGroupWithMessage = {
  ...mockGroupConversation,
  last_message_id: MSG_ID,
  messages_conversations_last_message_idTomessages: {
    content: "Hey everyone!",
    media_urls: [],
  },
};

const mockGroupWithBobAsAdmin = {
  ...mockGroupConversation,
  conversation_members: [
    mockGroupConversation.conversation_members[0],
    {
      ...mockGroupConversation.conversation_members[1],
      role: "admin",
    },
  ],
};

beforeEach(() => {
  resetPrismaMocks();
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/groups", () => {
  it("201 – creates a group and returns it", async () => {
    prismaMock.users.findMany.mockResolvedValue([
      { id: TEST_USER.id },
      { id: TEST_USER_B.id },
    ]);
    prismaMock.conversations.create.mockResolvedValue(mockGroupConversation);

    const res = await request(app)
      .post("/api/groups")
      .set("Authorization", makeAuthHeader())
      .send({ name: "Study Crew", memberIds: [TEST_USER_B.id] });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.group.type).toBe("group");
    expect(res.body.group.name).toBe("Study Crew");
  });

  it("201 – accepts optional description and permissions", async () => {
    prismaMock.users.findMany.mockResolvedValue([
      { id: TEST_USER.id },
      { id: TEST_USER_B.id },
    ]);
    prismaMock.conversations.create.mockResolvedValue({
      ...mockGroupConversation,
      description: "Open group",
      only_admin_add_members: false,
      only_admin_remove_members: false,
      only_admin_edit_group: false,
      only_admin_send_messages: false,
    });

    const res = await request(app)
      .post("/api/groups")
      .set("Authorization", makeAuthHeader())
      .send({
        name: "Study Crew",
        description: "Open group",
        memberIds: [TEST_USER_B.id],
        onlyAdminAddMembers: false,
        onlyAdminRemoveMembers: false,
        onlyAdminEditGroup: false,
        onlyAdminSendMessages: false,
      });

    expect(res.status).toBe(201);
    expect(res.body.group.description).toBe("Open group");
    expect(res.body.group.only_admin_add_members).toBe(false);
    expect(res.body.group.only_admin_remove_members).toBe(false);
    expect(res.body.group.only_admin_edit_group).toBe(false);
    expect(res.body.group.only_admin_send_messages).toBe(false);
  });

  it("400 – rejects missing name", async () => {
    const res = await request(app)
      .post("/api/groups")
      .set("Authorization", makeAuthHeader())
      .send({ memberIds: [TEST_USER_B.id] });

    expect(res.status).toBe(400);
  });

  it("400 – rejects empty memberIds array", async () => {
    const res = await request(app)
      .post("/api/groups")
      .set("Authorization", makeAuthHeader())
      .send({ name: "Lonely Group", memberIds: [] });

    expect(res.status).toBe(400);
  });

  it("400 – rejects when no memberIds provided at all", async () => {
    const res = await request(app)
      .post("/api/groups")
      .set("Authorization", makeAuthHeader())
      .send({ name: "Solo Group" });

    expect(res.status).toBe(400);
  });

  it("404 – returns not found if a member UUID does not exist", async () => {
    // Only one user found when we expect two
    prismaMock.users.findMany.mockResolvedValue([{ id: TEST_USER.id }]);

    const res = await request(app)
      .post("/api/groups")
      .set("Authorization", makeAuthHeader())
      .send({ name: "Ghost Group", memberIds: [TEST_USER_B.id] });

    expect(res.status).toBe(404);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app)
      .post("/api/groups")
      .send({ name: "Unauth Group", memberIds: [TEST_USER_B.id] });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("PATCH /api/groups/:groupId", () => {
  it("200 – admin can update group name", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );
    prismaMock.conversations.update.mockResolvedValue({
      ...mockGroupConversation,
      name: "Updated Crew",
    });

    const res = await request(app)
      .patch(`/api/groups/${GROUP_ID}`)
      .set("Authorization", makeAuthHeader())
      .send({ name: "Updated Crew" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.group.name).toBe("Updated Crew");
  });

  it("200 – updates description and permission flags", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );
    prismaMock.conversations.update.mockResolvedValue({
      ...mockGroupConversation,
      description: "Open collaboration",
      only_admin_add_members: false,
      only_admin_remove_members: false,
      only_admin_edit_group: false,
      only_admin_send_messages: false,
    });

    const res = await request(app)
      .patch(`/api/groups/${GROUP_ID}`)
      .set("Authorization", makeAuthHeader())
      .send({
        description: "Open collaboration",
        onlyAdminAddMembers: false,
        onlyAdminRemoveMembers: false,
        onlyAdminEditGroup: false,
        onlyAdminSendMessages: false,
      });

    expect(res.status).toBe(200);
    expect(res.body.group.description).toBe("Open collaboration");
    expect(res.body.group.only_admin_add_members).toBe(false);
    expect(res.body.group.only_admin_remove_members).toBe(false);
    expect(res.body.group.only_admin_edit_group).toBe(false);
    expect(res.body.group.only_admin_send_messages).toBe(false);
  });

  it("403 – non-admin cannot update group", async () => {
    const groupWhereAliceIsMember = {
      ...mockGroupConversation,
      conversation_members: mockGroupConversation.conversation_members.map(
        (m) => (m.user_id === TEST_USER.id ? { ...m, role: "member" } : m),
      ),
    };
    prismaMock.conversations.findUnique.mockResolvedValue(
      groupWhereAliceIsMember,
    );

    const res = await request(app)
      .patch(`/api/groups/${GROUP_ID}`)
      .set("Authorization", makeAuthHeader())
      .send({ name: "Hijacked" });

    expect(res.status).toBe(403);
  });

  it("404 – group not found", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .patch(`/api/groups/${GROUP_ID}`)
      .set("Authorization", makeAuthHeader())
      .send({ name: "Ghost" });

    expect(res.status).toBe(404);
  });

  it("400 – rejects update with no fields", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );

    const res = await request(app)
      .patch(`/api/groups/${GROUP_ID}`)
      .set("Authorization", makeAuthHeader())
      .send({});

    expect(res.status).toBe(400);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app)
      .patch(`/api/groups/${GROUP_ID}`)
      .send({ name: "Unauth" });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("DELETE /api/groups/:groupId", () => {
  it("200 – creator can delete a group", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );
    prismaMock.conversations.delete.mockResolvedValue({});

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(prismaMock.conversations.delete).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: GROUP_ID } }),
    );
  });

  it("403 – non-creator admin cannot delete group", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      ...mockGroupConversation,
      created_by: TEST_USER_B.id,
    });

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(403);
  });

  it("404 – group not found", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(404);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).delete(`/api/groups/${GROUP_ID}`);

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/groups/:groupId/members", () => {
  it("200 – member can list group members", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );

    const res = await request(app)
      .get(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(2);
  });

  it("403 – non-member cannot list members", async () => {
    // Alice is NOT in this group
    const foreignGroup = {
      ...mockGroupConversation,
      conversation_members: mockGroupConversation.conversation_members.filter(
        (m) => m.user_id !== TEST_USER.id,
      ),
    };
    prismaMock.conversations.findUnique.mockResolvedValue(foreignGroup);

    const res = await request(app)
      .get(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(403);
  });

  it("404 – group not found", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .get(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(404);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).get(`/api/groups/${GROUP_ID}/members`);

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/groups/:groupId/members", () => {
  it("201 – admin can add a new member", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );
    prismaMock.users.findUnique.mockResolvedValue(mockUserC);
    prismaMock.conversation_members.create.mockResolvedValue({
      conversation_id: GROUP_ID,
      user_id: USER_C_ID,
      role: "member",
    });

    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader())
      .send({ userId: USER_C_ID });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.member.id).toBe(USER_C_ID);
    expect(res.body.member.role).toBe("member");
  });

  it("400 – rejects missing userId", async () => {
    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader())
      .send({});

    expect(res.status).toBe(400);
  });

  it("403 – non-admin cannot add members", async () => {
    const groupWhereAliceIsMember = {
      ...mockGroupConversation,
      conversation_members: mockGroupConversation.conversation_members.map(
        (m) => (m.user_id === TEST_USER.id ? { ...m, role: "member" } : m),
      ),
    };
    prismaMock.conversations.findUnique.mockResolvedValue(
      groupWhereAliceIsMember,
    );

    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader())
      .send({ userId: USER_C_ID });

    expect(res.status).toBe(403);
  });

  it("201 – non-admin can add members when permission allows members", async () => {
    const openAddPermissionsGroup = {
      ...mockGroupConversation,
      only_admin_add_members: false,
      conversation_members: mockGroupConversation.conversation_members.map(
        (m) => (m.user_id === TEST_USER.id ? { ...m, role: "member" } : m),
      ),
    };

    prismaMock.conversations.findUnique.mockResolvedValue(
      openAddPermissionsGroup,
    );
    prismaMock.users.findUnique.mockResolvedValue(mockUserC);
    prismaMock.conversation_members.create.mockResolvedValue({
      conversation_id: GROUP_ID,
      user_id: USER_C_ID,
      role: "member",
    });

    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader())
      .send({ userId: USER_C_ID });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
  });

  it("409 – rejects adding an existing member", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );

    // Bob is already a member
    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader())
      .send({ userId: TEST_USER_B.id });

    expect(res.status).toBe(409);
  });

  it("404 – group not found", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members`)
      .set("Authorization", makeAuthHeader())
      .send({ userId: USER_C_ID });

    expect(res.status).toBe(404);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members`)
      .send({ userId: USER_C_ID });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("DELETE /api/groups/:groupId/members/:userId", () => {
  it("200 – admin can remove a non-admin member", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );
    prismaMock.conversation_members.delete.mockResolvedValue({});

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("200 – a member can leave (remove themselves)", async () => {
    // Bob (member) leaving – test as Bob by using TEST_USER_B
    // We need a separate test user signed in as Bob.
    // Reuse the existing app with a fresh request using Bob's auth token.
    const groupWithBobAsMember = {
      ...mockGroupConversation,
      conversation_members: [
        // Alice is still admin
        mockGroupConversation.conversation_members[0],
        // Bob is member
        { ...mockGroupConversation.conversation_members[1], role: "member" },
      ],
    };
    prismaMock.conversations.findUnique.mockResolvedValue(groupWithBobAsMember);
    prismaMock.conversation_members.delete.mockResolvedValue({});

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}`)
      .set(
        "Authorization",
        `Bearer ${(await import("../mocks/authMock.js")).makeJwt(TEST_USER_B)}`,
      );

    expect(res.status).toBe(200);
  });

  it("403 – non-admin cannot remove another member", async () => {
    const groupWhereAliceIsMember = {
      ...mockGroupConversation,
      conversation_members: mockGroupConversation.conversation_members.map(
        (m) => (m.user_id === TEST_USER.id ? { ...m, role: "member" } : m),
      ),
    };
    prismaMock.conversations.findUnique.mockResolvedValue(
      groupWhereAliceIsMember,
    );

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(403);
  });

  it("200 – non-admin can remove another member when permission allows members", async () => {
    const openRemovePermissionsGroup = {
      ...mockGroupConversation,
      only_admin_remove_members: false,
      conversation_members: mockGroupConversation.conversation_members.map(
        (m) => (m.user_id === TEST_USER.id ? { ...m, role: "member" } : m),
      ),
    };

    prismaMock.conversations.findUnique.mockResolvedValue(
      openRemovePermissionsGroup,
    );
    prismaMock.conversation_members.delete.mockResolvedValue({});

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("400 – last admin cannot leave without promoting first", async () => {
    // Alice is the only admin and tries to remove herself
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}/members/${TEST_USER.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });

  it("404 – group not found", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .delete(`/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(404);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).delete(
      `/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}`,
    );

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/groups/:groupId/members/:userId/promote", () => {
  it("200 – admin can promote a member to admin", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );
    prismaMock.users.findUnique.mockResolvedValue(
      mockGroupConversation.conversation_members[1].users,
    );
    prismaMock.conversation_members.update.mockResolvedValue({});

    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}/promote`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.member.role).toBe("admin");
  });

  it("403 – non-admin cannot promote members", async () => {
    const groupWhereAliceIsMember = {
      ...mockGroupConversation,
      conversation_members: mockGroupConversation.conversation_members.map(
        (m) => (m.user_id === TEST_USER.id ? { ...m, role: "member" } : m),
      ),
    };
    prismaMock.conversations.findUnique.mockResolvedValue(
      groupWhereAliceIsMember,
    );

    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}/promote`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(403);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).post(
      `/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}/promote`,
    );

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("POST /api/groups/:groupId/members/:userId/demote", () => {
  it("200 – admin can demote another admin to member", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupWithBobAsAdmin,
    );
    prismaMock.users.findUnique.mockResolvedValue(
      mockGroupConversation.conversation_members[1].users,
    );
    prismaMock.conversation_members.update.mockResolvedValue({});

    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}/demote`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.member.role).toBe("member");
  });

  it("400 – last admin cannot demote themselves", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue(
      mockGroupConversation,
    );

    const res = await request(app)
      .post(`/api/groups/${GROUP_ID}/members/${TEST_USER.id}/demote`)
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });

  it("401 – requires authentication", async () => {
    const res = await request(app).post(
      `/api/groups/${GROUP_ID}/members/${TEST_USER_B.id}/demote`,
    );

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("GET /api/conversations – type filter", () => {
  it("200 – ?type=group returns only group conversations", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([mockGroupWithMessage]);
    prismaMock.messages.groupBy.mockResolvedValue([]);

    const res = await request(app)
      .get("/api/conversations?type=group")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    // Every item in the response must be a group
    res.body.forEach((conv) => expect(conv.type).toBe("group"));
    // Prisma was called with the group type filter
    expect(prismaMock.conversations.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ type: "group" }),
      }),
    );
  });

  it("200 – ?type=direct returns only direct conversations", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([]);
    prismaMock.messages.groupBy.mockResolvedValue([]);

    const res = await request(app)
      .get("/api/conversations?type=direct")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    expect(prismaMock.conversations.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ type: "direct" }),
      }),
    );
  });

  it("200 – ?type=all (default) passes no type filter", async () => {
    prismaMock.conversations.findMany.mockResolvedValue([]);
    prismaMock.messages.groupBy.mockResolvedValue([]);

    const res = await request(app)
      .get("/api/conversations?type=all")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(200);
    // The where clause should NOT contain a `type` key when type=all
    const callArg = prismaMock.conversations.findMany.mock.calls[0][0];
    expect(callArg.where).not.toHaveProperty("type");
  });

  it("400 – invalid type value is rejected", async () => {
    const res = await request(app)
      .get("/api/conversations?type=invalid")
      .set("Authorization", makeAuthHeader());

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe("Group messaging via /api/conversations/:id/messages", () => {
  it("201 – member can send a message to a group", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: GROUP_ID,
      type: "group",
      only_admin_send_messages: false,
      conversation_members: mockGroupConversation.conversation_members,
    });
    prismaMock.messages.create.mockResolvedValue({
      id: MSG_ID,
      conversation_id: GROUP_ID,
      sender_id: TEST_USER.id,
      content: "Hey crew!",
      created_at: new Date(),
      is_read: false,
      media_urls: [],
    });

    const res = await request(app)
      .post(`/api/conversations/${GROUP_ID}/messages`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Hey crew!" });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.message.content).toBe("Hey crew!");
  });

  it("403 – non-member cannot send a message to the group", async () => {
    prismaMock.conversations.findUnique.mockResolvedValue({
      id: GROUP_ID,
      type: "group",
      // Alice is NOT in this group
      conversation_members: [{ user_id: TEST_USER_B.id }],
    });

    const res = await request(app)
      .post(`/api/conversations/${GROUP_ID}/messages`)
      .set("Authorization", makeAuthHeader())
      .send({ content: "Intrude!" });

    expect(res.status).toBe(403);
  });
});
