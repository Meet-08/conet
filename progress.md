# CoNet — Feature Progress Tracker

> Last updated: 2026-03-28
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

**Use Cases:** `MessageCreateConversation`, `MessageGetConversations`, `MessageGetMessages`, `MessageSendMessage`, `MessageMarkAsRead`, `MessageWatchMessages`, `MessageWatchConversationUpdates`, `MessageSearchUsers`, `MessageCreateGroup`, `MessageUpdateGroup`, `MessageDeleteGroup`, `MessageGetGroupMembers`, `MessageAddGroupMember`, `MessageRemoveGroupMember`
**Backend Endpoints:** `POST/GET /conversations`, `GET/POST /conversations/:id/messages`, `POST /conversations/:id/mark_as_read`, `GET /conversations/search_users`, `POST/PATCH/DELETE /groups/:id`, `GET/POST /groups/:id/members`, `DELETE /groups/:id/members/:userId`

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
- **View Ticket Page** — Dedicated ticket UI that fetches registration identifiers and renders QR payload for event check-in

**Use Cases:** `EventGetById`, `EventRegister`
**Backend Endpoints:** `GET /events/:id`, `POST /events/:id/register`

---

### Events Feed (Discover + Campus)

- **Events Page** — Published events feed with pull-to-refresh and infinite scroll
- **Event Dashboard Page** — Organizer-style dashboard with filter tabs (`All`, `Active`, `Upcoming`, `Past`, `Drafts`) backed by live `/events/organized` data
- **Attendance QR Scanner** — Organizer/co-host scans attendee QR using mobile camera and marks attendance via backend
- **From Your Campus Section** — Reuses event cards to highlight campus-facing event list on top
- **Discover Section** — Lists discoverable events with filter affordance and empty-state handling
- **My Events Entry** — App bar quick action routes to `/my-events`
- **My Events Page** — Redesigned chip-based list (`Upcoming`, `Past`, `Saved`) backed by filtered API fetching with pagination

**Use Cases:** `EventGetPublishedEvents`, `EventGetMyEvents`, `EventGetMyOrganizedEvents`, `EventMarkAttendance`
**Backend Endpoints:** `GET /events`, `GET /events/my`, `GET /events/organized`, `POST /events/:id/attend`

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

## 2. Functionality Only (No UI)

> Backend routes, domain use cases, and/or data layer are implemented — but the Flutter UI screens have **not been built yet**.

### Events

- **Create Event** — Organizer can create a new event as draft or publish it immediately, with optional activity timeline and prizes
- **Update Event** — Organizer can edit all event fields, activity, and prizes (wholesale replace)
- **Publish Event** — Organizer promotes a draft event to published status
- **Cancel Event** — Organizer cancels a published or draft event
- **Get Event** — Fetch a single event; non-organizers can only see published events
- **Register Event** — Authenticated user registers for a published event and receives the latest full event view
- **Registration Ticket Info** — Registered user fetches ticket payload data for QR generation
- **Attend Event (Scan Ticket)** — Organizer/co-host scans ticket payload and marks attendee as attended with live attendance summary
- **Discover Events** — Paginated list of published events with category, location type, date range, and text search filters
- **My Organized Events** — Organizer retrieves their own events, optionally filtered by status (draft/published/cancelled)
- **Add Co-host** — Organizer adds another user as a co-host
- **Remove Co-host** — Organizer removes a co-host
- **List Co-hosts** — Retrieve all co-hosts for an event

**Use Cases:** `EventGetById`, `EventRegister`, `EventPublish`, `EventSaveDraft`, `EventGetPublishedEvents`, `EventGetMyEvents`, `EventGetRegistrationInfo`, `EventMarkAttendance`
**Backend Endpoints:** `GET /events`, `GET /events/my`, `POST /events`, `GET /events/organized`, `GET /events/:id`, `POST /events/:id/register`, `GET /events/:id/registration-info`, `POST /events/:id/attend`, `PUT /events/:id`, `PATCH /events/:id/publish`, `PATCH /events/:id/cancel`, `GET /events/:id/cohosts`, `POST /events/:id/cohosts`, `DELETE /events/:id/cohosts/:userId`

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
