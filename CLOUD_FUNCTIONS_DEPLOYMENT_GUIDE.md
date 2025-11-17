# Cloud Functions Deployment Guide - IAP Receipt Validation

This guide explains how to deploy Firebase Cloud Functions for server-side In-App Purchase (IAP) receipt validation in SortBliss.

**Purpose:** Prevent IAP fraud by validating purchases with Apple App Store and Google Play APIs before granting in-app content.

**Security Benefits:**
- Prevents users from hacking IAP with tools like Lucky Patcher, Cydia Substrate
- Prevents replay attacks (same receipt used multiple times)
- Validates purchases with official Apple/Google APIs
- Stores validated receipts in Firestore to prevent duplication
- Protects revenue from fraudulent purchases

---

## Prerequisites

Before deploying Cloud Functions, you must complete:
- ✅ P0.5: Firebase Setup (FIREBASE_SETUP_GUIDE.md)
- ✅ Firebase CLI installed
- ✅ Node.js 18+ installed

---

## Part 1: Install Firebase CLI

### 1.1 Install Node.js

**macOS (using Homebrew):**
```bash
brew install node@18
```

**Linux:**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Windows:**
Download from https://nodejs.org/

**Verify installation:**
```bash
node --version  # Should show v18.x.x or higher
npm --version   # Should show 9.x.x or higher
```

### 1.2 Install Firebase CLI

```bash
npm install -g firebase-tools
```

**Verify installation:**
```bash
firebase --version  # Should show 12.x.x or higher
```

### 1.3 Login to Firebase

```bash
firebase login
```

This will open a browser window for Google authentication. Login with the same Google account you used to create your Firebase project.

---

## Part 2: Initialize Firebase in Your Project

### 2.1 Navigate to Project Directory

```bash
cd /home/user/sortbliss
```

### 2.2 Initialize Firebase

```bash
firebase init
```

**Select features:**
- [ ] Realtime Database (No)
- [ ] Firestore (Yes - for storing validated receipts)
- [x] Functions (Yes - for receipt validation)
- [ ] Hosting (No)
- [ ] Storage (No)
- [ ] Emulators (Yes - for local testing)

**Select Firebase project:**
- Choose "Use an existing project"
- Select your SortBliss Firebase project

**Firestore setup:**
- Use default Firestore rules
- Use default Firestore indexes

**Functions setup:**
- Language: TypeScript (already configured)
- ESLint: Yes (already configured)
- Install dependencies: Yes

**Emulators setup:**
- Functions emulator: Yes
- Firestore emulator: Yes

### 2.3 Verify Functions Directory

```bash
ls functions/
# Should show:
# - package.json
# - tsconfig.json
# - src/
# - .eslintrc.js
# - .gitignore
```

---

## Part 3: Install Cloud Functions Dependencies

### 3.1 Install Node Modules

```bash
cd functions
npm install
```

**Expected output:**
```
added 250+ packages in 30s
```

### 3.2 Verify Dependencies

```bash
npm list --depth=0
```

**Should show:**
- firebase-admin@^11.11.0
- firebase-functions@^4.5.0
- axios@^1.6.0
- google-auth-library@^9.2.0
- typescript@^4.9.0

---

## Part 4: Configure Apple App Store Credentials

### 4.1 Get Apple Shared Secret

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to "My Apps" > [Your App]
3. Click "App Information"
4. Scroll to "App-Specific Shared Secret"
5. Click "Generate" (or "View" if already exists)
6. Copy the shared secret (format: `abc123def456...`)

### 4.2 Set Apple Shared Secret in Firebase

```bash
cd /home/user/sortbliss/functions
firebase functions:config:set apple.shared_secret="YOUR_APPLE_SHARED_SECRET"
```

**Replace `YOUR_APPLE_SHARED_SECRET` with the actual secret from App Store Connect.**

### 4.3 Verify Configuration

```bash
firebase functions:config:get
```

**Expected output:**
```json
{
  "apple": {
    "shared_secret": "abc123def456..."
  }
}
```

---

## Part 5: Configure Google Play Credentials

### 5.1 Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to "IAM & Admin" > "Service Accounts"
4. Click "Create Service Account"
5. **Name:** `sortbliss-play-validator`
6. **Description:** `Service account for Google Play receipt validation`
7. Click "Create and Continue"

