# AdMob Setup Guide for SortBliss

This guide explains how to set up Google AdMob for SortBliss to enable production ad revenue.

**Status:** 🚨 REQUIRED - App currently uses test ad unit IDs that generate $0 revenue

---

## Prerequisites

- Google account
- Published app OR app pending review in App Store/Play Store
- Access to [AdMob Console](https://apps.admob.com/)
- Firebase project already set up (see FIREBASE_SETUP_GUIDE.md)

---

## Revenue Impact

**Current State:**
- Using test ad unit IDs
- **Revenue:** $0/month (test ads don't pay)

**After Setup:**
- Production ad unit IDs
- **Estimated Revenue:** $500-2000/month (depends on DAU and engagement)
- eCPM (earnings per 1000 impressions): $5-15 for rewarded ads

---

## Step 1: Create AdMob Account

### 1.1 Sign Up

1. Go to [AdMob Console](https://apps.admob.com/)
2. Click "Get Started" or "Sign In"
3. Use the same Google account as your Firebase project
4. Accept the AdMob terms of service
5. Select your country and timezone
6. Click "Create AdMob account"

### 1.2 Link to Firebase (Optional but Recommended)

1. In AdMob Console, go to "Settings" > "Linked accounts"
2. Click "Link" next to Firebase
3. Select your SortBliss Firebase project
4. Click "Link"

**Benefits:**
- Unified analytics across Firebase and AdMob
- Better audience segmentation
- Integrated reporting

---

## Step 2: Add Apps to AdMob

### 2.1 Add Android App

1. In AdMob Console, click "Apps" in sidebar
2. Click "Add app"
3. **Is your app listed on a supported app store?**
   - If app is already published: Select "Yes" and search for it
   - If app is not published yet: Select "No"
4. **Platform:** Android
5. **App name:** SortBliss
6. **Package name:** `com.sortbliss.app`
   - ⚠️ Must match exactly with `android/app/build.gradle` applicationId
7. Click "Add app"

**Note the App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`)

### 2.2 Add iOS App

1. Click "Apps" > "Add app"
2. **Is your app listed on a supported app store?**
   - If app is already published: Select "Yes" and search for it
   - If app is not published yet: Select "No"
3. **Platform:** iOS
4. **App name:** SortBliss
5. **Bundle ID:** `com.sortbliss.app`
   - ⚠️ Must match `ios/Runner/Info.plist` CFBundleIdentifier
6. Click "Add app"

**Note the App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ`)

---

## Step 3: Create Ad Units

SortBliss uses two types of ads:

1. **Rewarded Ads** - Users watch video to earn bonus coins (primary revenue driver)
2. **Interstitial Ads** - Full-screen ads shown between levels (secondary revenue)

### 3.1 Create Rewarded Ad Unit (Android)

1. In AdMob Console, go to "Apps"
2. Click on your Android app (SortBliss)
3. Click "Ad units" tab
4. Click "Add ad unit"
5. Select "Rewarded" ad format
6. **Ad unit name:** `Rewarded Bonus Coins`
7. **Reward amount:** 100
8. **Reward item:** Bonus Coins
9. Click "Create ad unit"

**Save this Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/1111111111`)

### 3.2 Create Interstitial Ad Unit (Android)

1. Click "Add ad unit"
2. Select "Interstitial" ad format
3. **Ad unit name:** `Level Complete Interstitial`
4. Click "Create ad unit"

**Save this Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/2222222222`)

### 3.3 Create Rewarded Ad Unit (iOS)

1. Go back to "Apps" and select your iOS app
2. Click "Ad units" > "Add ad unit"
3. Select "Rewarded" ad format
4. **Ad unit name:** `Rewarded Bonus Coins`
5. **Reward amount:** 100
6. **Reward item:** Bonus Coins
7. Click "Create ad unit"

**Save this Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/3333333333`)

### 3.4 Create Interstitial Ad Unit (iOS)

1. Click "Add ad unit"
2. Select "Interstitial" ad format
3. **Ad unit name:** `Level Complete Interstitial`
4. Click "Create ad unit"

**Save this Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/4444444444`)

---

## Step 4: Configure App with Production Ad Unit IDs

### 4.1 Update ad_manager.dart

Edit `/home/user/sortbliss/lib/core/monetization/ad_manager.dart`:

Find these test ad unit IDs:

```dart
// ANDROID TEST IDS - REPLACE WITH PRODUCTION
static const String _androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
static const String _androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

// IOS TEST IDS - REPLACE WITH PRODUCTION
static const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';
static const String _iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
```

Replace with your production ad unit IDs from Step 3:

```dart
// ANDROID PRODUCTION IDS
static const String _androidRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/1111111111'; // Your Android Rewarded ID
static const String _androidInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/2222222222'; // Your Android Interstitial ID

// IOS PRODUCTION IDS
static const String _iosRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/3333333333'; // Your iOS Rewarded ID
static const String _iosInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/4444444444'; // Your iOS Interstitial ID
```

### 4.2 Update App IDs in Configuration Files

#### Android: Update AndroidManifest.xml

