# Trainer Application & Verification — Implementation Plan

> **For agentic workers:** Implement task-by-task. Keep all changes additive until the new application flow is fully wired. The current worktree is dirty; do not revert unrelated edits.

**Goal:** Replace the current code-first trainer activation with an enterprise-grade application review flow. Trainer applicants submit an application, a protected admin review channel opens, admins verify the extended certificate of conduct by sight only, and only then an approval-bound activation code can make the user a verified trainer.

**Spec reference:** `docs/superpowers/specs/2026-04-28-trainer-application-review-design.md`

---

## Current Implementation Inventory

### Existing pieces to keep

| File / Area | Keep because |
|---|---|
| `supabase/migrations/20260427_trainer_network.sql` | Contains useful Discovery foundation: `trainer_profiles`, location privacy, nearby search, discovery requests |
| `lib/features/trainer/presentation/screens/trainer_discovery_screen.dart` | Client-side trainer search remains valid |
| `lib/features/trainer/presentation/screens/trainer_public_profile_screen.dart` | Public active trainer view remains valid |
| `lib/features/trainer/presentation/screens/trainer_requests_screen.dart` | Handles client requests to verified trainers, not trainer applications |
| `trainer_client_relationships` flow | Still needed after trainers are verified |

### Existing pieces to replace

| File / Area | Replace with |
|---|---|
| `profile_screen.dart` code dialog under "Trainer werden" | Trainer application intro/form/status |
| `admin_panel_screen.dart` free "Trainer-Codes" tab + FAB | Application review list/detail + approval-bound code generation |
| `create-trainer-code` | Approval-bound code creation only |
| `activate-trainer` | Application-bound activation only |
| `trainer_profile_setup_screen.dart` | Application form or later verified trainer profile editor |
| `trainer_profile_pending_screen.dart` | Application status screen |
| `pendingTrainersProvider` review logic | `trainerApplicationsForReviewProvider` |
| `admin_approve_trainer` RPC | `approve_trainer_application` RPC |

---

## Task 1: Add Database Foundation

**Files:**
- Create: `supabase/migrations/20260428_trainer_applications.sql`

- [ ] Create `trainer_applications`
- [ ] Create `trainer_application_audit_events`
- [ ] Extend `trainer_invite_codes` with `trainer_application_id` and `purpose`
- [ ] Extend `chat_channels` to support `application_review`
- [ ] Add indexes and constraints
- [ ] Add RLS policies
- [ ] Add helper/audit function

Important constraints:

- No uploaded or stored certificate files.
- Store only `background_check_verified_at` and `background_check_verified_by`.
- One open application per user.
- Activation code for production trainer approval must reference an approved application.

---

## Task 2: Add Application RPCs

**Files:**
- Modify/Create inside `supabase/migrations/20260428_trainer_applications.sql`

- [ ] `submit_trainer_application(...)`
- [ ] `get_own_trainer_application()`
- [ ] `get_trainer_applications_for_review()`
- [ ] `mark_background_check_seen(p_application_id uuid)`
- [ ] `set_trainer_application_status(p_application_id uuid, p_status text, p_reason text default null)`
- [ ] `approve_trainer_application(p_application_id uuid)`

`submit_trainer_application` must:

- validate current user
- prevent duplicate open application
- create application
- create `application_review` chat channel
- add applicant and admins/reviewer as members
- write audit event

`approve_trainer_application` must:

- require admin
- require background check sight verification
- set application approved
- generate an activation code with `purpose = 'trainer_application_approval'`
- link code to application
- write audit event

---

## Task 3: Harden Activation Functions

**Files:**
- Modify: `supabase/functions/activate-trainer/index.ts`
- Modify or deprecate: `supabase/functions/create-trainer-code/index.ts`

- [ ] `activate-trainer` requires `trainer_application_id`
- [ ] Code must belong to current user through the approved application
- [ ] Code must be unused and unexpired
- [ ] Activation sets `profiles.role = 'trainer'`
- [ ] Activation creates/updates `trainer_profiles.status = 'active'`
- [ ] Activation creates/updates `trainer_profile_private`
- [ ] Activation marks code used
- [ ] Activation writes audit event
- [ ] `create-trainer-code` no longer creates free-floating production codes

Preferred implementation:

- Move activation into a SECURITY DEFINER SQL RPC.
- Let Edge Function become a thin authenticated wrapper.

---

## Task 4: Add Dart Models and Repository

**Files:**
- Create: `lib/features/trainer/domain/models/trainer_application.dart`
- Create: `lib/features/trainer/domain/models/trainer_application_status.dart` or enum in same file
- Create/Modify: `lib/features/trainer/domain/repositories/trainer_application_repository.dart`
- Create: `lib/features/trainer/data/repositories/supabase_trainer_application_repository.dart`
- Create: tests under `test/features/trainer/domain/models/`

