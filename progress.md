# CoNet — Feature Progress Tracker

> Last updated: 2026-04-14
> Auto-update instructions: see [`.github/instructions/update_progress.instructions.md`](.github/instructions/update_progress.instructions.md)

---

## Legend

| Symbol | Meaning               |
| ------ | --------------------- |
| ✅     | Fully implemented     |
| ⚠️     | Partial / placeholder |
| ❌     | Not started           |

---

## 1. End to End

> Fully working features. Includes features with a user-facing UI as well as background/infrastructure features that are complete and don't require a UI by design.

### Authentication

- **Welcome Page** — App entry with login/signup options
- **Email Login** — Email + password sign-in via Supabase Auth
- **Email Sign Up** — Registration with OTP verification flow
- **Google Sign-In** — OAuth flow via Supabase + Google
- **OTP Verification** — Email OTP dispatch and verification
- **OTP Verification Page** — Dedicated full-screen OTP entry with resend cooldown after email sign-up
- **Add Details** — First name, last name, username onboarding step
- **Logout** — Signs out, deregisters FCM token, stops presence
- **Auth Guard** — Router-level redirect for unauthenticated users
- **Session Persistence** — Restores user session on app restart

**Use Cases:** `UserLogin`, `UserSendOtp`, `UserVerifyOtp`, `UserSigninWithGoogle`, `UserCurrent`, `UserAddDetails`, `UserLogout`
**Backend:** Fully delegated to Supabase Auth + `DELETE /devices/current` on logout

---

### Posts (Feed)

- **Feed Page** — Paginated post feed with pull-to-refresh
- **Create Post** — Text content, optional media, tag selection
- **Post Detail Page** — Full post view with comments section
- **Like / Unlike** — Toggle like with live count update
- **Comment** — Add, edit, delete comments on a post
- **Real-time Comments** — Live comment stream via Supabase Realtime
- **Delete Post** — Delete own posts
- **Bookmark (Local)** — Save/unsave posts locally (no backend persistence)
- **Liked Posts** — View all posts liked by the current user
- **Typed Media Rendering** — Post card renders image (tap-to-view), muted autoplay video (tap to unmute), audio banner controls, and per-media download option
- **Create Post Mixed Media Picker** — Post creation accepts mixed media attachments (image/video/audio/doc), shows typed previews, and supports per-item removal
- **Create Post Rich Text Controls** — Composer formatting buttons now apply Quill styles (bold, italic, bullet list) while preserving existing layout

**Use Cases:** `PostCreate`, `PostDelete`, `PostGetPosts`, `PostGetUserPosts`, `PostGetPost`, `PostGetPostComments`, `PostWatchPostComments`, `PostToggleLike`, `PostComment`, `PostBookmark`, `PostRemoveBookmark`, `PostGetBookmarks`, `PostGetLikedPosts`, `PostIsBookmarked`
**Backend Endpoints:** `GET/POST /posts`, `GET/PUT/DELETE /posts/:id`, `GET /posts/liked`, `GET /posts/user/:userId`, `GET /posts/:id/comments`, `PUT /posts/like/:id`, `POST /posts/comment/:id`, `PUT/DELETE /posts/:postId/comment/:commentId`

---

### Profile

- **Profile Page** — Own profile with Posts / Liked / Saved tabs
- **User Profile Page** — Other user's public profile with Follow/Unfollow
- **Edit Personal Info** — First name, last name, username, gender, date of birth
- **Edit About Me** — Bio / description
- **Edit Academic Info** — University, major, year of study
- **Edit Interests** — Multi-select interest tags
- **Edit Social Links** — GitHub, LinkedIn, Twitter, etc.
- **Edit Profile Pictures** — Avatar and banner image upload to Supabase Storage
- **Follow / Unfollow** — Follow other users with follower/following counts
- **Settings Page** — Logout entry point + settings scaffold

**Use Cases:** `ProfileGetUser`, `ProfileUpdatePersonalInfo`, `ProfileUpdateAboutMe`, `ProfileUpdateInterests`, `ProfileUpdateAcademicInfo`, `ProfileUpdateSocialLinks`, `ProfileUpdatePictures`, `ProfileFollowUser`, `ProfileUnfollowUser`
**Backend Endpoints:** `GET /profile/:uid`, `PUT /profile/about-me`, `PUT /profile/academic-info`, `PUT /profile/interests`, `PUT /profile/personal-info`, `PUT /profile/pictures`, `PUT /profile/social-links`, `POST/DELETE /profile/:uid/follow`
**Implementation Notes:**

