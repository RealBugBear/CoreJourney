# Complete Beginner's Guide to TestFlight

This guide assumes you've never done iOS development before. We'll go through every single step.

## What We're Going to Do

By the end of this guide, you'll have:
1. An Apple Developer account (costs $99/year)
2. Your app properly configured for iOS
3. Your app uploaded to TestFlight
4. Beta testers able to download and test your app

This is the FASTEST way to get your app into users' hands. The full App Store comes later.

---

## Part 1: Apple Developer Account (30 minutes + waiting)

### What is this?
Apple requires you to pay $99/year to distribute apps. This gives you access to TestFlight (beta testing) and the App Store.

### Step-by-Step:

**1. Go to Apple Developer Website**
- Open your web browser
- Go to: https://developer.apple.com
- Click the blue "Account" button in the top right corner

**2. Sign In**
- Use your Apple ID (the same one you use for iCloud, App Store, etc.)
- If you don't have one, click "Create yours now" and make one
- Enter your Apple ID email and password

**3. Enroll in the Developer Program**
- After signing in, you'll see a page about the Apple Developer Program
- Click "Enroll" or "Join the Apple Developer Program"
- Click "Start Your Enrollment"

**4. Choose Entity Type**
- Select "Individual" (unless you're a company with a DUNS number)
- Click "Continue"

**5. Fill in Your Information**
- Legal name (your full name exactly as it appears on ID)
- Address
- Phone number
- All fields are required and must be accurate

**6. Review and Accept**
- Read the Apple Developer Program License Agreement
- Check the box to agree
- Click "Continue"

**7. Pay the Fee**
- Cost: $99 USD (about €93)
- Payment methods: Credit card, debit card, or PayPal
- Enter your payment information
- Click "Purchase"

**8. Wait for Approval**
- Apple will review your enrollment
- Usually takes 24-48 hours
- You'll get an email when approved
- Subject line: "Your enrollment in the Apple Developer Program is complete"

**⏳ While You Wait:** You can do Part 2 and Part 3 below! You just can't upload until approved.

---

## Part 2: Configure Xcode (2-3 hours)

### What is Xcode?
Xcode is Apple's tool for building iOS apps. You need it even though you're using Flutter.

### Prerequisites

**1. Make sure Xcode is installed:**
- Open Applications folder on your Mac
- Look for "Xcode" (blue icon with a hammer)
- If you don't have it:
  - Open App Store
  - Search "Xcode"
  - Click "Get" (it's free, but 12-15 GB download)
  - Wait for installation (can take 30-60 minutes)

**2. Open Terminal**
- Press Command + Space
- Type "Terminal"
- Press Enter
- You'll see a white or black window with text

### Step 1: Open Your Project in Xcode

**In Terminal, type exactly:**
```bash
cd /Users/alexandermessinger/dev/corejourney
```
- Press Enter
- This moves you to your project folder

**Then type:**
```bash
open ios/Runner.xcworkspace
```
- Press Enter
- Xcode will open (might take a minute)
- You'll see your project files on the left side

**Important:** Make sure it says "Runner.xcworkspace" in the top of the Xcode window. If it says "Runner.xcodeproj", close it and use the command above again.

### Step 2: Create Build Configurations

**What are Build Configurations?**
These let you have different versions of your app (development for testing, production for users).

**Here's how:**

**1. Find the Project Navigator**
- Left sidebar in Xcode
- It's the folder icon (very top left, looks like 📁)
- Click it if you don't see your files

**2. Click on "Runner" (the blue icon at the very top)**
- NOT the folder, the blue icon with "R" on it
- Left sidebar, very top item

**3. You'll see two lists in the middle:**
- PROJECT: Runner
- TARGETS: Runner, RunnerTests
- Click on "Runner" under "PROJECT" (if not already selected)

**4. Click the "Info" tab**
- Top of the middle section
- Between "General" and "Build Settings"

**5. Find "Configurations" section**
- Scroll down a bit if you don't see it
- You'll see:
  - Debug
  - Release
  - Profile

**6. Create Debug-development:**
- Click the "+" button under Configurations
- Select "Duplicate 'Debug' Configuration"
- It will create "Debug copy"
- Double-click on "Debug copy"
- Type: `Debug-development`
- Press Enter

**7. Create Release-staging:**
- Click the "+" button again
- Select "Duplicate 'Release' Configuration"
- Double-click on "Release copy"
- Type: `Release-staging`
- Press Enter

**8. Create Release-production:**
- Click the "+" button again
- Select "Duplicate 'Release' Configuration"
- Double-click on the new "Release copy"
- Type: `Release-production`
- Press Enter

**You should now have:**
- Debug
- Debug-development ← new
- Release
- Release-staging ← new
- Release-production ← new
- Profile

### Step 3: Set Bundle IDs

**What is a Bundle ID?**
It's like your app's unique address. Each version needs its own.

**Here's how:**

**1. Click "Runner" under TARGETS**
- Middle section, under the TARGETS list
- Click on "Runner" (not the one under PROJECTS)

**2. Click "Build Settings" tab**
- Top of middle area, next to "Info"

**3. Find the search box**
- Right side, small search field
- Type: `product bundle identifier`

**4. You'll see "Product Bundle Identifier" appear**
- Click the triangle/arrow next to it to expand
- You'll see all your configurations listed

**5. Set each one:**

For **Debug-development:**
- Click on the value (right side)
- Delete what's there
- Type: `com.alexandermessinger.corejourney.dev`
- Press Enter

For **Release-staging:**
- Click on the value
- Type: `com.alexandermessinger.corejourney.staging`
- Press Enter

For **Release-production:**
- Click on the value
- Type: `com.alexandermessinger.corejourney`
- Press Enter

**Note:** Debug, Release, and Profile can stay as they are (we won't use them).

### Step 4: Create Schemes

**What is a Scheme?**
A scheme tells Xcode which configuration to use when you build your app.

**Here's how:**

**1. Find the Scheme dropdown**
- Top left of Xcode window
- Next to the Play/Stop buttons
- Says "Runner" with a dropdown arrow

**2. Click on "Runner" dropdown**
- Select "Manage Schemes..." at the bottom

**3. You'll see a list of schemes**
- Probably just "Runner" for now

**4. Create development scheme:**
- Click on "Runner"
- Click the ⚙️ (gear) icon at the bottom
- Select "Duplicate"
- In the "Name" field, delete "Runner copy" and type: `development`
- Click "Close"

**5. Create staging scheme:**
- Click on "Runner" again
- Click gear icon → Duplicate
- Name: `staging`
- Click "Close"

**6. Create production scheme:**
- Click on "Runner" again
- Click gear icon → Duplicate
- Name: `production`
- Click "Close"

**7. Make schemes shared:**
- Check the checkbox in the "Shared" column for:
  - development
  - staging
  - production
- Click "Close"

**You should now see:** development, staging, production schemes

### Step 5: Configure Each Scheme

**For development scheme:**

**1. Select "development" from scheme dropdown**
- Top left, where it says "Runner"
- Click dropdown → Select "development"

**2. Click on "development" dropdown again**
- Select "Edit Scheme..." at the bottom

**3. In the left sidebar, click "Run"**
- It should expand to show: "Info", "Arguments", etc.

**4. Click on "Info" under "Run"**

**5. Find "Build Configuration" dropdown**
- Middle right area
- Click the dropdown
- Select: `Debug-development`
- Click "Close"

**For staging scheme:**

**1. Select "staging" from scheme dropdown**

**2. Click scheme dropdown → "Edit Scheme..."**

**3. Click "Run" → "Info"**

**4. Build Configuration → Select: `Release-staging`**

**5. Click "Close"**

**For production scheme:**

**1. Select "production" from scheme dropdown**

**2. Click scheme dropdown → "Edit Scheme..."**

**3. Click "Run" → "Info"**

**4. Build Configuration → Select: `Release-production`**

**5. Click "Close"**

### Step 6: Test Your Configuration

**1. Close Xcode** (Command + Q)

**2. Open Terminal again**

**3. Type:**
```bash
cd /Users/alexandermessinger/dev/corejourney
flutter clean
flutter pub get
```
- Press Enter after each line
- Wait for it to finish (might take a minute)

**4. Try building production:**
```bash
flutter build ios --flavor production -t lib/main_production.dart
```
- Press Enter
- Wait (this takes 2-5 minutes)

**5. Look for:**
- "Built build/ios/iphoneos/Runner.app" ← Success!
- If you see errors, copy them and I'll help you fix them

**Congratulations!** Xcode is configured! ✅

---

## Part 3: Host Your Privacy Policy (15 minutes)

### Why do you need this?
Apple requires a publicly accessible URL with your privacy policy BEFORE you can upload to TestFlight.

### Option A: GitHub Pages (Easiest, Free)

**Prerequisites:**
- Your code must be in a GitHub repository
- If it is, continue. If not, let me know and I'll help you set that up.

**Steps:**

**1. Go to your GitHub repository**
- Open browser → github.com
- Find your repository (probably `alexandermessinger/corejourney`)

**2. Click "Settings"**
- Top right area of your repository page
- Between "Insights" and the star icon

**3. Scroll down to "Pages"**
- Left sidebar in Settings
- Under "Code and automation" section
- Click "Pages"

**4. Configure Pages:**
- Source: Select "Deploy from a branch"
- Branch: Select "main" (or "master")
- Folder: Select "/docs"
- Click "Save"

**5. Wait a minute**, then refresh the page

**6. You'll see a green box that says:**
- "Your site is live at https://alexandermessinger.github.io/corejourney/"

**7. Your privacy policy will be at:**
```
https://alexandermessinger.github.io/corejourney/privacy_policy
```

**8. Test it:**
- Open that URL in your browser
- You should see your privacy policy
- If you see a 404, wait another minute and try again

**Save this URL!** You'll need it in Part 4.

### Option B: Firebase Hosting (Alternative)

**If you prefer Firebase:**

**1. Install Firebase Tools:**
```bash
npm install -g firebase-tools
```

**2. Login:**
```bash
firebase login
```
- Browser will open
- Login with your Google account (same one as Firebase)

**3. Initialize:**
```bash
cd /Users/alexandermessinger/dev/corejourney
firebase init hosting
```
- Select your production Firebase project
- Public directory: type `public` and press Enter
- Single-page app: type `n` and press Enter
- Overwrite index.html: type `n` and press Enter

**4. Create page:**
```bash
mkdir -p public
cp docs/privacy_policy.md public/privacy.md
```

**5. Deploy:**
```bash
firebase deploy --only hosting
```

**6. Your URL will be:**
```
https://YOUR-PROJECT-ID.web.app/privacy
```
or
```
https://YOUR-PROJECT-ID.firebaseapp.com/privacy
```

---

## Part 4: Create App in App Store Connect (15 minutes)

### Prerequisites
- Your Apple Developer account must be approved (check your email)
- If not approved yet, you can read this but can't do it until approved

### Steps:

**1. Go to App Store Connect**
- Open browser
- Go to: https://appstoreconnect.apple.com
- Sign in with your Apple ID

**2. Click "My Apps"**
- Big blue button in the middle

**3. Click the "+" button**
- Top left, next to "Apps"
- Select "New App"

**4. Fill in the form:**

- **Platforms:** Check "iOS" ✓
- **Name:** `CoreJourney`
  - This is what users see in the App Store
  - Can be changed later
  
- **Primary Language:** Select "German" or "English"
  - Choose the main language of your app
  
- **Bundle ID:** Click dropdown
  - Select: `com.alexandermessinger.corejourney`
  - If you don't see it, it means App Store Connect hasn't synced with Xcode yet
  - Wait 10 minutes and refresh, or continue to Part 5 first
  
- **SKU:** `corejourney-2025`
  - Unique identifier (only you see this)
  - Can be anything, but can't change later
  
- **User Access:** Select "Full Access"

**5. Click "Create"**

**6. Add App Information:**

- Left sidebar → Click "App Information"
- **Privacy Policy URL:** Paste your URL from Part 3
  - Example: `https://alexandermessinger.github.io/corejourney/privacy_policy`
- **Category:** Select "Health & Fitness"
- **Secondary Category:** (optional) "Lifestyle"
- Click "Save" in top right

**Done!** Your app is created in App Store Connect. ✅

---

## Part 5: Build and Upload to TestFlight (45 minutes)

### Final Check Before Building:

**1. Make sure everything is ready:**
- ✅ Apple Developer account approved
- ✅ Xcode configured (Part 2)
- ✅ Privacy policy hosted (Part 3)
- ✅ App created in App Store Connect (Part 4)

**2. Verify production Firebase:**
- Make sure you have `ios/Runner/GoogleService-Info.plist` for production
- If you only have dev Firebase, that's okay for now - we'll fix later

### Build the Archive

**1. Close Xcode if it's open**

**2. Open Terminal**

**3. Navigate to project:**
```bash
cd /Users/alexandermessinger/dev/corejourney
```

**4. Clean and prepare:**
```bash
flutter clean
flutter pub get
```

**5. Open Xcode:**
```bash
open ios/Runner.xcworkspace
```

**6. In Xcode, select production scheme:**
- Top left dropdown (currently shows a scheme name)
- Click it
- Select "production"

**7. Select device:**
- Next to the scheme dropdown
- Click where it says "iPhone 15 Pro" or similar
- Select "Any iOS Device (arm64)"
- It should now say "production > Any iOS Device (arm64)"

**8. Archive the app:**
- Top menu: Product → Archive
- Wait 5-10 minutes
- You'll see a progress bar
- When done, a window called "Organizer" will open

**If you see errors during archive:**
- Take a screenshot or copy the error
- Tell me exactly what it says
- Common issues:
  - Signing: We'll fix together
  - Missing files: We'll add them
  - Version errors: Easy to fix

### Upload to App Store Connect

**In the Organizer window:**

**1. You'll see your archive listed**
- Should say "CoreJourney" and today's date
- Should say "production" configuration

**2. Click "Distribute App"** (blue button on right)

**3. Select "App Store Connect"**
- Click "Next"

**4. Select "Upload"**
- Click "Next"

**5. App Store Connect Symbols:**
- Check ✓ "Upload your app's symbols..."
- Check ✓ "Manage Version and Build Number"
- Click "Next"

**6. Signing:**
- Select "Automatically manage signing"
- Click "Next"
- Xcode will prepare your app (1-2 minutes)

**7. Review:**
- You'll see a summary
- Check that:
  - Bundle ID: com.alexandermessinger.corejourney
  - Version looks correct (1.0.0)
- Click "Upload"

**8. Wait for upload:**
- Progress bar will show
- Takes 2-5 minutes depending on internet
- When done: "Upload Successful!" ✅

**9. Click "Done"**

### Wait for Processing

**1. Go back to browser**
- App Store Connect → TestFlight
- Or direct: https://appstoreconnect.apple.com

**2. Click on "CoreJourney"**

**3. Click "TestFlight" tab**
- Top of the page, between "App Store" and "Activity"

**4. You'll see:**
- Your build with status "Processing"
- This takes 10-30 minutes normally
- You'll get an email when ready
- Email subject: "Your build has finished processing"

**5. While you wait:**
- Get coffee ☕
- Read the next section
- Do NOT close this browser tab

---

## Part 6: Invite Beta Testers (10 minutes)

### After Processing is Complete

**1. In App Store Connect → TestFlight:**

**2. Click "Internal Testing" on left:**

**3. Click "+ " next to "Internal Testing"**
- Or click "Create Group" if you don't have one

**4. Create a Test Group:**
- Name: `Beta Testers` (or whatever you want)
- Check ✓ "Enable automatic distribution"
- Click "Create"

**5. Add Testers:**
- Click "Testers" tab  
- Click "+" button
- Enter email addresses (one per line):
  ```
  friend1@example.com
  friend2@example.com
  yourownexample@gmail.com
  ```
- Click "Add"

**6. Select your build:**
- Click "Builds" tab
- Click "+" next to your build number
- Select the build that was processing
- Click "Add Build"

**7. Click "Start Testing"** (if prompted)

### Testers Receive Invite

**Within a few minutes:**
- Each tester gets an email
- Subject: "You're invited to test CoreJourney"
- They click "View in TestFlight" or "Start Testing"

**Testers need to:**
1. Install TestFlight app from App Store (free)
2. Accept your invitation
3. Click "Install" in TestFlight
4. Your app downloads to their iPhone!

---

## Part 7: What to Tell Your Testers

**Send them this message:**

---

Hi! I'd love your feedback on my app CoreJourney.

**To install:**

1. **Check your email** for an invite from Apple TestFlight
   - Subject: "You're invited to test CoreJourney"
   
2. **Install the TestFlight app**
   - Open App Store on your iPhone
   - Search "TestFlight"
   - Download (it's free, made by Apple)

3. **Accept the invite**
   - Open the email again
   - Tap "View in TestFlight" or "Start Testing"
   - It will open the TestFlight app

4. **Install CoreJourney**
   - Tap "Install" next to CoreJourney
   - Wait for download
   - Tap "Open" to launch

5. **Use the app and give feedback!**
   - In TestFlight app, tap "Send Beta Feedback"
   - Or text/email me directly

The app is in early beta, so if you find bugs, that's great - let me know!

Thanks!

---

## Troubleshooting

### Common Issues and Solutions

**"No Schemes" in Xcode dropdown**
- Did you close and reopen Xcode after creating schemes?
- Try: Xcode menu → Product → Scheme → Manage Schemes
- Make sure "Shared" is checked for your schemes

**"Signing for 'Runner' requires a development team"**
- Xcode → Select Runner target
- "Signing & Capabilities" tab
- Check ✓ "Automatically manage signing"
- Team: Select your Apple Developer team from dropdown
- If no team appears: Your Apple Developer account isn't approved yet

**"No bundle ID found" in App Store Connect**
- Create the bundle IDs manually:
  1. developer.apple.com → Certificates, IDs, & Profiles
  2. Identifiers → "+" button
  3. App IDs → Continue
  4. Description: CoreJourney Production
  5. Bundle ID: com.alexandermessinger.corejourney
  6. Capabilities: (leave default)
  7. Continue → Register

**Build takes forever**
- First build is always slow (5-10 min)
- Subsequent builds are faster (2-3 min)
- If stuck >20 min, press Command+. to cancel and try again

**"Archive not showing in Organizer"**
- Xcode → Window → Organizer
- Click "iOS Apps" if not selected
- Look for "Archives" section
- Select "All" from dropdown
- Your archive should be there

**Testers not receiving email**
- Check spam folder
- Make sure you entered email correctly
- Try removing and re-adding the tester
- Wait up to 1 hour (sometimes emails are slow)

**Can't install on iPhone**
- TestFlight only works on iPhone, iPad, Apple Watch
- Tester must have iOS 13.0 or later
- Check Settings → General → Software Update

---

## What Happens Next?

### You just did something amazing! 🎉

You:
- Set up a proper dev/prod workflow (like the pros)
- Configured iOS properly
- Created an app in App Store Connect
- Built and uploaded your first iOS app
- Got it into the hands of real users

### Now What?

**1. Collect Feedback (1-2 weeks)**
- Ask testers what works and what doesn't
- Note all bugs and crashes
- See what features they want

**2. Fix and Iterate**
- Fix critical bugs first
- Make small improvements
- Upload new builds to TestFlight (same process as Part 5)
  - Testers get automatic updates!

**3. Prepare for App Store (when ready)**
- Create app screenshots (we'll do this together later)
- Write full app description
- Add more metadata
- Submit for App Store review

**But for now:**
- Take a break! You earned it.
- Wait for feedback from testers
- We'll do the next steps when you're ready

---

## Quick Reference Card

**Build Production:**
```bash
cd /Users/alexandermessinger/dev/corejourney
flutter clean && flutter pub get
open ios/Runner.xcworkspace
# Then: Product → Archive
```

**Upload New Version:**
1. Increment version in pubspec.yaml (1.0.0+1 → 1.0.0+2)
2. Build archive (Product → Archive)
3. Distribute → Upload
4. Wait for processing
5. Testers get automatic update!

**Important URLs:**
- App Store Connect: https://appstoreconnect.apple.com
- Developer Portal: https://developer.apple.com
- TestFlight Status: Check in App Store Connect → TestFlight

**Get Help:**
If you get stuck:
1. Read the error message carefully
2. Check the Troubleshooting section above
3. Ask me! Copy/paste the exact error

---

**You did it!** Your app is live in TestFlight! 🚀
