# Testing Guide for CoreJourney

## Overview

This guide shows you how to properly test your app with different training states and scenarios.

---

## Part 1: Creating Test Accounts

### Why You Need Multiple Test Accounts

Your app has different states:
- **Day 0-1**: New user, no training
- **Day 7**: First week completed
- **Day 14**: Halfway through
- **Day 27**: Almost finished
- **Day 28**: Golden Day!
- **Post-completion**: Questionnaire, reset, new cycle

You need test accounts at each stage to verify everything works.

### Test Account Strategy

**Create 6 test accounts:**

1. **test-new@corejourney.app** - Brand new user (0/28 days)
2. **test-week1@corejourney.app** - Completed 7 days (7/28)
3. **test-halfway@corejourney.app** - Completed 14 days (14/28)
4. **test-almost@corejourney.app** - Completed 27 days (27/28)
5. **test-golden@corejourney.app** - On Day 28 (Golden Day)
6. **test-complete@corejourney.app** - Completed all 28 days

**Password for all:** `TestDemo2025!` (easy to remember)

---

## Part 2: Setting Up Test Data

### Option A: Manual Setup via App (Time-consuming)

**For New User (0/28):**
1. Sign up with email
2. Don't complete any training
3. Done!

**For Day 7 User:**
1. Sign up
2. Complete 7 training sessions manually
3. Takes ~30-60 minutes

**Problem:** This takes FOREVER. Use Option B instead!

### Option B: Seed Script (Recommended)

I'll create a script that sets up all test accounts with data automatically.

**Usage:**
```bash
# Run from your project directory
dart run scripts/seed_test_data.dart --env=dev

# Creates all 6 test accounts with proper data
# Takes ~30 seconds
```

**What it does:**
- Creates Firebase Auth accounts
- Adds progress data to Firestore
- Sets proper training completion dates
- Marks specific days as completed

---

## Part 3: Manipulating Test Data

### Method 1: Firebase Console (Easy, No Code)

**Access Firestore:**
1. Go to https://console.firebase.google.com
2. Select your **development** project
3. Click "Firestore Database" in left sidebar
4. Find your collection (probably `users` or `progress`)

**To Change Completed Days:**
1. Find the user document (by email or UID)
2. Click on the user
3. Find `progress` collection or field
4. Edit the `completedDays` array
5. Add/remove day numbers (0-27)

**Example:**
```
Before: completedDays: [0, 1, 2, 3, 4, 5, 6]  // 7 days
After:  completedDays: [0, 1, 2, ..., 26, 27] // 28 days (Golden Day!)
```

**To Reset a User:**
1. Find the user document
2. Delete the `progress` subcollection
3. Or set `completedDays: []`

### Method 2: Developer Tools in App (Recommended)

Add a hidden debug menu to your development builds.

**Features:**
- View current day count
- Mark any day as complete/incomplete
- Jump to specific day
- Reset all progress
- Trigger Golden Day
- Complete questionnaire

**Access:**
- In development builds only
- Hidden from production
- Tap profile icon 10 times to reveal

I'll create this for you in Part 4.

### Method 3: Isar Studio (Local Database)

Since you use Isar for local storage:

**Install Isar Inspector:**
```bash
dart pub global activate isar_inspector
```

**Run Inspector:**
```bash
# While app is running in dev mode
isar_inspector
```

**Opens a web UI** where you can:
- View all local database records
- Edit progress entries
- Delete records
- Add test data

**URL:** http://localhost:8484 (opens automatically)

---

## Part 4: Testing Different Scenarios

### Scenario 1: New User (Day 0)

**Test Account:** test-new@corejourney.app

**What to Test:**
- [ ] Onboarding shows (if you have one)
- [ ] Dashboard shows 0/28 progress
- [ ] Can start first training
- [ ] Training Day 1 works
- [ ] Progress saves after completion
- [ ] Dashboard updates to 1/28

**Expected Behavior:**
- Clean slate
- No cached data
- All features accessible

### Scenario 2: Mid-Journey (Day 7)

**Test Account:** test-week1@corejourney.app

**What to Test:**
- [ ] Dashboard shows 7/28 (25% progress)
- [ ] Progress bar shows correctly
- [ ] Can access Day 8 training
- [ ] Cannot access Day 9 (if sequential)
- [ ] Previous days show as complete
- [ ] Stats/achievements show correctly

**Edge Cases:**
- Skip a day (go from Day 7 to Day 9)
- Go backwards (replay Day 5)
- Try to replay Day 7 twice

### Scenario 3: Almost Done (Day 27)

**Test Account:** test-almost@corejourney.app