- Academic Info Form (`AcademicInfoForm` in `core/widgets/academic_info_form.dart`) extracted as a reusable widget and is now used across both **Add Details (Auth)** onboarding and **Edit Academic Info (Profile)** screens with mode-based label rendering.

---

### Messaging (DM + Groups)

- **Conversations List** — All DMs and group chats with unread badges
- **Chat Page** — Real-time message thread with full history
- **Send Message** — Text messages + file/image attachments
- **Image Viewer** — Full-screen image viewer from chat
- **Online Indicator** — Shows if recipient is currently online
- **Mark as Read** — Auto-marks messages as read with cooldown
- **Real-time Messages** — Live message stream via Supabase Realtime
- **Real-time Conversation Updates** — Conversation list updates live
- **New Message Sheet** — User search to start a new DM
- **Create Group** — Create group chat with selected members
- **Group Management** — Rename group, change group image (admin only)
- **Delete Group** — Admin can dissolve the group
- **Group Members** — View, add, and remove group members
- **Group Details Page** — Group profile screen with live member list, add-member search, and settings entry points
- **Group Image Upload** — Create-group and group-details flows now support image picker upload before persisting group metadata
- **Group Permissions Dialog** — Group permissions are shown in a dedicated modal with read-only status toggles sourced from backend role/creator data

**Use Cases:** `MessageCreateConversation`, `MessageGetConversations`, `MessageGetMessages`, `MessageSendMessage`, `MessageMarkAsRead`, `MessageWatchMessages`, `MessageWatchConversationUpdates`, `MessageSearchUsers`, `MessageCreateGroup`, `MessageUpdateGroup`, `MessageDeleteGroup`, `MessageGetGroupMembers`, `MessageAddGroupMember`, `MessageRemoveGroupMember`
**Backend Endpoints:** `POST/GET /conversations`, `GET/POST /conversations/:id/messages`, `POST /conversations/:id/mark_as_read`, `GET /conversations/search_users`, `POST/PATCH/DELETE /groups/:id`, `GET/POST /groups/:id/members`, `DELETE /groups/:id/members/:userId`

**Implementation Notes:**

- **Conversation Fetching** — Removed `last_message_id IS NOT NULL` restriction from `getConversationsService` so empty group conversations (no messages yet) are now fetchable. Mapping functions already handle null messages gracefully with optional chaining.
- **Test Coverage** — Added unit test for conversations without messages to ensure empty groups appear in conversation list.

---

### Notifications

- **Notification Page** — Paginated list of all notifications with load-more
- **Notification Badge** — Unseen count badge on bottom nav icon
- **Real-time Notifications** — New notification stream via Supabase Realtime
- **Mark All as Seen** — Clears unseen count
- **Push Notifications (FCM)** — Firebase Cloud Messaging delivery for likes, comments, follows, new messages
- **Notification Types** — Like, comment, follow, message — each with appropriate icon and copy

**Use Cases:** `GetNotificationsUsecase`, `MarkAllAsSeenUsecase`, `WatchNotificationsUsecase`
**Backend Endpoints:** `GET /notifications`, `POST /notifications/mark-seen`
**BullMQ Worker:** `notificationWorker.js` — processes queued FCM push jobs via Firebase Admin SDK

---

### Event Detail (Discover)

- **Event Detail Page** — Dynamic event detail UI driven by `GET /events/:id` (header, schedule, prizes, organizer, eligibility, FAQs)
- **Event Registration CTA** — Register button wired to backend registration flow and updates event state after success
- **Save Event** — Bookmark action on event detail saves published events with backend persistence and success feedback
- **View Ticket Page** — Dedicated ticket UI that fetches registration identifiers and renders QR payload for event check-in

**Use Cases:** `EventGetById`, `EventRegister`, `EventSave`
**Backend Endpoints:** `GET /events/:id`, `POST /events/:id/register`, `POST /events/:id/save`

---

### Events Feed (Discover + Campus)

- **Events Page** — Published events feed with pull-to-refresh and infinite scroll
- **Event Search Page** — Dedicated search screen with debounced query over published events and quick access to event details
- **Event Dashboard Page** — Organizer-style dashboard with filter tabs (`All`, `Active`, `Upcoming`, `Past`, `Drafts`) backed by live `/events/organized` data
- **Attendance QR Scanner** — Organizer/co-host scans attendee QR using mobile camera and marks attendance via backend
- **Event Attendees Page** — Organizer/co-host views individual attendee list or team roster with status filters (`All`, `Registered`, `Attended`, `Cancelled`)
- **Participants XLS Export** — Attendees page downloads and opens event participation XLS with team/individual columns and custom-field responses (excluding image fields), with re-download support
- **From Your Campus Section** — Reuses event cards to highlight campus-facing event list on top
- **Discover Section** — Lists discoverable events with filter affordance and empty-state handling
- **My Events Entry** — App bar quick action routes to `/my-events`
- **My Events Page** — Redesigned chip-based list (`Upcoming`, `Past`, `Saved`) backed by filtered API fetching with pagination

