# TestFlight Quick Start Guide

**Goal:** Get your app to beta testers in 2-3 days.

## What You Need

✅ **Already have:**
- Working Flutter app with dev/staging/prod flavors
- Firebase configured
- Privacy policy document

⏳ **Still need:**
- Apple Developer account ($99/year, 24-48h approval)
- Xcode schemes configured
- Privacy policy hosted publicly
- First production build uploaded

## Step-by-Step

### 1. Apple Developer Account (Start Today!)

1. Go to https://developer.apple.com/programs/enroll/
2. Pay $99, wait 24-48 hours for approval
3. While waiting: Do steps 2-3 below

### 2. Configure Xcode (2-3 hours)

See detailed guide: [docs/IOS_SCHEMES_SETUP.md](file:///Users/alexandermessinger/dev/corejourney/docs/IOS_SCHEMES_SETUP.md)

**Quick version:**
```bash
# Open Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Create build configurations (Debug-development, Release-staging, Release-production)
# 2. Set bundle IDs per config
# 3. Create schemes (development, staging, production)
# 4. Link schemes to configurations
```

**Test it works:**
```bash
flutter build ios --flavor production -t lib/main_production.dart
```

### 3. Host Privacy Policy (15 minutes)

**Easiest: GitHub Pages**
```bash
# In your GitHub repo:
# Settings → Pages → Deploy from: main branch → /docs folder

# Your URL will be:
https://YOUR_USERNAME.github.io/corejourney/privacy_policy
```

**Add link to app:**
```dart
// In settings screen
ListTile(
  title: Text('Privacy Policy'),
  onTap: () => launch('https://YOUR-URL/privacy'),
)
```

### 4. Create App in App Store Connect (5 minutes)

After Apple account approved:
1. https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Name: CoreJourney
4. Bundle ID: com.alexandermessinger.corejourney
5. SKU: corejourney-2025
6. Privacy URL: Your hosted URL

### 5. Upload to TestFlight (30 minutes)

**Build & Archive:**
```bash
# In Xcode:
# Select: production scheme + Any iOS Device
# Product → Archive (wait 5-10 min)
# Organizer → Distribute App → Upload
```

**Wait for processing:** 10-30 minutes

### 6. Invite Testers (5 minutes)

1. App Store Connect → TestFlight → Internal Testing
2. Add emails (up to 100, no review needed!)
3. Testers get email → Install TestFlight app → Download your app

## Timeline

- **Day 1**: Sign up Apple Developer, start Xcode config
- **Day 2**: Finish Xcode, host privacy policy, test build
- **Day 3**: Upload to TestFlight
- **Day 4**: Testers using your app! 🎉

## Troubleshooting

**"No signing certificate"**
- Xcode → Automatically manage signing ✓

**Upload fails**
- Check bundle ID matches exactly
- Try archiving again

**Processing stuck**
- Normal: 10-30 min
- Check App Store Connect → Activity for errors

## After First Beta

1. Collect feedback
2. Fix bugs
3. Upload new build (increment version)
4. Iterate!

When ready for public: Add screenshots, full metadata, submit to App Store.

---

**Commands Cheat Sheet:**
```bash
# Open Xcode
open ios/Runner.xcworkspace

# Build production
flutter build ios --flavor production -t lib/main_production.dart --release

# Clean build
flutter clean && flutter pub get
```

Good luck! 🚀