**What to Test:**
- [ ] Dashboard shows 27/28 (96%)
- [ ] Only Day 28 remaining
- [ ] Can access Day 28
- [ ] Day 28 is marked special (Golden Day prep)
- [ ] Anticipation messaging works

### Scenario 4: Golden Day (Day 28) 🌟

**Test Account:** test-golden@corejourney.app

**What to Test:**
- [ ] Special Golden Day UI appears
- [ ] Celebration graphics show
- [ ] Confetti/animation works
- [ ] Special message displays
- [ ] Can complete Day 28
- [ ] After completion: Shows 28/28
- [ ] Questionnaire triggers (if applicable)

**Edge Cases:**
- Force quit during Day 28
- Network error during completion
- Multiple taps on complete button

### Scenario 5: Post-Completion

**Test Account:** test-complete@corejourney.app  

**What to Test:**
- [ ] Questionnaire appears
- [ ] Can fill questionnaire
- [ ] Questionnaire saves
- [ ] Training resets to 0/28 (new cycle)
- [ ] OR: Different UI for completed users
- [ ] Stats preserved from previous cycle
- [ ] Can start new training cycle

**Edge Cases:**
- Skip questionnaire
- Partial questionnaire completion
- Network error during submit

### Scenario 6: Edge Cases

**Things to Test:**

**Time Manipulation:**
- Change device date forward (skip days)
- Change device date backward
- Start training at 11:59 PM, complete at 12:01 AM

**Network Issues:**
- Airplane mode during training
- Complete training offline
- Sync when back online
- Conflict resolution (if data differs)

**Unusual Patterns:**
- Do training 3 times in one day
- Skip 5 days, then resume
- Complete out of order (Day 10 before Day 5)
- Multiple devices (sync issues)

**Performance:**
- 100 completed trainings in database
- Large progress history
- Images/videos in training data

---

## Part 5: Industry-Standard Testing Practices

### What You Might Be Missing

**1. Regression Testing**

**What:** Re-test old features after adding new ones

**How:** Create a regression test checklist
```
After every update, test:
- [ ] Login/Signup still works
- [ ] Training Day 1 works
- [ ] Progress saves
- [ ] Sync works
- [ ] Profile updates
```

**Why:** New features shouldn't break old ones

**2. Exploratory Testing**

**What:** Use the app like a creative user would

**How:** 
- Click things in weird orders
- Rapid-fire button presses
- Use unexpected input
- Try to break things intentionally

**Examples:**
- Tap "Complete Training" 20 times rapidly
- Enter emoji in text fields
- Paste 10,000 characters
- Rotate device mid-training

**3. Boundary Testing**

**What:** Test edge values

**Examples:**
- Day 0 (before first training)
- Day 28 (last day)
- Day 29 (after all training)
- -1 days (invalid)
- 999 days (way over)

**4. Error Recovery Testing**

**What:** Make things fail, see if app recovers

**Test:**
- [ ] Kill app during training save
- [ ] Network error during auth
- [ ] Firebase offline
- [ ] Device runs out of space
- [ ] Low battery mode
- [ ] Background app refresh disabled

**Expected:** App handles gracefully, shows error messages, retries

**5. Accessibility Testing**

**What:** Make sure everyone can use your app

**Test:**
- [ ] VoiceOver (iOS screen reader) works
- [ ] Text scales properly (Settings → Display → Text Size)
- [ ] Buttons are large enough (44x44pt minimum)
- [ ] Colors have sufficient contrast
- [ ] Works in dark mode
- [ ] Works in grayscale mode

**How:**
```
iOS Settings:
- Accessibility → VoiceOver → On
- Accessibility → Display → Reduce Motion
- Display → Text Size → Largest
```

**6. Performance Testing**

**What:** App should be fast and smooth

**Metrics:**
- [ ] App launch < 3 seconds
- [ ] Screen transitions < 300ms
- [ ] No janky animations
- [ ] Memory usage reasonable
- [ ] Battery drain normal
- [ ] No memory leaks

**Tools:**
- Xcode Instruments (Time Profiler, Allocations)
- Firebase Performance Monitoring
- Manual observation

**7. Security Testing**

**What:** Protect user data

**Test:**
- [ ] Passwords not visible in logs
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS only (no HTTP)
- [ ] No hardcoded secrets in code
- [ ] Auth tokens expire properly
- [ ] Password reset works securely

**8. Cross-Device Testing**

**Test on:**
- [ ] Oldest supported iPhone (iPhone 12?)
- [ ] Newest iPhone (iPhone 15)
- [ ] Small screen (iPhone SE)
- [ ] Large screen (iPhone Pro Max)
- [ ] iPad (if supported)
- [ ] iOS minimum version
- [ ] iOS latest version

