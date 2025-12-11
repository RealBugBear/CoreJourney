# iOS Schemes Configuration Guide

## Overview
iOS uses **Schemes** instead of Android's **Product Flavors**. Each scheme can have different configurations.

## Current Status
✅ Android flavors configured (development, staging, production)
⏳ iOS schemes need to be configured manually in Xcode

## Steps to Configure iOS Schemes

### 1. Open Xcode
```bash
open ios/Runner.xcworkspace
```

### 2. Duplicate Runner Scheme (3 times)

1. Click on "Runner" scheme dropdown (top left, next to play/stop buttons)
2. Select **"Manage Schemes..."**
3. Select "Runner" scheme → Click gear icon → **"Duplicate"**
4. Name it **"development"**
5. Repeat for **"staging"** and **"production"**

### 3. Configure Each Scheme

For each scheme (development, staging, production):

#### A. Edit Scheme
1. Select scheme → Click **"Edit Scheme..."**
2. Go to **"Run"** → **"Info"** tab
3. Set **Build Configuration**:
   - development → Debug-development
   - staging → Release-staging  
   - production → Release-production

#### B. Create Build Configurations
1. Click on project "Runner" in left sidebar
2. Select "Runner" project (blue icon)
3. Go to **"Info"** tab
4. Under **"Configurations"**, duplicate existing configs:
   - Duplicate "Debug" → Rename to **"Debug-development"**
   - Duplicate "Release" → Rename to **"Release-staging"**
   - Duplicate "Release" → Rename to **"Release-production"**

#### C. Set Bundle Identifier per Configuration
1. Select "Runner" target
2. Go to **"Build Settings"** tab
3. Search for **"Product Bundle Identifier"**
4. Expand the dropdown
5. Set for each configuration:
   - Debug-development: `com.alexandermessinger.corejourney.dev`
   - Release-staging: `com.alexandermessinger.corejourney.staging`  
   - Release-production: `com.alexandermessinger.corejourney`

#### D. Set App Name per Configuration
1. In **"Build Settings"**, search for **"Product Name"**
2. Set for each:
   - Debug-development: `CoreJourney DEV`
   - Release-staging: `CoreJourney STAGING`
   - Release-production: `CoreJourney`

### 4. Firebase Configuration per Flavor

Create separate `GoogleService-Info.plist` files:

```bash
ios/
  Runner/
    Firebase/
      development/
        GoogleService-Info.plist  # Dev Firebase
      staging/
        GoogleService-Info.plist  # Staging Firebase (use dev or create separate)
      production/
        GoogleService-Info.plist  # Prod Firebase
```

Then in **Xcode Build Phases**:
1. Select Runner target → **"Build Phases"** tab
2. Add **"Run Script"** phase before "Compile Sources"
3. Add script:

```bash
#!/bin/sh
case "${CONFIGURATION}" in
  "Debug-development" )
    cp -r "${PROJECT_DIR}/Runner/Firebase/development/" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/"
    ;;
  "Release-staging" )
    cp -r "${PROJECT_DIR}/Runner/Firebase/staging/" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/"
    ;;
  "Release-production" )
    cp -r "${PROJECT_DIR}/Runner/Firebase/production/" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/"
    ;;
esac
```

### 5. Verify Setup

Build each flavor:
```bash
# Development
flutter build ios --flavor development --target lib/main_development.dart

# Staging  
flutter build ios --flavor staging --target lib/main_staging.dart

# Production
flutter build ios --flavor production --target lib/main_production.dart
```

Check that:
- Different app names appear
- Different bundle IDs are used
- Apps can be installed side-by-side

---

## Alternative: Use Xcode GUI Only

If you prefer pure Xcode without Build Phases scripts:

1. **Create 3 separate targets** in Xcode (duplicate Runner target)
2. Name them: Runner-Dev, Runner-Staging, Runner-Production
3. Set different Bundle IDs for each
4. Add different `GoogleService-Info.plist` to each target
5. Create schemes for each target

This is simpler but creates more maintenance overhead.

---

## Quick Reference

| Flavor | Bundle ID | App Name | Build Config |
|--------|-----------|----------|--------------|
| development | `com.alexandermessinger.corejourney.dev` | CoreJourney DEV | Debug-development |
| staging | `com.alexandermessinger.corejourney.staging` | CoreJourney STAGING | Release-staging |
| production | `com.alexandermessinger.corejourney` | CoreJourney | Release-production |

---

## Next Steps

After iOS schemes are configured:
1. Test all 3 flavors build successfully
2. Install all 3 on device/simulator to verify they're separate
3. Verify Firebase works correctly for each
4. Document any iOS-specific configuration needed

---

**Note:** iOS configuration is more manual than Android. The steps above need to be done in Xcode GUI. There's no equivalent to Android's `build.gradle.kts` for programmatic flavor configuration in iOS.
