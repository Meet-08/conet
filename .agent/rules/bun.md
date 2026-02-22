---
trigger: model_decision
description: This should apply when working on conet_backend/ directory no matter what prompt is given
---

# Bun + Express + Prisma – Backend Best‑Practice Guidelines

This document defines **how an agent must think and act** when working on this Bun + Express backend using Prisma.

This is not a framework comparison, not a tutorial, and not optional advice. It is a discipline document meant to prevent architectural drift, logic leaks, and controller hell.

---

## 1. Core Backend Principles (Read Twice)

1. **HTTP is a delivery mechanism, not your business layer**
2. **Controllers orchestrate, services decide, Prisma persists**
3. **Every request has a single responsibility**
4. **Validation, auth, business logic, persistence are never mixed**

If a file does more than one of these, it is wrong.

---

## 2. Mandatory Mental Model (Sequential Thinking)

For every backend change, the agent must follow this order:

1. What is the **business intent**?
2. What is the **HTTP contract**?
3. What is the **domain rule**?
4. What is the **data mutation/query**?
5. What are the **failure modes**?

Skipping steps produces bugs that look like features.

---

## 3. Folder Responsibility Rules (Based on This Repo)

### `server.js`

Purpose:

- App bootstrap only

Allowed:

- Express app creation
- Global middleware registration
- Route mounting
- Server start

Forbidden:

- Business logic
- Route definitions
- Prisma access

---

### `routes/`

Purpose:

- HTTP wiring only

Rules:

- One route file per resource
- Routes map 1:1 to controller functions
- No logic beyond middleware composition

Example responsibility:

- Method + path + middleware + controller

---

### `controllers/`

Purpose:

- Request/response orchestration

Rules:

- Controllers do NOT contain business rules
- Controllers do NOT call Prisma directly
- Controllers translate:
  - req → input DTO
  - result → HTTP response

A controller should be boring enough to scan in 30 seconds.

---

### `middleware/`

Purpose:

- Cross‑cutting concerns

Rules:

- Auth, validation, error handling only
- Middleware must be composable
- Middleware must be side‑effect predictable

Examples:

- `validateSupabaseToken`
- request validation
- centralized error handling

---

### `config/`

Purpose:

- Infrastructure setup

Rules:

- Prisma client initialization only
- DB config only
- No environment logic scattered elsewhere

`prisma.js` is the **only place** Prisma client is created.

---

### `prisma/`

Purpose:

- Schema is the single source of truth

Rules:

- No logic
- No comments explaining business behavior
- Schema mirrors data, not API

Migrations are intentional, not accidental.

---

## 4. Introduce a Service Layer (Strongly Required)

Current structure is missing a **services/** layer.

Add:

```
services/
 └── postService.js
```

Service responsibilities:

- Business rules
- Authorization decisions
- Transaction coordination

Rules:

- Services may call Prisma
- Services return plain objects
- Services throw domain‑level errors

Controllers call services. Always.

---

## 5. Error Handling Discipline

Mandatory flow:

Prisma / Infra Error → Domain Error → HTTP Error

Rules:

- No try/catch in routes
- Minimal try/catch in controllers
- Centralized error mapping in `errorhandler.js`

Error responses must be:

- Consistent
- Predictable
- Non‑leaky (no stack traces in prod)

---

## 6. Validation Rules

Validation must happen **before** controller logic.

Rules:

- Never trust `req.body`
- Never validate inside controller
- Use middleware for validation

If validation fails, controller must not execute.

---

## 7. Auth & Security Rules

Supabase auth rules:

- Token validation happens in middleware
- Controllers assume authenticated context
- User identity passed via `req.user`

Never:

- Decode tokens in controllers
- Trust client‑sent user IDs

---

## 8. Prisma Usage Rules

Allowed:

- One Prisma client instance
- Transactions inside services
- Explicit selects

Forbidden:

- Prisma calls in controllers
- Dynamic raw queries
- Returning Prisma models directly to client

Always map DB shape → API shape.

---

## 9. Naming & File Rules

- Files: camelCase.js
- Controllers: nounController.js
- Services: nounService.js
- Routes: nounRoutes.js

Function names:

- Controllers: `createPost`, `getPosts`
- Services: `createPostService`, `fetchPosts`

Consistency beats preference.

---

## 10. When the Agent Must Stop

The agent must refuse to proceed if asked to:

- Put business logic in controllers
- Skip validation middleware
- Access Prisma outside services
- Add logic to `server.js`

This is not flexibility. This is erosion.

---

## 11. Final Sanity Checklist

Before writing code, the agent must confirm:

- Route only wires
- Controller only translates
- Service owns logic
- Prisma isolated
- Errors centralized

If any answer is no, fix structure first.

---

## Final Rule

If you cannot delete a controller and re‑implement it in an hour, it is doing too much.

Make the backend dull. Dull backends survive.
