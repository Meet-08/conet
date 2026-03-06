---
trigger: model_decision
---

# Instructions: Auto-Update progress.md

## Purpose

Whenever a new feature, screen, use case, backend endpoint, worker, middleware, or infrastructure component is added to this codebase, update [`progress.md`](../../progress.md) to reflect the current state.

## When to Apply These Instructions

Apply these instructions when:

- A new Flutter screen, page, or widget is created under `conet_app/lib/feature/`
- A new use case, repository, or data source is added in `conet_app/lib/feature/*/domain/` or `conet_app/lib/feature/*/data/`
- A new route, controller, or service is added in `conet_backend/routes/`, `conet_backend/controllers/`, or `conet_backend/services/`
- A new worker is added to `conet_backend/worker/`
- A new middleware is added to `conet_backend/middleware/`
- A new Prisma model is added to `conet_backend/prisma/schema.prisma`
- An existing placeholder/UI-only feature gains functionality
- A new top-level feature folder is created under `conet_app/lib/feature/`

---

## How to Update progress.md

### Step 1 — Classify the change

Determine which category the new/changed item belongs to:

| Category                       | Criteria                                                                                                                                                                                                                                       |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **End to End**                 | Fully working. This includes: (a) features with UI + domain + data + backend all wired together, AND (b) background/infrastructure features (workers, middleware, services, interceptors) that are complete and **don't need a UI by design**. |
| **Functionality Only (No UI)** | Backend routes, domain use cases, and/or data layer are implemented — but the **Flutter UI screens have not been built yet**. The UI is missing/pending, not absent by design.                                                                 |
| **UI Only (No Functionality)** | Flutter screens/widgets exist — but **no use cases, no bloc/data wiring, no backend routes**. Data is static or hardcoded.                                                                                                                     |

### Step 2 — Locate or create the section

- If the feature **already exists** in `progress.md`, find the correct section and add the new bullet or sub-item.
- If it is a **brand-new feature**, add a new `###` sub-section under the appropriate category (`## 1`, `## 2`, or `## 3`).

### Step 3 — Write the entry

Follow the existing format exactly:

```markdown
### Feature Name

- **Sub-feature or Screen Name** — one-line description of what it does
- **Another sub-feature** — description

**Use Cases:** `UseCaseName`, `AnotherUseCase` (omit line if none)
**Backend Endpoints:** `METHOD /path`, `METHOD /path` (omit line if none)
```

Rules:

- Each bullet = one user-visible capability or one infrastructure responsibility.
- Keep descriptions to a single line — explain the _what_, not the _how_.
- List use case class names in backticks.
- List backend endpoints as `METHOD /path` in backticks.
- If a feature moves from **UI Only** to **End to End** (got functionality added), remove it from Section 3 and add it to Section 1. Add a note: `> Promoted from UI Only on YYYY-MM-DD`.

### Step 4 — Update the "Last updated" date

Change the date at the top of `progress.md`:

```markdown
> Last updated: YYYY-MM-DD
```

Use today's date in `YYYY-MM-DD` format.

### Step 5 — Update the Architecture Overview or Database Models table if needed

- If a new technology or library was introduced (e.g., a new state management approach, a new DB adapter), add it to the **Architecture Overview** table.
- If a new Prisma model was added, append the model name (lowercase, snake_case) to the **Database Models** list.

---

## Example: Complete Infrastructure Feature (no UI needed)

If a new background worker or service is added that is complete and doesn't require a UI, place it under `## 1. End to End`:

```markdown
### Analytics Service

> Background/infrastructure — no UI required by design.

- **Event Tracking** — Sends anonymised usage events to the analytics backend
- **Session Tracking** — Starts/stops session on login/logout
```

---

## Example: Adding a New End-to-End Feature (Search)

If a Search feature is implemented with a `SearchPage`, `SearchBloc`, `SearchUseCase`, `SearchDataSource`, and `GET /search` endpoint, add:

```markdown
### Search

- **Search Page** — Full-text search across posts and users with debounced input
- **Search Results** — Paginated results grouped by posts and users
- **Recent Searches** — Locally stored recent search terms

**Use Cases:** `SearchQuery`, `SearchGetRecent`, `SearchClearRecent`
**Backend Endpoints:** `GET /search`
```

Place this under `## 1. End to End`.

---

## Example: Adding a UI-Only Screen (Story)

If a `StoryPage` is added with hardcoded data and no backend:

```markdown
### Stories

- **StoryPage** — Horizontally scrollable story bubbles (hardcoded users)
- **StoryViewer** — Full-screen story viewer with progress bar (static images)

> ⚠️ No use cases, no repository, no backend routes. Static placeholder only.
```

Place this under `## 3. UI Only (No Functionality)`.

---

## Example: Functionality Without UI Yet (backend done, UI pending)

If a backend search API and Flutter use cases are built but no Flutter search screen exists yet:

```markdown
### Search

- `GET /search` — Full-text search across posts and users

**Use Cases:** `SearchQuery`
**Backend Endpoints:** `GET /search`

> ⚠️ UI not built yet.
```

Place this under `## 2. Functionality Only (No UI)`.

---

---

## Example: Promoting a Feature from UI Only to End to End

If the Explore feature gets fully wired up:

1. Remove the entire `### Explore` block from `## 3. UI Only (No Functionality)`.
2. Add a new `### Explore` block under `## 1. End to End` with all details.
3. Optionally add a note: `> Promoted from UI Only on YYYY-MM-DD`.

---

## Do NOT

- Do not delete any existing entries without verifying the feature was intentionally removed.
- Do not change the three top-level section headings (`## 1`, `## 2`, `## 3`).
- Do not rewrite descriptions of existing features unless they changed.
- Do not add speculative or planned features — only document what is actually implemented in code.
