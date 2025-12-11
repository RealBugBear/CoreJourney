# Push Notification Setup Guide

> [!NOTE]
> **Important for Streak Reminders**: The streak reminder feature we just implemented uses **Local Notifications**. These are scheduled directly by the app on the user's device. **You do NOT need to perform the steps below for the streak reminders to work.** They will work out of the box!
>
> The steps below are for enabling **Remote Push Notifications** (e.g., if you want to send marketing messages or announcements from the Firebase Console to all users).

If you decide to enable Remote Push Notifications in the future, follow these steps:

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
2.  Open your project (**corejourney**).
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

## 4. Code Dependencies (Future)

To actually receive these remote notifications in the app, you would need to:
1.  Add `firebase_messaging` to your `pubspec.yaml`.
2.  Initialize Firebase Messaging in your code.
3.  Request permission (similar to how we did for local notifications).

But again, for your **Streak Reminders**, you are already good to go! 🚀
