# Release Readiness Checklist

Scope: latest core flows (hands-free training, reminders v2, offline sync, dashboard progress UI).

## Automated checks

Run:

```bash
make release-readiness-mobile
```

For Phase-0 stabilization rounds (recommended):

```bash
make phase0-smoke
```

Expected:
- `flutter analyze` has no errors
- `test/features/progress/streak_logic_test.dart` passes
- Phase-0 prompt includes midnight/offline/restart smoke cases

## Manual smoke (must-pass)

1. Hands-free training
- Start training in `Routine (Hands-free)` mode.
- Screen stays on during the session.
- Audio/haptic feedback works according to selected feedback mode.
- Background music (e.g. Spotify/Apple Music) keeps playing.

2. Reminder behavior v2
- Enable reminders and set cadence (`Minimal` and `Ausgewogen`).
- Verify no duplicate reminder is scheduled.
- Verify "already trained today" pushes reminder to next day.
- Verify in-window reminder uses delayed scheduling.

3. Offline-first sync
- Put device in airplane mode.
- Complete training and change settings while offline.
- Go back online and verify queue drains to zero.
- Confirm data appears correctly after sync.

4. Dashboard consistency
- Complete a training and return to dashboard.
- Verify `Heute`, `Diese Woche`, `Streak`, and `Tag x/28` are consistent.
- Verify momentum bar and journey map match snapshot values.

## Go / No-Go

Go only if:
- automated checks pass
- no critical blockers in manual smoke
- no data loss or duplicate reminder behavior observed