- [ ] Model parses application status, timestamps, review channel id, background check fields
- [ ] Repository exposes applicant and admin methods
- [ ] Unit tests cover JSON parsing and status helpers

---

## Task 5: Add Riverpod Providers

**Files:**
- Create: `lib/features/trainer/presentation/providers/trainer_application_provider.dart`

- [ ] `ownTrainerApplicationProvider`
- [ ] `submitTrainerApplicationProvider` or notifier method
- [ ] `trainerApplicationsForReviewProvider`
- [ ] `markBackgroundCheckSeenProvider` or notifier method
- [ ] `approveTrainerApplicationProvider` or notifier method
- [ ] `rejectTrainerApplicationProvider` / `needsMoreInfo`

Provider invalidation must refresh:

- applicant status after submit
- admin list after status changes
- admin detail after messages or review actions

---

## Task 6: Build Applicant UX

**Files:**
- Create: `lib/features/trainer/presentation/screens/trainer_application_intro_screen.dart`
- Create: `lib/features/trainer/presentation/screens/trainer_application_form_screen.dart`
- Create: `lib/features/trainer/presentation/screens/trainer_application_status_screen.dart`
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`
- Modify: `lib/core/navigation/app_router.dart`

- [ ] "Trainer werden" opens intro, not code dialog
- [ ] Intro clearly explains certificate sight-check and no storage
- [ ] Form submits application
- [ ] Successful submit opens status screen
- [ ] Status screen links to review channel
- [ ] Existing `/trainer/profile-setup` redirects or becomes legacy-safe
- [ ] Existing `/trainer/profile-pending` redirects or becomes legacy-safe

---

## Task 7: Build Admin Review UX

**Files:**
- Modify: `lib/features/admin/presentation/screens/admin_panel_screen.dart`
- Modify: `lib/features/admin/presentation/providers/admin_provider.dart`
- Create: `lib/features/admin/presentation/screens/admin_trainer_application_detail_screen.dart` if detail is separated

- [ ] Replace visible free trainer-code creation with application review
- [ ] Add list of submitted/in-review/needs-info applications
- [ ] Show applicant data and review status
- [ ] Show action: mark certificate sight-check complete
- [ ] Show action: request more information
- [ ] Show action: reject
- [ ] Show action: approve and generate activation code
- [ ] Show generated code only after approval
- [ ] Add audit-friendly labels

Do not add document upload UI.

---

## Task 8: Review Channel Integration

**Files:**
- Modify: chat models if needed
- Modify: `lib/features/chat/...`
- Modify: `supabase/migrations/20260428_trainer_applications.sql`

- [ ] Support `ChannelType.applicationReview`
- [ ] Display review channels separately from trainer-client DMs where practical
- [ ] Allow applicant/admin messages in review channel
- [ ] Keep review channels out of normal trainer-client assumptions
- [ ] Ensure `get_channel_list` includes application review channels for members

Important: Do not treat review-channel admins as trainers or moderators for trainer-client features.

---

## Task 9: Discovery and Trainer Profile Compatibility

**Files:**
- Modify: `lib/features/trainer/data/repositories/supabase_trainer_profile_repository.dart`
- Modify: `lib/features/trainer/presentation/providers/trainer_discovery_provider.dart`
- Modify: `supabase/migrations/20260427_trainer_network.sql` only via new corrective migration

- [ ] Keep `find_trainers_nearby` active-only
- [ ] Keep discovery request flow unchanged for active trainers
- [ ] Ensure application approval creates a valid `trainer_profiles` row
- [ ] Remove direct admin approval of pending `trainer_profiles` from UI
- [ ] Preserve existing active trainers during migration

---

## Task 10: Tests and Verification

- [ ] Model tests for `TrainerApplication`
- [ ] RPC smoke SQL for submit/review/approve/activate
- [ ] Flutter analyze relevant files
- [ ] Widget smoke for applicant flow
- [ ] Manual QA:
  - normal user submits application
  - review channel appears
  - admin marks certificate seen
  - admin approves
  - applicant activates code
  - trainer appears in discovery
  - certificate file is never uploaded/stored

---

## Cleanup Rules

Only after the new flow works end-to-end:

- [ ] Remove legacy free code FAB
- [ ] Remove or hide direct code activation from normal profile
- [ ] Deprecate `admin_approve_trainer`
- [ ] Deprecate `get_pending_trainers`
- [ ] Update old trainer discovery spec to point to the new application spec
- [ ] Update QA docs
