# Push Notification Setup Guide

CoreJourney now uses two notification paths:

- Local notifications for on-device training reminders.
- Firebase Cloud Messaging remote pushes for video calls, call requests, appointment proposals, and confirmed appointments.

The app-side Firebase Messaging integration is implemented. Complete the external setup below before expecting remote pushes to arrive on real devices.

## 1. Apple Developer Portal (Create APNs Key)

1.  Log in to the [Apple Developer Portal](https://developer.apple.com/account).
2.  Go to **Certificates, Identifiers & Profiles**.
3.  Select **Keys** from the side menu.
4.  Click the **+** button to create a new key.
5.  Name it something like "Firebase Push Key".
6.  Check the box for **Apple Push Notifications service (APNs)**.
7.  Click **Continue** and then **Register**.
8.  **Download** the `.p8` file.
    *   **Warning**: You can only download this file **once**. Save it somewhere safe!
9.  Note down the **Key ID** (displayed on the download page).
10. Note down your **Team ID** (displayed in the top right of the portal).

## 2. Firebase Console (Upload Key)

1.  Log in to the [Firebase Console](https://console.firebase.google.com/).
2.  Open your project (**corejourney-prod**).
3.  Click the **Gear icon** (Project Settings) in the top left.
4.  Go to the **Cloud Messaging** tab.
5.  Scroll down to the **Apple app configuration** section.
6.  Under **APNs Authentication Key**, click **Upload**.
7.  Upload the `.p8` file you downloaded from Apple.
8.  Enter the **Key ID** and **Team ID** you noted earlier.
9.  Click **Upload**.

## 3. Xcode Configuration (Enable Capabilities)

1.  Open your project in Xcode:
    ```bash
    open ios/Runner.xcworkspace
    ```
2.  In the project navigator (left sidebar), click on the root **Runner** project.
3.  Select the **Runner** target in the main view.
4.  Go to the **Signing & Capabilities** tab.
5.  Click **+ Capability** (top left of the tab).
6.  Search for **Push Notifications** and double-click to add it.
7.  Click **+ Capability** again.
8.  Search for **Background Modes** and add it.
9.  In the **Background Modes** section, check the box for **Remote notifications**.

The repo already contains the required `aps-environment` entitlement and `UIBackgroundModes` entry. Verify Xcode does not remove them when signing settings change.

## 4. Supabase Edge Function Secrets

Set these secrets for the Supabase project that serves the app:

```bash
supabase secrets set FIREBASE_PROJECT_ID=corejourney-prod
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
```

`FIREBASE_SERVICE_ACCOUNT_JSON` must be the full Firebase service-account JSON for a service account allowed to send FCM v1 messages.

## 5. Database Migration

Apply `supabase/migrations/20260427_push_tokens.sql`. It creates the shared `device_tokens` registry plus `upsert_push_token` and `revoke_push_token`.

## 6. Smoke Test

1. Install the app on a physical iOS or Android device.
2. Sign in and allow notification permission.
3. Confirm a row appears in `device_tokens` with `enabled = true`.
4. Trigger a direct video call, call request, appointment proposal, or appointment confirmation.
5. Confirm the corresponding Supabase function returns `{ "sent": 1 }` or higher.
