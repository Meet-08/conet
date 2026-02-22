---
trigger: model_decision
description: This should apply when working on conet_app/ directory no matter what prompt is given
---

# Flutter Clean Architecture – Sequential Thinking & System Prompt Guidelines

This document is a **system-level guideline for an agent** working on this Flutter codebase. Its purpose is to enforce **sequential reasoning**, **clean architecture discipline**, and **predictable decision-making** while extending or modifying the app.

This is not a tutorial. It is a rulebook.

---

## 1. Core Principles (Non‑Negotiable)

1. **Think in layers, act in layers**
   - Presentation → Domain → Data → External systems
   - Never skip a layer.

2. **Dependencies only point inward**
   - Presentation depends on Domain
   - Domain depends on nothing
   - Data depends on Domain

3. **One change = one feature boundary**
   - Do not mix auth logic with posts, messages, or profile
   - If unsure where code belongs, it probably does not belong there

4. **Predictability over cleverness**
   - Explicit > implicit
   - Boring code is correct code

---

## 2. How the Agent Must Think (Sequentially)

For _any_ task, the agent must follow this exact mental pipeline.

### Step 1: Identify the Feature Boundary

Ask:

- Which feature folder owns this behavior?
- Is this `core` or a `feature/*`?

Rules:

- Cross-feature logic goes into `core`
- Business intent always maps to a single feature

---

### Step 2: Classify the Change Type

The agent must explicitly classify the task as one of:

- UI-only change
- State management change
- New business rule
- New data source / API change
- Cross-cutting concern (auth, routing, error handling)

This classification decides **which layers are allowed to change**.

---

### Step 3: Start From the Domain (Always)

Before touching UI or API code, the agent must answer:

- What is the **use case**?
- What is the **entity** involved?
- What is the **repository contract**?

Rules:

- If a use case does not exist, create it
- If logic lives in Bloc only, it is wrong

Domain checklist:

- Use case name = verb + noun
- No Flutter imports
- No Dio, Supabase, JSON, or UI logic

---

### Step 4: Validate the Repository Contract

For any data interaction:

- Repository interface must exist in `domain/repository`
- Return types must be entities or primitives
- Errors must be mapped to `AppFailure`

If the repository method does not exist:

1. Define it in domain
2. Implement it in data
3. Inject it properly

Never reverse this order.

---

### Step 5: Implement Data Layer Last

Data layer rules:

- Implements domain contracts only
- Converts models ↔ entities
- Handles exceptions and maps them to failures

Explicit structure:

- data_source → repository_impl → domain

Forbidden:

- UI imports
- Bloc imports
- Business rules

---

### Step 6: Presentation Is a Consumer, Not an Owner

Presentation layer responsibilities:

- Dispatch events
- Render states
- Zero business decisions

Bloc rules:

- One Bloc per feature
- Events describe **intent**, not implementation
- States describe **facts**, not actions

UI rules:

- Widgets are dumb
- No async calls inside widgets
- No repository or use case access directly
- Use FontAwesome icons for all icons, no custom SVGs
- Always check core widgets and utils before adding anything

---

## 3. Folder‑Specific Rules Based on This Repo

### `core/`

Purpose:

- App-wide concerns only

Allowed:

- API clients (Dio)
- Interceptors
- Global cubits (AppUserCubit)
- Routing
- Shared widgets

Forbidden:

- Feature-specific logic
- Feature-specific models

---

### `feature/*/domain`

This is the **source of truth**.

Rules:

- Entities are immutable
- Use cases are single-purpose
- Repositories are abstract

If something feels reusable but depends on business meaning, it belongs here, not `core`.

---

### `feature/*/data`

Rules:

- Models mirror API / DB, not UI
- Data sources are dumb and specific
- Repository implementation coordinates data sources

Real-time sources must be isolated and wrapped by repositories.

---

### `feature/*/presentation`

Rules:

- Bloc handles orchestration only
- Pages wire blocs + widgets
- Widgets are reusable but feature-scoped

If a widget is reused across features, promote it to `core/widgets`.

---

## 4. Error Handling Discipline

Mandatory flow:

External error → Exception → Failure → State

Rules:

- No try/catch in UI
- No raw exceptions in Bloc states
- Every failure must be user-representable

---

## 5. Dependency Injection Rules

- All dependencies registered in `init_dependencies.dart`
- Features register their own dependencies
- No `new` keyword in Bloc or UI for repositories or data sources

Construction order:
DataSource → Repository → UseCase → Bloc

---

## 6. Naming & Consistency Rules

- Files: snake_case
- Classes: PascalCase
- Use cases: verb_noun.dart
- Events: FeatureActionEvent
- States: FeatureState

If naming feels ambiguous, stop and rename.

---

## 7. When the Agent Must Refuse to Proceed

The agent must stop and re-evaluate if:

- Asked to bypass domain layer
- Asked to put logic in UI
- Asked to reuse models as entities
- Asked to access API directly from Bloc

Refusal is correctness, not stubbornness.

---

## 8. Mental Checklist Before Writing Code

Before generating code, the agent must internally confirm:

- Feature boundary is clear
- Domain contract exists
- Data layer only implements contracts
- Presentation has no business logic
- Errors are mapped correctly

If any answer is no, fix design first.

---

## 9. Final Rule

If the change cannot be explained **layer by layer**, it is not clean architecture.

Make it boring. Make it obvious. Make it correct.
