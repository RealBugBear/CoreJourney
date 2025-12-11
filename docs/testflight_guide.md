# TestFlight & App Store Quick Start Guide

## Prerequisites Checklist

- [ ] Apple Developer Account ($99/year)
- [ ] App icons ready (1024×1024 minimum)
- [ ] Privacy policy URL (host `privacy_policy.md` somewhere)
- [ ] App description written
- [ ] Production Firebase configured

## Step 1: Prepare Production Build

### 1.1 Update Bootstrap for Production Selection

**Current:** App uses `firebase_options.dart` (always dev)
**Needed:** Support both dev and prod

```bash
# Build for dev (default)
flutter run

# Build for prod
flutter run --dart-define=ENV=prod
flutter build ipa --release --dart-define=ENV=prod
```

### 1.2 Build Production IPA

```bash
# Clean first
flutter clean
flutter pub get

# Build for production
flutter build ipa --release --dart-define=ENV=prod
```

**Output:** `build/ios/ipa/corejourney.ipa`

## Step 2: App Store Connect Setup

### 2.1 Create App
1. Go to: https://appstoreconnect.apple.com
2. My Apps → + Icon → New App
3. Fill details:
   - **Name:** CoreJourney
   - **Primary Language:** German
   - **Bundle ID:** com.alexandermessinger.corejourney
   - **SKU:** corejourney-ios-2025
   - **User Access:** Full Access

### 2.2 App Information
- **Privacy Policy URL:** https://yourdomain.com/privacy (host the privacy_policy.md)
- **Category:** Health & Fitness
- **Subcategory:** Mind & Body
- **Content Rights:** No third-party content

### 2.3 Pricing
- **Price:** Free
- **Availability:** All countries (or select specific)

## Step 3: Upload Build

### Option A: Via Xcode (Recommended)

```bash
# Open workspace
open ios/Runner.xcworkspace
```

In Xcode:
1. Select "Any iOS Device (arm64)"
2. Product → Archive (wait 5-10 min)
3. Window → Organizer → Archives
4. Select archive → "Distribute App"
5. Select "App Store Connect"
6. Upload

### Option B: Via Command Line

```bash
# Build
flutter build ipa --release --dart-define=ENV=prod

# Upload with xcrun
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/corejourney.ipa \
  --username "your@email.com" \
  --password "app-specific-password"
```

## Step 4: TestFlight Setup

### 4.1 Wait for Processing
- After upload: 10-30 minutes processing
- Check: App Store Connect → TestFlight

### 4.2 Add Beta Testers

**Internal Testing (up to 100):**
1. TestFlight → Internal Testing
2. Add email addresses
3. They receive invite automatically

**External Testing (up to 10,000):**
1. TestFlight → External Testing
2. Create group
3. Submit for beta review (1-2 days)
4. Add testers

### 4.3 Test Information
- **Beta App Description:** "28-day reflexology training program"
- **Feedback Email:** beta@corejourney.app
- **What to Test:** Login, training flow, progress tracking

## Step 5: App Store Submission

### 5.1 Screenshots Required

**iPhone 6.7" (Pro Max) - Required:**
- Min 2 screenshots
- Max 10 screenshots
- Size: 1290 × 2796 pixels

**iPhone 5.5" (8 Plus) - Required:**
- Min 2 screenshots  
- Max 10 screenshots
- Size: 1242 × 2208 pixels

**What to show:**
1. Login screen
2. Dashboard with progress
3. Training intro
4. Exercise screen
5. Completion celebration

### 5.2 App Preview (Optional)
- Video demonstration
- 15-30 seconds
- Same sizes as screenshots

### 5.3 Description

**Subtitle (30 chars):**
"28-Tage Reflextraining"

**Description (up to 4000 chars):**
```
CoreJourney - Dein persönliches 28-Tage Programm

Erlebe die Transformation mit unserem wissenschaftlich fundierten 
28-Tage-Programm für pränatales Reflextraining.

✨ FEATURES
• 28 strukturierte Trainingstage
• Geführte tägliche Übungen
• Automatisches Progress Tracking
• Golden Day Celebration
• Offline-Modus
• Cloud-Sync über alle Geräte

🎯 PERFEKT FÜR
• Persönliche Entwicklung
• Körper-Geist-Integration
• Stressreduktion
• Verbesserung von Koordination und Balance

📊 DEIN FORTSCHRITT
Verfolge deinen Fortschritt Tag für Tag. Die App erinnert dich an 
dein Training und feiert deine Erfolge.

Starte noch heute deine CoreJourney!
```

**Keywords (100 chars):**
reflextraining,entwicklung,gesundheit,training,fitness,wellness,koordination

**Support URL:** https://corejourney.app/support
**Marketing URL:** https://corejourney.app

### 5.4 Age Rating
- **Age Rating:** 4+
- **Content:**
  - No violence, sexual content, etc.
  - Health & fitness content only

### 5.5 Review Information
- **Sign-In Required:** Yes
- **Demo Account:**
  - Email: demo@corejourney.app
  - Password: TestDemo123!
  - (Create this in Firebase)
- **Notes:** "Health and wellness training app. No medical claims."

### 5.6 Version Information
- **Version:** 1.0.0
- **Build:** 1
- **Copyright:** 2025 Alexander Messinger
- **Release:** Automatic (or Manual Release)

## Step 6: Submit for Review

1. App Store Connect → CoreJourney → prepare Submission
2. Add all information above
3. Select build from TestFlight
4. Submit for Review
5. Wait 24-72 hours

## Common Issues

### Build Upload Fails
- Check code signing in Xcode
- Verify bundle ID matches App Store Connect
- Try manual archive via Xcode

### Missing Compliance
- Export compliance: No encryption (or standard iOS encryption)
- Content rights: Check if applicable

### Rejection Reasons
1. **Crashes:** Test thoroughly before submission
2. **Missing functionality:** All features should work
3. **Privacy policy:** Must be accessible
4. **Demo account:** Must work for reviewers

## Post-Submission

### If Approved (1-3 days)
- App goes live automatically (or manual release)
- Users can download from App Store
- Monitor reviews and ratings

### If Rejected
- Read rejection reason carefully
- Fix issues
- Reply to reviewer if needed
- Resubmit

## After Launch

### Monitoring
- Check Firebase Analytics
- Monitor crash reports
- Read user reviews
- Track downloads

### Updates
- Fix bugs via new builds
- Add features
- Submit updates same process

---

## Quick Commands Reference

```bash
# Development build
flutter run

# Production build
flutter build ipa --release --dart-define=ENV=prod

# Clean build
flutter clean && flutter pub get && flutter build ipa --release --dart-define=ENV=prod

# Open Xcode
open ios/Runner.xcworkspace
```

## Next Steps

1. [ ] Get Apple Developer account
2. [ ] Create app icons
3. [ ] Host privacy policy
4. [ ] Take screenshots
5. [ ] Build production IPA
6. [ ] Upload to TestFlight
7. [ ] Beta test
8. [ ] Submit to App Store

Good luck! 🚀