**Use Cases:** `EventGetPublishedEvents`, `EventGetMyEvents`, `EventGetMyOrganizedEvents`, `EventGetAttendees`, `EventMarkAttendance`
**Backend Endpoints:** `GET /events`, `GET /events/my`, `GET /events/organized`, `GET /events/:id/attendees`, `GET /events/:id/participants/export`, `POST /events/:id/attend`

---

### Event Creation & Registration

- **Create Event Wizard** — Organizer creates draft/published events with timeline, prizes, FAQs, co-hosts, and validation
- **Registration Configuration Builder** — Organizer configures registration deadline, team participation constraints, paid/free mode, UPI ID, and dynamic custom registration fields
- **Custom Field Reference Images** — Organizer can add image-type custom fields; images upload to Supabase under `event/custom_field/{field_name}` and are stored as URLs in event custom_fields
- **Organizer Conversation Linking** — Organizer can auto-create and attach a new organizer/co-host group conversation during event submission
- **Registration Form Page** — Event detail registration opens a dedicated dynamic page with required custom field validation and payload mapping, while image-type fields are read-only organizer content
- **Team Registration UI** — Team events collect captain enrollment/semester/branch, enforce team-size limits, and allow searchable optional team member selection
- **Paid Registration QR Flow** — Paid events generate UPI QR with per-member amount and team-size-based total, plus transaction ID and payment proof upload support
- **Organizer/Cohost Register Participant Page** — Organizer/co-host can select a participant and submit individual/team registration on their behalf with dynamic custom fields

**Use Cases:** `EventPublish`, `EventSaveDraft`, `EventRegister`, `EventRegisterParticipant`, `MessageCreateGroup`, `MessageSearchUsers`
**Backend Endpoints:** `POST /events`, `PATCH /events/:id/publish`, `POST /events/:id/register`, `POST /events/:id/register-participant`, `POST /groups`

---

### Device Management (FCM Token)

> Background/infrastructure — no UI required by design.

- **Register Device** — Registers FCM token + platform + device name on login
- **Deregister Device** — Removes FCM token on logout to stop push delivery

**Use Cases:** `RegisterDeviceUseCase`, `RemoveDeviceUseCase`
**Backend Endpoints:** `POST /devices/register`, `DELETE /devices/current`

---

### Presence Service

> Background/infrastructure — no UI required by design.

- **Online Tracking** — Tracks which users are currently online via Supabase Realtime presence channels
- **Online Indicator** — Exposes online status to the chat UI via `PresenceCubit` (shown as a dot in `ChatAppBar`)
- **Start / Stop Presence** — Joins presence channel on login, leaves on logout

---

### Push Notification Worker

> Background/infrastructure — no UI required by design.

- **Job Queue Processing** — BullMQ worker (`notificationWorker.js`) processes queued push jobs from Redis
- **FCM Delivery** — Looks up active device tokens and sends payloads via Firebase Admin SDK
- **Triggered By** — Post likes, post comments, follow events, new chat messages

---

### API Auth Infrastructure

> Background/infrastructure — no UI required by design.

- **Token Interceptor** — Dio interceptor that auto-attaches Supabase JWT `Authorization` header to every API request
- **Backend JWT Middleware** — `validateSupabaseToken.js` verifies Supabase JWT on all protected backend routes
- **Request Logger** — `requestLogger.js` structured request/response logging to `logs/` via Winston

---

### Design Token Theme System

> Background/infrastructure — no UI required by design.

- **Core Token Palette** — Brand, neutral (light/dark), accent, status, and backdrop palettes defined under `lib/core/theme`
- **Semantic Color Layer** — Text, icon, border, background, surface, state, brand, inverse, and on-\* token mappings with light/dark variants
- **Typography + Layout Tokens** — Font, type styles, spacing, radius, and elevation scales centralized for reuse
- **App Theme Wiring** — `MaterialApp` now uses shared token-driven `light` and `dark` themes with system mode support

## 2. Functionality Only (No UI)

> Backend routes, domain use cases, and/or data layer are implemented — but the Flutter UI screens have **not been built yet**.

### Events

