# Demo Account Setup for App Store Review

## Why You Need This
Apple reviewers need to test your app before approval. You must provide working login credentials.

---

## Create Demo Account

### Step 1: Go to Firebase Console
**Production:** https://console.firebase.google.com/project/corejourney-prod/authentication/users

### Step 2: Add User
1. Click **"Add user"** button
2. Fill in:
   - **Email:** `demo@corejourney.app`
   - **Password:** `DemoReview2025!`
3. Click **"Add user"**

### Step 3: Save Credentials
Add these to App Store Connect when submitting:

```
Demo Account Email: demo@corejourney.app
Demo Account Password: DemoReview2025!
```

**Notes for reviewers:**
```
This is a demo account for testing. 
The app tracks a 28-day training program.
Log in and click "Start Training" to see the exercise flow.
Progress is automatically saved.
```

---

## Test the Demo Account

Before submitting to App Store, verify it works:

```bash
# Run production version
flutter run --dart-define=ENV=prod
```

1. Logout if logged in
2. Login with demo credentials
3. Complete one training session
4. Verify progress saves
5. Logout and login again to verify persistence

---

## Alternative Accounts (Optional)

Create additional test accounts if needed:

- `test1@corejourney.app` / `TestUser123!`
- `test2@corejourney.app` / `TestUser123!`

These can be used for:
- Internal testing
- Beta testers
- Different progress states

---

## Security Note

⚠️ **Never use real user passwords** for demo accounts.
✅ Use unique passwords only for demo purposes.
🔒 These credentials will be visible to Apple reviewers.

---

## After App Store Approval

You can:
- Keep the demo account active for support testing
- Or delete it: Firebase Console → Users → Delete

Done! The demo account is ready for App Store submission. ✅