**9. Localization Testing** (if you support multiple languages)

**Test:**
- [ ] All text translates
- [ ] Text doesn't overflow
- [ ] RTL languages work (Arabic, Hebrew)
- [ ] Date formats correct per locale
- [ ] Number formats correct

**10. Beta Testing Feedback Loop**

**What:** Get real user feedback

**Process:**
1. Release to TestFlight
2. Get feedback from testers
3. Log all bugs/requests
4. Prioritize (critical, high, medium, low)
5. Fix critical bugs
6. Release next beta
7. Repeat

**Feedback Channels:**
- TestFlight feedback
- Email
- Shared spreadsheet
- Bug tracking tool (GitHub Issues, Linear, etc.)

---

## Part 6: Bug Reporting Template

When testers find bugs, use this format:

```markdown
## Bug Report

**Title:** [Brief description]

**Priority:** Critical / High / Medium / Low

**Environment:**
- Build: 1.0.0 (123)
- Device: iPhone 15 Pro
- iOS: 17.2
- Account: test-week1@corejourney.app

**Steps to Reproduce:**
1. Open app
2. Go to Training
3. Complete Day 7
4. Tap "Next Day"

**Expected Result:**
Should show Day 8 training screen

**Actual Result:**
App crashes with white screen

**Screenshots/Video:**
[Attach if possible]

**Frequency:**
Always / Sometimes / Once

**Additional Context:**
Only happens on Day 7, not other days
```

---

## Part 7: Pre-Release Checklist

Before each TestFlight release:

**Functionality:**
- [ ] All core features work
- [ ] No critical bugs
- [ ] New features tested
- [ ] Regression tests pass

**Data:**
- [ ] Test accounts work
- [ ] Data syncs properly
- [ ] No data loss scenarios

**Performance:**
- [ ] App launches quickly
- [ ] No crashes in testing
- [ ] No memory issues

**UI/UX:**
- [ ] No UI glitches
- [ ] Animations smooth
- [ ] Text readable
- [ ] Dark mode works

**Compliance:**
- [ ] Privacy policy updated (if needed)
- [ ] No offensive content
- [ ] Age-appropriate

**Build:**
- [ ] Version number incremented
- [ ] Build number incremented
- [ ] Correct environment (staging/production)
- [ ] Signing works

---

## Part 8: Testing Workflow

**Daily Development:**
1. Write feature
2. Test manually with test accounts
3. Run unit tests (`flutter test`)
4. Fix bugs
5. Commit

**Before TestFlight:**
1. Full regression test (all scenarios)
2. Test on multiple devices
3. Review checklist
4. Build and upload
5. Smoke test TestFlight build

**Beta Testing:**
1. Release to internal testers
2. Collect feedback (3-7 days)
3. Triage bugs
4. Fix critical issues
5. Release next version

**Before App Store:**
1. Extended beta period (2-4 weeks)
2. Test on many devices
3. Get QA approval
4. Final review
5. Submit

---

## Part 9: Tools You Should Know

**Testing Tools:**
- **TestFlight**: Beta distribution
- **Xcode Simulator**: Quick testing
- **Xcode Instruments**: Performance profiling
- **Firebase Console**: Data inspection
- **Isar Inspector**: Local DB inspection
- **Charles Proxy**: Network debugging

**Bug Tracking:**
- GitHub Issues (free, simple)
- Linear (modern, fast)
- Jira (enterprise)
- Notion (flexible)

**Analytics:**
- Firebase Analytics (free)
- Crashlytics (crash reports)
- Performance Monitoring

---

## Quick Reference

**Test Account Passwords:** `TestDemo2025!`

**Firebase Console:** https://console.firebase.google.com

**Test Data Script:**
```bash
dart run scripts/seed_test_data.dart --env=dev
```

**Isar Inspector:**
```bash
isar_inspector
```

**Reset Test Account:**
1. Firebase Console
2. Find user
3. Delete progress data
4. OR: Use reset button in dev builds

---

## What's Industry Standard?

✅ **You should have:**
- Multiple test accounts
- Test data at different states
- Regression test checklist
- Bug reporting process
- Pre-release checklist

✅ **You should do:**
- Test on real devices
- Test edge cases
- Get beta feedback
- Fix critical bugs before release
- Document known issues

✅ **You should NOT do:**
- Test only on simulator
- Skip regression testing
- Ignore beta feedback
- Release with known crashes
- Test only happy path

**Remember:** Better to find bugs in testing than in production!