Edit `android/app/src/main/AndroidManifest.xml`:

Find this line:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

Replace with your Android App ID from Step 2.1:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

#### iOS: Update Info.plist

Edit `ios/Runner/Info.plist`:

Find this section:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

Replace with your iOS App ID from Step 2.2:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ</string>
```

---

## Step 5: Test Production Ads

### 5.1 Enable Test Mode for Your Device

**Important:** AdMob restricts ad serving to protect against invalid traffic. Add your test device to avoid account suspension.

#### Get Your Device Test ID

**Android:**
```bash
adb logcat | grep "AdRequest"
```

Look for output like:
```
Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))
```

**iOS:**
Run app in Xcode and check console for:
```
GADMobileAds: To get test ads on this device, set: GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers = @[ @"2077ef9a63d2b398840261c8221a0c9b" ];
```

#### Add Test Device in AdMob Console

1. Go to AdMob Console > "Settings" > "Test devices"
2. Click "Add test device"
3. **Platform:** Android or iOS
4. **Device name:** My Test Phone
5. **Device ID:** Paste the ID from above
6. Click "Save"

### 5.2 Build and Test

```bash
flutter clean
flutter pub get
flutter run --release
```

**Verify:**
1. Open app and navigate to Shop > Bonus Coins
2. Tap "Watch Ad for 100 Coins"
3. **Expected:** Real ad loads (not test ad waterfall)
4. Complete ad and verify 100 coins added
5. Play through levels and verify interstitial ads load

**Warning Signs:**
- ❌ No ads loading: Check ad unit IDs are correct
- ❌ Test ads still showing: Check App IDs in manifest/plist
- ❌ "Ad failed to load" error: Check internet connection and AdMob console

---

## Step 6: Enable App-ads.txt (Critical for Revenue)

App-ads.txt prevents fraudulent ad inventory and is **required** for maximum eCPM rates.

### 6.1 Generate app-ads.txt

1. In AdMob Console, go to "Settings" > "Account information"
2. Scroll to "app-ads.txt" section
3. Click "How to set up app-ads.txt"
4. Copy the generated app-ads.txt content (looks like):

```
google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
```

### 6.2 Publish app-ads.txt

**If you have a developer website:**

Upload app-ads.txt to the root of your domain:
```
https://yourdomain.com/app-ads.txt
```

**If you don't have a website:**

You can defer this until after launch, but eCPM rates will be ~30% lower without it.

Temporary solution: Create a free GitHub Pages site or use Firebase Hosting.

---

## Step 7: Configure Ad Mediation (Optional - Increases Revenue 20-40%)

AdMob mediation allows you to serve ads from multiple ad networks, increasing fill rate and eCPM.

### 7.1 Enable Mediation

1. In AdMob Console, go to "Mediation"
2. Click "Create mediation group"
3. **Ad format:** Rewarded
4. **Platform:** Android or iOS
5. **Targeting:** All apps
6. Click "Continue"

### 7.2 Add Ad Sources

**Recommended networks for casual mobile games:**
- **Meta Audience Network** (Facebook) - Best for rewarded ads
- **Unity Ads** - Good for gaming apps
- **AppLovin** - High eCPM for casual games
- **Vungle** - Premium video ads

**Setup for each network:**
1. Create account with ad network
2. Add their SDK to your app (follow their integration guide)
3. Get placement/app IDs from their console
4. Add to AdMob mediation group
5. Set eCPM floor prices

**Expected Revenue Lift:** 20-40% increase in total ad revenue

---

## Step 8: Configure Payment Information

### 8.1 Set Up Payments

1. In AdMob Console, go to "Payments"
2. Click "Set up payments"
3. **Country:** Select your country
4. **Timezone:** Select your timezone
5. **Account type:** Individual or Business
6. Click "Continue"

### 8.2 Add Payment Method

1. Choose payment method:
   - **Electronic Funds Transfer (EFT)** - Direct bank deposit (recommended)
   - **Wire transfer** - For large payments (>$10K/month)
   - **Checks** - Mailed checks (slowest)
2. Enter your bank account information
3. Verify your account (small test deposit)

### 8.3 Set Payment Threshold

**Default:** $100 minimum payout

You'll receive payment when earnings reach $100, typically 21 days after month end.

---

## Step 9: Monitor Performance

### 9.1 Key Metrics to Track

**In AdMob Console > "Reports":**

1. **Impressions** - How many ads shown
2. **Click-through rate (CTR)** - Percentage of users clicking ads
3. **eCPM** - Earnings per 1000 impressions (target: $5-15 for rewarded)
4. **Fill rate** - Percentage of ad requests filled (target: >90%)
5. **Estimated earnings** - Total revenue

### 9.2 Set Up Alerts

1. Go to "Settings" > "Email alerts"
2. Enable alerts for:
   - Policy violations
   - Payment issues
   - Significant revenue changes

---

## Troubleshooting

### "Ad failed to load: 3 (No fill)"

**Cause:** AdMob has no ads to serve for your region/user

**Solutions:**
1. Wait 24 hours after creating ad units (AdMob needs time to activate)
2. Test in different geographic region
3. Ensure app is approved in App Store/Play Store
4. Check AdMob account status (not suspended)

### "Invalid ad unit ID"

**Cause:** Ad unit ID doesn't match AdMob console

**Solutions:**
1. Double-check IDs in ad_manager.dart match AdMob console exactly
2. Ensure App IDs in AndroidManifest.xml and Info.plist are correct
3. Rebuild app: `flutter clean && flutter pub get && flutter run --release`

### "Ad serving limited due to invalid traffic"

**Cause:** AdMob detected suspicious activity (too many clicks, bot traffic)

**Solutions:**
1. Never click your own ads (use test devices only)
2. Don't incentivize users to click ads (against policy)
3. Contact AdMob support to review account
4. May take 30 days to automatically resolve

### Low eCPM rates (<$1)

**Causes:**
- No app-ads.txt configured
- Poor user engagement (short session times)
- Low-value geographic regions

**Solutions:**
1. Set up app-ads.txt (Step 6)
2. Enable ad mediation (Step 7)
3. Improve app retention and engagement
4. Target high-value countries (US, UK, Canada, Australia)

---

## Policy Compliance

**Critical AdMob policies:**

1. ✅ **No accidental clicks** - Ads must be clearly distinguishable from content
2. ✅ **No incentivized clicks** - Can't reward users for clicking ads (only watching)
3. ✅ **No misleading ad placement** - Ads can't trick users into clicking
4. ✅ **Children's content** - Must comply with COPPA if targeting kids <13
5. ✅ **Rewarded ads only** - Can incentivize watching rewarded ads, not clicking

**SortBliss is compliant:**
- Rewarded ads clearly labeled "Watch Ad for 100 Coins"
- Interstitial ads shown at natural break points (between levels)
- No misleading placement

---

## Revenue Optimization Tips

### 1. Frequency Capping

Don't show too many ads - reduces user satisfaction.

**Recommended:**
- Rewarded ads: Unlimited (user-initiated)
- Interstitial ads: Max 1 per 3 minutes

### 2. Strategic Placement

**Best times to show ads:**
- After level completion (interstitial)
- When user runs out of resources (rewarded)
- After achievements unlocked (interstitial)

**Avoid:**
- During active gameplay
- During tutorials
- On first app launch

### 3. A/B Test Ad Formats

Use Firebase Remote Config to test:
- Rewarded ad frequency
- Interstitial ad frequency
- Ad placement locations
- Reward amounts

### 4. Seasonal Optimization

eCPM rates vary by season:
- **Highest:** November-December (holiday shopping season)
- **Lowest:** January-February (post-holiday)

Plan major marketing pushes for Q4 to maximize revenue.

---

## Expected Revenue Timeline

**Week 1:** $0-5/day (learning phase, limited ad serving)
**Month 1:** $50-200 total (AdMob builds user history)
**Month 3:** $200-500/month (stable ad serving)
**Month 6:** $500-2000/month (with 5,000-10,000 DAU and optimizations)

**Scaling factors:**
- Daily Active Users (DAU)
- Average session length
- Ad frequency settings
- Geographic user distribution
- Ad mediation partners

---

## Next Steps After Setup

1. **Monitor for 1 week** - Check AdMob console daily for policy violations
2. **Optimize ad placements** - Use Firebase Analytics to track ad engagement
3. **Enable mediation** - Add Meta Audience Network and Unity Ads (20-40% revenue boost)
4. **Set up app-ads.txt** - Critical for maximum eCPM
5. **Submit for App Store/Play Store review** - Production ads require published app

---

## AdMob Console URLs

- **Main Dashboard:** https://apps.admob.com/
- **Ad Units:** https://apps.admob.com/v2/apps/list/ad_units
- **Mediation:** https://apps.admob.com/v2/mediation
- **Reports:** https://apps.admob.com/v2/reporting/home
- **Payments:** https://apps.admob.com/v2/payments

---

## Summary Checklist

After completing this guide, you will have:
- ✅ AdMob account created and linked to Firebase
- ✅ Android and iOS apps registered in AdMob
- ✅ 4 production ad unit IDs created (2 rewarded, 2 interstitial)
- ✅ Ad unit IDs configured in ad_manager.dart
- ✅ App IDs configured in AndroidManifest.xml and Info.plist
- ✅ Test devices registered to avoid policy violations
- ✅ Production ads tested and verified
- ✅ Payment information configured
- ✅ Performance monitoring set up

**Estimated Time:** 45-60 minutes (first-time setup)

**Status Check:**
```bash
# Verify production ad unit IDs are configured
grep "ca-app-pub-" lib/core/monetization/ad_manager.dart
grep "ca-app-pub-" android/app/src/main/AndroidManifest.xml
grep "ca-app-pub-" ios/Runner/Info.plist

# Should show YOUR ad unit IDs, not test IDs (3940256099942544)
```

---

**Questions?** Check [AdMob Help Center](https://support.google.com/admob) or AdMob Community Forums.