- **Update Event** — Organizer can edit all event fields, activity, and prizes (wholesale replace)
- **Cancel Event** — Organizer cancels a published or draft event
- **Get Event** — Fetch a single event; non-organizers can only see published events
- **Registration Ticket Info** — Registered user fetches ticket payload data for QR generation
- **Attend Event (Scan Ticket)** — Organizer/co-host scans ticket payload and marks attendee as attended with live attendance summary
- **Discover Events** — Paginated list of published events with category, location type, date range, and text search filters
- **My Organized Events** — Organizer retrieves their own events, optionally filtered by status (draft/published/cancelled)
- **Add Co-host** — Organizer adds another user as a co-host
- **Remove Co-host** — Organizer removes a co-host
- **List Co-hosts** — Retrieve all co-hosts for an event
- **Organizer/Cohost Participant Registration** — Organizer or co-host can register another user/team to the event on their behalf

**Use Cases:** `EventGetById`, `EventGetPublishedEvents`, `EventGetMyEvents`, `EventGetRegistrationInfo`, `EventMarkAttendance`
**Backend Endpoints:** `GET /events`, `GET /events/my`, `POST /events`, `GET /events/organized`, `GET /events/:id`, `POST /events/:id/register`, `POST /events/:id/register-participant`, `GET /events/:id/registration-info`, `POST /events/:id/attend`, `PUT /events/:id`, `PATCH /events/:id/publish`, `PATCH /events/:id/cancel`, `GET /events/:id/cohosts`, `POST /events/:id/cohosts`, `DELETE /events/:id/cohosts/:userId`

---

### Payments

- **Organizer Account Setup** — Organizer provides bank account details (account holder, account number, IFSC, PAN)
- **Initiate Payment** — Create Razorpay order for event registration payment
- **Registration Rollback on Failure** — Cancels event registration when payment initiation/checkout fails or user cancels payment
- **Payment Verification Webhook** — Verifies Razorpay webhook signature and updates payment status from payment events
- **KYC Status Webhook** — Verifies Razorpay webhook signature and updates organizer account verification status
- **Payment Status Tracking** — Tracks payment status in database (pending/completed/failed)

**Use Cases:** `PaymentCreateOrganizerAccount`, `PaymentGetOrganizerAccount`, `PaymentInitiate`, `RevertRegistration`, `PaymentVerifyWebhook`
**Backend Endpoints:** `POST /payments/organizer-account`, `GET /payments/organizer-account`, `POST /payments/:registrationId/initiate`, `POST /payments/:registrationId/revert`, `POST /payments/webhook/payment-verification`, `POST /payments/webhook/kyc-status`, `POST /payments/webhook/verify`

**Implementation Notes:**

- Organizer account creation triggers Razorpay linked account creation (TODO)
- Payment initiation creates order with Razorpay and stores order_id (TODO: call Razorpay API)
- Payment-failed webhooks and client failure callbacks now revert registration to cancelled for unpaid attempts
- Webhook handlers validate signatures using `RAZORPAY_WEBHOOK_SECRET` and process idempotent updates for payment/KYC events
- Flutter event registration launches Razorpay checkout and auto-rolls back pending registrations on failure

---

## 3. UI Only (No Functionality)

> Flutter screens/widgets exist but have no use cases, no bloc/data wiring, and no backend routes. All data shown is static or hardcoded.

### Explore

- **ExplorePage** — Layout with search bar, "Trending Topics" chips, and post cards
- **ExploreAppBar** — Search bar widget (non-functional)
- **TrendingTopics / TrendingTopicChip** — Horizontal scrollable chips (hardcoded labels)
- **ExplorePostCard** — Post card with hardcoded static user ("David Park") and content

> ⚠️ No use cases, no repository, no bloc, no backend routes. Pure placeholder shell.

---

## Architecture Overview

| Layer              | Technology                                                      |
| ------------------ | --------------------------------------------------------------- |
| Frontend           | Flutter (Clean Architecture — feature/data/domain/presentation) |
| State Management   | BLoC + Cubit                                                    |
| Navigation         | GoRouter with auth-guard                                        |
| Backend            | Node.js + Bun runtime                                           |
| Database           | PostgreSQL via Prisma ORM                                       |
| Auth               | Supabase Auth                                                   |
| Real-time          | Supabase Realtime (presence + messaging + notifications)        |
| File Storage       | Supabase Storage                                                |
| Push Notifications | Firebase Cloud Messaging (FCM) via Firebase Admin SDK           |
| Job Queue          | BullMQ (Redis-backed)                                           |
| Local Storage      | via `Hive` (bookmarks)                                          |