### 5.2 Grant Permissions

1. **Role:** Select "Service Account User"
2. Click "Continue"
3. Click "Done"

### 5.3 Create JSON Key

1. Find your new service account in the list
2. Click the three dots (⋮) > "Manage keys"
3. Click "Add Key" > "Create new key"
4. **Key type:** JSON
5. Click "Create"
6. Save the JSON file as `service-account-key.json`

**⚠️ IMPORTANT:** Never commit this file to git. It's already in .gitignore.

### 5.4 Enable Google Play Developer API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "Library"
3. Search for "Google Play Android Developer API"
4. Click on it and click "Enable"

### 5.5 Grant API Access in Play Console

1. Go to [Google Play Console](https://play.google.com/console/)
2. Select your app
3. Navigate to "Setup" > "API access"
4. Find your service account in the list
5. Click "Grant access"
6. Under "Permissions," select:
   - ✅ View financial data, orders, and cancellation survey responses
   - ✅ Manage orders and subscriptions
7. Click "Invite user"
8. Click "Send invite"

### 5.6 Upload Service Account to Firebase (Optional)

**Option A: Use Application Default Credentials (Recommended)**

When deployed to Cloud Functions, the service account is automatically available. No manual upload needed.

**Option B: Manual Configuration (For local testing)**

```bash
firebase functions:config:set google.service_account="$(cat service-account-key.json)"
```

**Note:** This stores the entire JSON in Firebase config. Not recommended for production.

---

## Part 6: Deploy Cloud Functions

### 6.1 Build Functions

```bash
cd /home/user/sortbliss/functions
npm run build
```

**Expected output:**
```
Successfully compiled 3 files with TypeScript
```

### 6.2 Deploy to Firebase

```bash
firebase deploy --only functions
```

**Deployment process:**
1. Compiles TypeScript to JavaScript
2. Uploads functions to Firebase
3. Provisions Cloud Functions infrastructure
4. Deploys functions to production

**Expected output:**
```
✔ functions[validateReceipt(us-central1)] Successful create operation.
✔ functions[restorePurchases(us-central1)] Successful create operation.
✔ functions[appleWebhook(us-central1)] Successful create operation.
✔ functions[googleWebhook(us-central1)] Successful create operation.

✔ Deploy complete!

Functions deployed:
- validateReceipt(us-central1)
- restorePurchases(us-central1)
- appleWebhook(us-central1)
- googleWebhook(us-central1)
```

**Deployment time:** 2-5 minutes

### 6.3 Verify Deployment

```bash
firebase functions:list
```

**Expected output:**
```
┌────────────────────┬──────────────┬──────────────┐
│ Function           │ Version      │ Trigger      │
├────────────────────┼──────────────┼──────────────┤
│ validateReceipt    │ 1            │ HTTPS        │
│ restorePurchases   │ 1            │ HTTPS        │
│ appleWebhook       │ 1            │ HTTPS        │
│ googleWebhook      │ 1            │ HTTPS        │
└────────────────────┴──────────────┴──────────────┘
```

### 6.4 Get Function URLs

```bash
firebase functions:config:get
```

**Note the function URLs (format: https://us-central1-YOUR-PROJECT.cloudfunctions.net/functionName)**

---

## Part 7: Update Flutter App to Use Cloud Functions

### 7.1 Add cloud_functions Dependency

Edit `pubspec.yaml`:

```yaml
dependencies:
  # ... existing dependencies
  cloud_functions: ^4.5.0
```

Run:
```bash
flutter pub get
```

### 7.2 Uncomment Cloud Functions Code

Edit `lib/core/monetization/monetization_manager.dart`:

1. **Line 8:** Uncomment the import:
```dart
import 'package:cloud_functions/cloud_functions.dart';
```

2. **Lines 200-254:** Uncomment the `_validateReceipt` method body (remove `/*` and `*/`)

3. **Lines 256-263:** Remove the temporary skip logic

**Before:**
```dart
// TODO: Uncomment after Firebase setup (P0.5)
// import 'package:cloud_functions/cloud_functions.dart';

Future<bool> _validateReceipt(PurchaseDetails purchaseDetails) async {
  // TODO: Uncomment after Firebase setup (P0.5)
  /*
  try {
    final functions = FirebaseFunctions.instance;
    // ... validation code
  }
  */

  // TEMPORARY: Allow all purchases until Firebase is set up
  debugPrint('WARNING: Receipt validation disabled - Firebase not configured');
  return true;
}
```

**After:**
```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<bool> _validateReceipt(PurchaseDetails purchaseDetails) async {
  try {
    final functions = FirebaseFunctions.instance;
    // ... validation code (all uncommented)
    return true;
  } catch (e) {
    // ... error handling
    return false;
  }
}
```

### 7.3 Rebuild and Test

```bash
flutter clean
flutter pub get
flutter run --release
```

---

## Part 8: Test Receipt Validation

### 8.1 Test Purchase Flow

1. Launch app on device/emulator
2. Navigate to Storefront
3. Attempt to purchase "Starter Pack (100 coins)"
4. Complete the purchase (use Sandbox tester account for iOS)
5. Verify purchase is validated and coins are added

### 8.2 Check Firebase Logs

```bash
firebase functions:log --only validateReceipt
```

**Expected output:**
```
2024-01-15T10:30:00.000Z - info: Receipt validated successfully
  userId: "abc123"
  platform: "ios"
  productId: "sortbliss_coin_pack_small"
  transactionId: "1000000123456789"
```

### 8.3 Verify Firestore Storage

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to "Firestore Database"
4. Check `validated_receipts` collection
5. Verify receipt document exists with correct data

### 8.4 Test Replay Attack Prevention

1. Complete a purchase
2. Try to use the same receipt again (modify app code to replay)
3. Verify second attempt is rejected with error: "This receipt has already been used by another user"

---

## Part 9: Monitor and Maintain

### 9.1 Set Up Alerts

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to "Functions"
3. Click on `validateReceipt`
4. Click "Set up alerts"
5. Enable alerts for:
   - Function errors
   - High latency (>1s)
   - Memory exceeded

### 9.2 Monitor Costs

Cloud Functions pricing:
- **Free tier:** 2 million invocations/month
- **Paid tier:** $0.40 per million invocations

**Estimated costs for SortBliss:**
- 10,000 DAU × 5 purchases/day = 50,000 invocations/month
- Cost: $0 (well within free tier)

### 9.3 View Logs

**Real-time logs:**
```bash
firebase functions:log --follow
```

**Filter by function:**
```bash
firebase functions:log --only validateReceipt
```

**View errors only:**
```bash
firebase functions:log | grep ERROR
```

---

## Part 10: Implement Webhooks (Optional - For Subscriptions)

If you plan to add subscriptions in the future, implement webhook handlers.

### 10.1 Apple App Store Server Notifications

**Purpose:** Receive notifications for subscription renewals, cancellations, refunds

**Setup:**
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to your app
3. Click "App Information"
4. Scroll to "App Store Server Notifications"
5. **URL:** `https://us-central1-YOUR-PROJECT.cloudfunctions.net/appleWebhook`
6. Click "Save"

**Implementation:**
Edit `functions/src/index.ts` and implement the `appleWebhook` function (currently has TODO).

### 10.2 Google Play Real-time Developer Notifications

**Purpose:** Receive notifications for subscription events and refunds

**Setup:**
1. Go to [Google Play Console](https://play.google.com/console/)
2. Navigate to your app
3. Click "Monetize" > "Monetization setup"
4. Scroll to "Real-time developer notifications"
5. **Topic name:** Create a Pub/Sub topic in Google Cloud
6. Link the topic to Cloud Functions

**Implementation:**
Edit `functions/src/index.ts` and implement the `googleWebhook` function (currently has TODO).

---

## Troubleshooting

### "Apple shared secret not configured"

**Error:** `Apple shared secret not configured. Run: firebase functions:config:set apple.shared_secret="your_secret"`

**Solution:**
```bash
firebase functions:config:set apple.shared_secret="YOUR_APPLE_SHARED_SECRET"
firebase deploy --only functions
```

### "Google Play API authentication failed"

**Error:** `API authentication failed. Check service account configuration.`

**Solutions:**
1. Verify service account has correct permissions in Play Console
2. Ensure "Google Play Android Developer API" is enabled
3. Wait 24 hours for permissions to propagate
4. Check service account key is valid

### "Purchase not found in Google Play"

**Error:** `Purchase not found`

**Solutions:**
1. Ensure app is using production APK (not debug)
2. Verify package name matches exactly: `com.sortbliss.app`
3. Check purchase token is correct
4. Ensure purchase wasn't refunded

### "Receipt replay attack detected"

**Warning:** `This receipt has already been used by another user`

**This is expected behavior - the system is working correctly.**

The receipt was already validated for a different user. This prevents fraud.

### High latency (>2 seconds)

**Causes:**
- Cold start penalty (first invocation after idle)
- Network latency to Apple/Google APIs

**Solutions:**
1. Increase function memory (improves cold start):
   ```typescript
   export const validateReceipt = functions
     .runWith({ memory: '512MB' })
     .https.onCall(async (data, context) => { ... });
   ```

2. Set minimum instances (keeps function warm):
   ```typescript
   export const validateReceipt = functions
     .runWith({ minInstances: 1 })
     .https.onCall(async (data, context) => { ... });
   ```

   **Note:** Minimum instances cost ~$5/month but eliminate cold starts.

---

## Security Best Practices

### 1. Never Commit Secrets

**Files to NEVER commit:**
- `service-account-key.json`
- `.runtimeconfig.json`
- Any file ending in `-key.json`

**These are already in .gitignore.**

### 2. Rotate Secrets Regularly

**Apple Shared Secret:**
- Regenerate every 6 months
- Update with: `firebase functions:config:set apple.shared_secret="NEW_SECRET"`
- Redeploy: `firebase deploy --only functions`

**Google Service Account:**
- Rotate keys annually
- Create new key, deploy, then delete old key

### 3. Use Firebase App Check (Recommended)

Prevents unauthorized clients from calling your Cloud Functions.

**Setup:**
1. Go to Firebase Console > Build > App Check
2. Enable App Check for your app
3. Add App Check enforcement in Cloud Functions

### 4. Rate Limiting

Prevent abuse by limiting calls per user.

**Implementation:**
Use Firebase Functions rate limiting (built-in for callable functions).

---

## Cost Optimization

### Free Tier Limits
- 2M invocations/month
- 400,000 GB-seconds compute time
- 200,000 CPU-seconds
- 5GB network egress

### Estimated Usage for SortBliss
- **Invocations:** 50,000/month (well within free tier)
- **Compute time:** Minimal (each call takes <500ms)
- **Network:** Minimal (small JSON payloads)

**Expected monthly cost:** $0

### If You Exceed Free Tier
- Monitor usage in Firebase Console > Functions > Usage
- Set up budget alerts in Google Cloud Console
- Consider caching validation results (already implemented)

---

## Next Steps After Deployment

1. ✅ Deploy Cloud Functions
2. ✅ Uncomment receipt validation in MonetizationManager
3. ✅ Test purchase flow end-to-end
4. ✅ Monitor logs for errors
5. ✅ Set up alerts for function failures
6. 🔄 Implement webhook handlers for subscriptions (if applicable)
7. 🔄 Enable Firebase App Check (recommended)

---

## Summary Checklist

After completing this guide, you will have:
- ✅ Firebase CLI installed and authenticated
- ✅ Cloud Functions project initialized
- ✅ Apple shared secret configured
- ✅ Google Play service account created and configured
- ✅ 4 Cloud Functions deployed:
  - validateReceipt (receipt validation)
  - restorePurchases (restore purchases)
  - appleWebhook (Apple server notifications)
  - googleWebhook (Google Play notifications)
- ✅ Flutter app updated to use Cloud Functions
- ✅ Receipt validation tested and working
- ✅ Firestore storing validated receipts
- ✅ Monitoring and alerts configured

**Estimated Time:** 45-60 minutes (first-time setup)

**Status Check:**
```bash
# Verify deployment
firebase functions:list

# Check logs
firebase functions:log --only validateReceipt --limit 5

# Test with Flutter app
flutter run --release
```

---

**Questions?** Check [Firebase Functions Documentation](https://firebase.google.com/docs/functions) or Firebase Community Forums.

**Security concerns?** Email: support@sortbliss.com
