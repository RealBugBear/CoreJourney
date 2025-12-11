# Screenshot Guide for App Store

## Required Screenshots

Apple requires screenshots for iPhone displays:

### iPhone 6.7" (Pro Max) - **REQUIRED**
- **Size:** 1290 × 2796 pixels
- **Min:** 2 screenshots
- **Max:** 10 screenshots

### iPhone 5.5" (8 Plus) - **REQUIRED**  
- **Size:** 1242 × 2208 pixels
- **Min:** 2 screenshots
- **Max:** 10 screenshots

---

## Recommended Screenshots (5 total)

1. **Login/Welcome Screen**
   - Shows app branding
   - Clean, inviting first impression

2. **Dashboard with Progress**
   - Main screen showing progress bar
   - Day counter (e.g., "Day 3 of 28")
   - "Start Training" button

3. **Training Intro**
   - "Bereit für dein Training?" screen
   - Shows what user will do

4. **Exercise Screen**
   - Mid-training exercise display
   - Shows timer or instructions

5. **Completion/Progress**
   - Success message
   - Updated progress or celebration

---

## How to Take Screenshots

### Method 1: iOS Simulator (Easiest)

```bash
# Run app on simulator
flutter run

# Or specify device
flutter run -d "iPhone 15 Pro Max"
```

**In Simulator:**
1. Navigate to each screen
2. Press: **Cmd + S** (saves to Desktop)
3. Simulator saves exact required size!

**Simulator Devices to Use:**
- **iPhone 15 Pro Max** → 1290 × 2796 (6.7")
- **iPhone 8 Plus** → 1242 × 2208 (5.5")

### Method 2: Real Device (Advanced)

```bash
# Run on connected iPhone
flutter run -d <device-id>
```

1. Navigate to screens
2. Take screenshots (Power + Volume Up)
3. Transfer to Mac
4. Resize if needed

---

## Screenshot Workflow

### Step 1: Prepare Test Data
Make sure you have good demo data:
- Login with demo account
- Have some progress (Day 3-5 looks good)
- Golden Day date visible

### Step 2: Launch on Correct Simulator

```bash
# List available simulators
flutter devices

# Run on iPhone 15 Pro Max
flutter run -d "iPhone 15 Pro Max"

# Or iPhone 8 Plus
flutter run -d "iPhone 8 Plus"
```

### Step 3: Navigate and Capture

For each screen:
1. Navigate to the screen
2. Wait for animations to complete
3. Press **Cmd + S**
4. Check Desktop for saved image

### Step 4: Organize Files

```bash
# Create folder
mkdir ~/Desktop/AppStore_Screenshots

# Rename files clearly
mv ~/Desktop/Screenshot*.png ~/Desktop/AppStore_Screenshots/
# Then rename to:
# 01_login_6.7.png
# 02_dashboard_6.7.png
# 03_training_intro_6.7.png
# etc.
```

---

## Screenshot Tips

### ✅ Do:
- Use light mode (cleaner look)
- Show realistic data (Day 3-5, not Day 1)
- Center important content
- Remove status bar clutter if possible
- Show app in best light

### ❌ Don't:
- Show error states
- Use placeholder text
- Include personal data
- Show debugging info
- Have empty states

---

## Exact Screens to Capture

### Screen 1: Login
- Show clean login screen
- App logo/name visible
- Email/password fields

**How:**
```bash
flutter run
# Don't login yet
# Cmd + S
```

### Screen 2: Dashboard  
- Progress bar showing ~3/28 days
- "Bereit für dein heutiges Training?" text
- Stats cards visible

**How:**
```bash
# Login with demo account
# See dashboard
# Cmd + S
```

### Screen 3: Training Intro
- "Training starten" button clicked
- Intro screen showing

**How:**
```bash
# From dashboard, click "Training starten"
# Intro screen appears
# Cmd + S
```

### Screen 4: Exercise
- During or after exercise
- Shows exercise content/timer

**How:**
```bash
# Navigate through training flow
# Capture exercise screen
# Cmd + S
```

### Screen 5: Progress/Completion
- After completing training
- Success message visible
- Updated progress

**How:**
```bash
# Complete training
# See confirmation
# Cmd + S
```

---

## After Taking Screenshots

### Verify Sizes
```bash
cd ~/Desktop/AppStore_Screenshots

# Check dimensions
sips -g pixelWidth -g pixelHeight *.png
```

Should show:
- 1290 × 2796 for Pro Max
- 1242 × 2208 for 8 Plus

### Upload to App Store Connect
1. Go to App Store Connect
2. Your App → Screenshots
3. Drag & drop for each device size
4. Arrange in order

---

## Quick Start

**Fastest way to get all screenshots:**

```bash
# 1. Run on Pro Max
flutter run -d "iPhone 15 Pro Max"

# 2. Take 5 screenshots (Cmd+S each):
#    - Login
#    - Dashboard  
#    - Training Intro
#    - Exercise
#    - Completion

# 3. Run on 8 Plus
flutter run -d "iPhone 8 Plus"

# 4. Repeat same 5 screenshots

# Done! You have all required screenshots.
```

---

## Alternative: Use Automated Tools

**Fastlane Snapshot** (Advanced):
- Automates screenshot capture
- Takes screenshots on all devices
- Requires setup

**For now:** Manual is faster and easier!

---

Ready to start? Pick your first device and let's capture! 📸
