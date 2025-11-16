# SortBliss Testing Guide
## Complete Setup & Validation for Demo-Ready Deployment

**Last Updated:** 2025-11-16
**Target:** Get SortBliss running and testable within 24 hours
**Goal:** Validate all premium features and $1.1M valuation claims with live data

---

## Table of Contents
1. [Prerequisites & System Requirements](#prerequisites--system-requirements)
2. [Quick Start (5-Minute Setup)](#quick-start-5-minute-setup)
3. [Detailed Setup Instructions](#detailed-setup-instructions)
4. [Running on Emulators](#running-on-emulators)
5. [Feature Testing Scenarios](#feature-testing-scenarios)
6. [Expected Behavior vs Common Bugs](#expected-behavior-vs-common-bugs)
7. [Performance Benchmarks](#performance-benchmarks)
8. [Troubleshooting Guide](#troubleshooting-guide)

---

## Prerequisites & System Requirements

### Required Software

#### Flutter SDK
- **Version Required:** 3.6.0 or higher
- **Installation:** https://docs.flutter.dev/get-started/install
- **Verify:** `flutter --version`
- **Expected Output:** `Flutter 3.6.0` or higher

#### Platform SDKs

**For Android Testing:**
- **Android Studio** Hedgehog (2023.1.1) or later
- **Android SDK** API Level 23+ (Android 6.0+)
- **Java Development Kit (JDK)** 17+
- **Android Emulator** with Google Play Services
- **Verify:** `flutter doctor --android-licenses`

**For iOS Testing (macOS only):**
- **Xcode** 15.0 or later
- **CocoaPods** 1.11.0 or later (`sudo gem install cocoapods`)
- **iOS Simulator** iOS 12.0+
- **Verify:** `xcode-select -p` and `pod --version`

### System Requirements

**Minimum:**
- **RAM:** 8GB (16GB recommended for smooth emulation)
- **Storage:** 10GB free space
- **CPU:** 4 cores (8+ cores recommended)
- **OS:** Windows 10+, macOS 11+, or Ubuntu 20.04+

**Network:**
- Active internet connection for first-time dependency download
- Access to Supabase backend (if testing AI/daily challenges)
- Access to Google Play Services (for ads/IAP testing)

### Optional Tools
- **VS Code** with Flutter/Dart extensions
- **Android Studio** with Flutter plugin
- **Flipper** for advanced debugging
- **Charles Proxy** for network traffic inspection

---

## Quick Start (5-Minute Setup)

### 1. Clone & Navigate
```bash
cd /home/user/sortbliss
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Create Environment Configuration
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with minimal working config
# For basic gameplay testing, you can leave most values empty
# The app gracefully degrades without backend services
```

**Minimal .env for Offline Testing:**
```env
SUPABASE_URL=
SUPABASE_FUNCTIONS_URL=
SUPABASE_SESSION_TOKEN=
SUPABASE_ANON_KEY=
SUPABASE_DAILY_CHALLENGE_ENDPOINT=
OPENAI_SESSION_TOKEN=
GEMINI_SESSION_TOKEN=
ANTHROPIC_SESSION_TOKEN=
PERPLEXITY_SESSION_TOKEN=
OPENAI_BASE_URL=https://api.openai.com/v1
```

### 4. Verify Setup
```bash
flutter doctor -v
```

**Expected:** All checkmarks except for optional items

### 5. Launch on Emulator
```bash
# List available devices
flutter devices

# Run on first available device
flutter run

# Or specify a device
flutter run -d <device-id>
```

### 6. Quick Smoke Test
Once the app launches:
1. ✅ Splash screen appears (1-2 seconds)
2. ✅ Main menu loads with player stats
3. ✅ Tap "Play" button
4. ✅ Gameplay screen loads with sortable items
5. ✅ Drag an item to a container
6. ✅ Observe scoring and visual feedback

**If all 6 steps work:** You're ready to proceed with detailed testing!

---

## Detailed Setup Instructions

### Step 1: Environment Configuration

#### Create .env File
```bash
cp .env.example .env
```

#### Configuration Levels

**Level 1: Offline Mode (No Backend)**
- Perfect for testing core gameplay, UI/UX, and local features
- Leave all environment variables empty or use placeholders
- Features available: Gameplay, settings, achievements (local), audio, haptics

**Level 2: Backend Integration (Supabase)**
- Required for: Daily challenges, AI features, cloud sync
- Obtain Supabase credentials from your project dashboard
- Set: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_DAILY_CHALLENGE_ENDPOINT`

**Level 3: Full Production (All Services)**
- Required for: AI chat, multi-provider support
- Configure: All Supabase + provider tokens (managed server-side)
- Note: API keys should remain in Supabase Edge Functions, not in .env

#### Sample Full .env Configuration
```env
# Supabase Configuration
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_FUNCTIONS_URL=https://xxxxx.functions.supabase.co
SUPABASE_SESSION_TOKEN=
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_DAILY_CHALLENGE_ENDPOINT=https://xxxxx.supabase.co/rest/v1/daily_challenges

# Provider Tokens (ephemeral, managed by edge functions)
OPENAI_SESSION_TOKEN=
GEMINI_SESSION_TOKEN=
ANTHROPIC_SESSION_TOKEN=
PERPLEXITY_SESSION_TOKEN=

# Optional Overrides
OPENAI_BASE_URL=https://api.openai.com/v1
```

### Step 2: Install Flutter Dependencies

```bash
# Install all Dart packages
flutter pub get

# Verify no dependency conflicts
flutter pub outdated
```

**Expected Duration:** 30-120 seconds (depending on network speed)

**Critical Dependencies Installed:**
- `in_app_purchase` ^3.2.0 - IAP functionality
- `google_mobile_ads` ^5.2.0 - Ad monetization
- `share_plus` ^10.0.2 - Social sharing
- `audioplayers` ^6.5.1 - Audio playback
- `flutter_dotenv` ^5.1.0 - Environment management
- `dio` ^5.4.0 - HTTP client
- 20+ additional packages (see pubspec.yaml)

### Step 3: Platform-Specific Setup

#### Android Setup

**1. Configure Gradle**
```bash
cd android
./gradlew clean
cd ..
```

**2. Accept Android Licenses**
```bash
flutter doctor --android-licenses
# Press 'y' to accept all licenses
```

**3. Verify AndroidManifest.xml Permissions**
File: `android/app/src/main/AndroidManifest.xml`
```xml
<!-- Required Permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Optional (for advanced features) -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**4. Test Build (Optional)**
```bash
flutter build apk --debug
```

#### iOS Setup (macOS only)

**1. Install CocoaPods Dependencies**
```bash
cd ios
pod install --repo-update
cd ..
```

**2. Configure Xcode Project**
```bash
open ios/Runner.xcworkspace
```

In Xcode:
- Select "Runner" project
- Go to "Signing & Capabilities"
- Select your Team or use automatic signing
- Verify Bundle Identifier: `com.sortbliss.app`

**3. Verify Info.plist Permissions**
File: `ios/Runner/Info.plist`
```xml
<key>NSCameraUsageDescription</key>
<string>Camera for gesture detection</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone for voice commands</string>
```

**4. Test Build (Optional)**
```bash
flutter build ios --debug --no-codesign
```

### Step 4: Verify Installation

```bash
flutter doctor -v
```

**Expected Output (All Green):**
```
[✓] Flutter (Channel stable, 3.6.0, on macOS/Windows/Linux)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS (macOS only)
[✓] Chrome - develop for the web
[✓] Android Studio
[✓] VS Code
[✓] Connected device
```

**Acceptable Warnings:**
- HTTP proxy warnings (can be ignored)
- Optional VS Code/Android Studio (if using other IDEs)

---

## Running on Emulators

### Android Emulator

#### Create a Test Device
```bash
# List available Android Virtual Devices (AVDs)
flutter emulators

# Create a new AVD if none exist
flutter emulators --create

# Or use Android Studio:
# Tools > Device Manager > Create Virtual Device
```

**Recommended AVD Configuration:**
- **Device:** Pixel 7 Pro or Pixel 5
- **System Image:** Android 13 (API 33) with Google Play
- **RAM:** 4GB
- **Storage:** 8GB
- **Enable:** Hardware keyboard, Device frame

#### Launch Emulator
```bash
# Start specific emulator
flutter emulators --launch <emulator-id>

# Or use Android Studio Device Manager
```

#### Run App on Android
```bash
# Auto-detect and launch
flutter run

# Specific device
flutter run -d <android-device-id>

# Hot reload enabled by default (press 'r' to reload, 'R' for restart)
```

**Expected Launch Time:** 10-30 seconds (first launch), 3-5 seconds (subsequent)

#### Android-Specific Testing Notes
- **Minimum SDK:** API 23 (Android 6.0) - tested on 6.0+
- **Target SDK:** Follows Flutter defaults
- **Permissions:** Will auto-request on first use (camera, microphone)
- **Ad Testing:** Uses Google test ad units (see logs for ad IDs)

### iOS Simulator (macOS only)

#### List Available Simulators
```bash
xcrun simctl list devices available
```

#### Launch Simulator
```bash
# Open default simulator
open -a Simulator

# Or specify iOS version
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator
```

**Recommended Simulator:**
- **Device:** iPhone 15 Pro or iPhone 14
- **iOS Version:** 16.0 or later
- **Why:** Modern performance, representative of target audience

#### Run App on iOS
```bash
# Auto-detect and launch
flutter run

# Specific device
flutter run -d <ios-simulator-id>

# For physical device (requires Apple Developer account)
flutter run -d <iphone-device-id>
```

**Expected Launch Time:** 15-45 seconds (first launch), 5-10 seconds (subsequent)

#### iOS-Specific Testing Notes
- **Minimum iOS:** 12.0
- **Orientation:** Portrait enforced (landscape disabled in code)
- **Permissions:** Will show permission dialogs on first use
- **Haptic Testing:** Requires physical device (simulators don't vibrate)

### Hot Reload Workflow

**Development Commands:**
- **`r`** - Hot reload (preserves app state, updates UI)
- **`R`** - Hot restart (resets app state, full reload)
- **`p`** - Show widget hierarchy (debug)
- **`o`** - Toggle platform (Android/iOS rendering)
- **`w`** - Dump widget hierarchy to console
- **`q`** - Quit

**Best Practice:** Use `r` for UI tweaks, `R` after code structure changes

---

## Feature Testing Scenarios

### 1. Core Gameplay Testing

#### Test Scenario 1.1: Basic Sorting Mechanics
**Objective:** Verify drag-and-drop functionality and scoring

**Steps:**
1. Launch app and tap "Play" from main menu
2. Wait for gameplay screen to load (shows 8 emoji items)
3. **Drag** any item from the central pile
4. **Drop** it into one of the 4 category containers
5. Observe visual feedback (particles, sound, score update)
6. Repeat for 5-8 items
7. Complete the level by sorting all items correctly

**Expected Behavior:**
- ✅ Items snap to containers with haptic feedback
- ✅ Score increases (+100 base points per item)
- ✅ Combo counter appears after 2+ consecutive correct placements
- ✅ Particle effects (sparkles) on successful drop
- ✅ Sound effects: `item_drop.mp3` on placement
- ✅ HUD updates in real-time (score, moves, time)
- ✅ Level completes when all items sorted

**Common Bugs:**
- ❌ Items get stuck mid-drag (release and retry)
- ❌ No haptic feedback on drop (check Settings > Haptics enabled)
- ❌ Audio not playing (check Settings > Sound Effects enabled)
- ❌ Score not updating (restart level with `R`)

**Performance Metrics:**
- **FPS:** Should maintain 60 FPS during drag operations
- **Response Time:** <16ms from touch to visual feedback
- **Memory:** <150MB RAM usage during gameplay

#### Test Scenario 1.2: Combo & Streak System
**Objective:** Validate scoring multipliers

**Steps:**
1. Start a new level
2. Sort 3+ items **consecutively** without errors
3. Observe combo counter (e.g., "3x COMBO!")
4. Make an incorrect placement (break combo)
5. Observe combo reset
6. Build combo again to 5x

**Expected Behavior:**
- ✅ Combo counter appears after 2nd consecutive correct placement
- ✅ Multiplier increases: 2x, 3x, 4x, 5x (max)
- ✅ Score multiplied by combo value (e.g., 100 × 3 = 300 points)
- ✅ Visual celebration for 5x combo (confetti, screen shake)
- ✅ Combo resets to 0 on incorrect placement
- ✅ Sound effect: `success_pop.mp3` on combo milestone

**Common Bugs:**
- ❌ Combo counter stuck at 1x (check game state reset)
- ❌ Multiplier not applying to score (verify scoring logic)

#### Test Scenario 1.3: Adaptive Tutorial
**Objective:** First-time user onboarding experience

**Steps:**
1. **Reset app data** to trigger tutorial:
   - Android: Settings > Apps > SortBliss > Clear Data
   - iOS: Uninstall and reinstall
2. Launch app and start first level
3. Observe tutorial overlay with gesture guidance
4. Follow tutorial instructions (drag, drop)
5. Complete tutorial steps (3-5 guided actions)

**Expected Behavior:**
- ✅ Tutorial appears only on first gameplay session
- ✅ Animated hand gesture shows drag path
- ✅ Text instructions: "Drag items to matching containers"
- ✅ Tutorial dismisses after 3 successful placements
- ✅ Never shows again (stored in SharedPreferences)

**Common Bugs:**
- ❌ Tutorial repeats every level (check persistence logic)
- ❌ Tutorial blocks all interactions (should allow guided actions)

### 2. In-App Purchases (IAP) Testing

#### Test Scenario 2.1: Product Catalog
**Objective:** Verify IAP product loading

**Steps:**
1. Navigate to Main Menu
2. Tap "Store" or "Shop" button (if available)
   - **Note:** Storefront UI is currently placeholder ("Coming soon")
3. Check logs for IAP initialization:
   ```
   flutter run | grep -i "purchase\|iap\|product"
   ```

**Expected Behavior:**
- ✅ 5 products loaded:
  - `sortbliss_remove_ads` (Non-consumable)
  - `sortbliss_coin_pack_small` (Consumable, 250 coins)
  - `sortbliss_coin_pack_large` (Consumable, 750 coins)
  - `sortbliss_coin_pack_epic` (Consumable, 2000 coins)
  - `sortbliss_sort_pass_premium` (Non-consumable)
- ✅ Products have titles, descriptions, prices (from Google Play/App Store)
- ✅ Analytics event: `iap_products_loaded` (check logs)

**Common Bugs:**
- ❌ Products fail to load (requires Google Play/App Store connection)
- ❌ Test environment shows "Item not available" (use Google Play Console test tracks)

#### Test Scenario 2.2: Purchase Flow (Sandbox Testing)
**Objective:** Complete a test purchase

**Prerequisites:**
- **Android:** Add test account in Google Play Console
- **iOS:** Sandbox tester account in App Store Connect

**Steps:**
1. Open Store/Shop screen
2. Select a product (e.g., "250 Coins")
3. Tap "Buy" button
4. Complete sandbox purchase flow (test payment)
5. Observe purchase success confirmation
6. Check coin balance updates (Main Menu > Player Stats)

**Expected Behavior:**
- ✅ Native purchase dialog appears (Google Play/App Store)
- ✅ Sandbox test account charged (no real money)
- ✅ Purchase success: Coins added to player balance
- ✅ Analytics events:
  - `iap_purchase_initiated`
  - `iap_purchase_success`
  - `iap_coins_delivered` (if consumable)
- ✅ Persistent storage: Purchase saved in SharedPreferences
- ✅ UI updates immediately (no app restart required)

**Common Bugs:**
- ❌ "Pending" state never resolves (restart app to retry)
- ❌ Coins not added (check entitlement delivery logic)
- ❌ Duplicate purchases allowed for non-consumables (verify purchase verification)

#### Test Scenario 2.3: Restore Purchases
**Objective:** Verify purchase restoration on new device

**Steps:**
1. Complete a non-consumable purchase (e.g., "Remove Ads")
2. **Uninstall** the app
3. **Reinstall** the app
4. Navigate to Store/Shop
5. Tap "Restore Purchases" button
6. Observe purchase restoration

**Expected Behavior:**
- ✅ Previous non-consumable purchases restored
- ✅ Consumables **not** restored (by design)
- ✅ Analytics event: `iap_restore_initiated`, `iap_restore_success`
- ✅ UI reflects restored entitlements (e.g., ads disabled)

**Common Bugs:**
- ❌ Restore button missing (check UI implementation)
- ❌ Restore fails silently (check error handling in logs)

### 3. Advertising Testing

#### Test Scenario 3.1: Rewarded Ad Flow
**Objective:** Watch ad, receive reward

**Steps:**
1. Play a level and complete it
2. On Level Complete screen, tap "Watch Ad for 2x Coins" (if available)
3. Observe ad loading
4. Watch ad to completion (30 seconds)
5. Close ad
6. Verify coin reward granted

**Expected Behavior:**
- ✅ Ad loads within 3 seconds
- ✅ Test ad shows (Google test creative)
- ✅ "Skip Ad" button appears after 5 seconds (for test ads)
- ✅ Coins doubled upon ad completion
- ✅ Analytics events:
  - `ad_rewarded_load_success`
  - `ad_rewarded_show`
  - `ad_rewarded_impression`
  - `ad_rewarded_earned_reward` (coins: 2x)
- ✅ User can decline ad (no penalty)

**Common Bugs:**
- ❌ Ad fails to load (network issue or test ID misconfiguration)
- ❌ Reward not granted (check AdManager callback logic)
- ❌ App crashes after ad closes (test error handling)

#### Test Scenario 3.2: Interstitial Ad Flow
**Objective:** Verify non-intrusive interstitial placement

**Steps:**
1. Complete 3-5 levels consecutively
2. Observe interstitial ad appearance (frequency controlled)
3. Close ad after viewing
4. Return to game flow

**Expected Behavior:**
- ✅ Interstitials show after every 3-5 levels (configurable)
- ✅ Skippable after 5 seconds
- ✅ Does **not** interrupt active gameplay
- ✅ Analytics events: `ad_interstitial_show`, `ad_interstitial_impression`
- ✅ User can close ad immediately (X button)

**Common Bugs:**
- ❌ Ads show too frequently (adjust frequency logic)
- ❌ Ads interrupt gameplay mid-level (timing issue)

#### Test Scenario 3.3: Ad-Free Entitlement
**Objective:** Verify "Remove Ads" IAP disables ads

**Steps:**
1. Purchase "Remove Ads" IAP (sandbox)
2. Complete a level (trigger interstitial check)
3. Observe no ads shown
4. Try to watch rewarded ad
5. Verify rewarded ads **still available** (by design)

**Expected Behavior:**
- ✅ Interstitial ads **completely disabled** after purchase
- ✅ Rewarded ads **still available** (user opt-in)
- ✅ Analytics event: `ad_free_activated`
- ✅ Purchase persists across app restarts

**Common Bugs:**
- ❌ Ads still show after purchase (check entitlement logic)
- ❌ Rewarded ads also disabled (should remain available)

### 4. Analytics & KPI Testing

#### Test Scenario 4.1: Event Logging
**Objective:** Verify analytics instrumentation

**Steps:**
1. Run app with verbose logging:
   ```bash
   flutter run | tee analytics_log.txt
   ```
2. Perform actions:
   - Start a level
   - Complete a level
   - Make a purchase
   - Watch an ad
   - Change settings
3. Search logs for analytics events:
   ```bash
   grep "Analytics" analytics_log.txt
   ```

**Expected Events (Sample):**
- `app_open` - App launch
- `level_start` - Gameplay initiated
- `level_complete` - Level finished (with stars, score, time)
- `iap_purchase_initiated` - Purchase flow started
- `ad_rewarded_earned_reward` - Rewarded ad completed
- `settings_changed` - User preferences updated
- `achievement_unlocked` - Achievement triggered
- `share_initiated` - Social share action

**Expected Behavior:**
- ✅ All events include timestamp
- ✅ Events include relevant context (level number, score, etc.)
- ✅ No PII (personally identifiable information) logged
- ✅ Events sent to AnalyticsService (currently debug print)

**Common Bugs:**
- ❌ Duplicate events (check event deduplication)
- ❌ Missing required parameters (validate event schema)

#### Test Scenario 4.2: KPI Dashboard Verification
**Objective:** Validate business metrics calculation

**Prerequisites:** Complete 10-20 levels with varied performance

**Steps:**
1. Navigate to Settings or Profile screen
2. View "Analytics" or "Stats" section (if available)
3. Verify displayed metrics:
   - Levels Completed: 47
   - Current Streak: 12
   - Coins Earned: 2,850
   - Achievements Unlocked: 2

**Expected Behavior:**
- ✅ Metrics match actual gameplay (persistent storage)
- ✅ Metrics update in real-time during session
- ✅ Metrics survive app restart (SharedPreferences)

**Common Bugs:**
- ❌ Metrics reset on app restart (persistence failure)
- ❌ Metrics out of sync with actual actions (update logic)

### 5. Daily Challenge Testing

#### Test Scenario 5.1: Daily Challenge Fetch
**Objective:** Load daily challenge from backend

**Prerequisites:** Supabase configured in .env

**Steps:**
1. From Main Menu, tap "Daily Challenge" widget
2. Observe loading state (spinner)
3. Wait for challenge data to load (1-3 seconds)
4. Verify challenge details displayed:
   - Title (e.g., "Aurora Monday Challenge")
   - Description
   - Target (e.g., "Earn 3 stars")
   - Rewards (coins, skins)
   - Countdown timer

**Expected Behavior:**
- ✅ Challenge loads from Supabase REST API
- ✅ Fallback to local challenge if network fails
- ✅ Countdown timer shows time until reset (24 hours)
- ✅ Challenge cached for 1 hour (TTL)
- ✅ Analytics event: `daily_challenge_loaded`

**Common Bugs:**
- ❌ Challenge fails to load (check Supabase URL in .env)
- ❌ Countdown timer incorrect (timezone issue)
- ❌ No fallback challenge (verify local data)

#### Test Scenario 5.2: Challenge Completion
**Objective:** Complete daily challenge and claim rewards

**Steps:**
1. Start daily challenge
2. Complete level meeting target criteria (e.g., 3 stars)
3. Observe completion state
4. Tap "Claim Reward" button
5. Verify rewards added to account

**Expected Behavior:**
- ✅ Challenge marked as complete (checkmark icon)
- ✅ Rewards breakdown shown (coins, exclusive items)
- ✅ "Claim Reward" button enabled
- ✅ Rewards added to player profile (coins +500, etc.)
- ✅ Analytics event: `daily_challenge_complete`, `daily_challenge_reward_claimed`
- ✅ Challenge grayed out until next reset

**Common Bugs:**
- ❌ Rewards claimable multiple times (verify claim state)
- ❌ Challenge resets prematurely (check reset logic)

### 6. Social Sharing Testing

#### Test Scenario 6.1: Progress Sharing
**Objective:** Share achievement to social platforms

**Steps:**
1. Complete a level with high score (3 stars)
2. On Level Complete screen, tap "Share" button
3. Select sharing platform (WhatsApp, Twitter, etc.)
4. Verify shared content format
5. Complete share action
6. Return to app

**Expected Behavior:**
- ✅ Native share sheet appears (platform-specific)
- ✅ Share text includes:
  - "I just scored [X] points on SortBliss!"
  - "Beat my score: [App Store link]"
- ✅ Share count increments in player profile
- ✅ Analytics event: `share_initiated`, `share_completed`
- ✅ Achievement "Social Butterfly" unlocks after 3 shares

**Common Bugs:**
- ❌ Share sheet doesn't open (check share_plus permissions)
- ❌ Share count not incrementing (verify persistence)

#### Test Scenario 6.2: Referral Tracking (Future)
**Objective:** Verify referral link generation

**Steps:**
1. Tap "Invite Friends" (if available)
2. Generate referral link
3. Copy link to clipboard
4. Share via messaging app

**Expected Behavior:**
- ✅ Unique referral link generated (includes user ID)
- ✅ Link format: `https://sortbliss.app/ref?code=ABC123`
- ✅ Analytics event: `referral_link_generated`

**Note:** Full referral attribution requires backend integration (not yet implemented)

### 7. Settings & Preferences Testing

#### Test Scenario 7.1: Audio Settings
**Objective:** Toggle sound effects and music

**Steps:**
1. Navigate to Settings screen
2. Toggle "Sound Effects" OFF
3. Return to gameplay
4. Observe no sound effects on item placement
5. Return to Settings
6. Toggle "Background Music" OFF
7. Observe music stops

**Expected Behavior:**
- ✅ Settings persist across app restarts
- ✅ Immediate effect (no app restart required)
- ✅ Independent controls (music vs effects)
- ✅ Analytics event: `settings_changed` (audio: false)

**Common Bugs:**
- ❌ Settings reset on restart (SharedPreferences issue)
- ❌ Music continues after toggle OFF (AudioManager state)

#### Test Scenario 7.2: Haptic Feedback
**Objective:** Test vibration settings

**Steps:**
1. Navigate to Settings
2. Toggle "Haptic Feedback" ON
3. Play a level and observe vibration on:
   - Item placement (light tap)
   - Correct placement (success impact)
   - Level complete (celebration pattern)
4. Return to Settings
5. Toggle "Haptic Feedback" OFF
6. Replay level, verify no vibration

**Expected Behavior:**
- ✅ Vibration patterns distinct for different actions
- ✅ No vibration in iOS Simulator (requires physical device)
- ✅ Android emulator may simulate (depending on AVD config)

**Common Bugs:**
- ❌ Vibration continues after toggle OFF (HapticManager state)
- ❌ Excessive vibration (adjust durations in code)

#### Test Scenario 7.3: Difficulty Adjustment
**Objective:** Modify game difficulty slider

**Steps:**
1. Navigate to Settings
2. Adjust "Difficulty" slider (0.0 to 1.0)
3. Start a new level
4. Observe gameplay changes (TBD: difficulty affects time limits, item count, etc.)

**Expected Behavior:**
- ✅ Slider position saved in SharedPreferences
- ✅ Difficulty affects gameplay parameters (implementation-dependent)
- ✅ Analytics event: `settings_changed` (difficulty: 0.75)

**Note:** Difficulty implementation may vary; verify behavior with current build

### 8. Performance & Stability Testing

#### Test Scenario 8.1: Memory Leak Detection
**Objective:** Ensure no memory leaks during extended play

**Steps:**
1. Run app with DevTools profiling:
   ```bash
   flutter run --profile
   ```
2. Open Flutter DevTools (URL shown in console)
3. Navigate to "Performance" tab
4. Play 20+ levels continuously
5. Monitor memory usage graph
6. Check for memory growth over time

**Expected Behavior:**
- ✅ Memory usage stabilizes after initial gameplay
- ✅ No continuous upward trend (leak indicator)
- ✅ Garbage collection occurs periodically (saw-tooth pattern)
- ✅ Peak memory: <200MB on mobile

**Common Bugs:**
- ❌ Memory grows indefinitely (leak in animation controllers, listeners)
- ❌ UI lag after extended play (dispose() not called)

#### Test Scenario 8.2: Frame Rate Monitoring
**Objective:** Validate 60 FPS during gameplay

**Steps:**
1. Run app with performance overlay:
   ```bash
   flutter run --profile
   ```
2. Press **`P`** in terminal to toggle performance overlay
3. Play a level with heavy visual effects (particles, confetti)
4. Observe FPS bars (green = 60 FPS, red = janky)

**Expected Behavior:**
- ✅ Consistent green bars (60 FPS)
- ✅ No red bars during normal gameplay
- ✅ Occasional yellow bars acceptable during intense effects
- ✅ UI thread: <16ms per frame
- ✅ Raster thread: <16ms per frame

**Common Bugs:**
- ❌ Frequent red bars (performance issue)
- ❌ UI thread spikes (layout thrashing, rebuild storms)
- ❌ Raster thread spikes (shader compilation, overdraw)

#### Test Scenario 8.3: Battery Usage (Physical Device)
**Objective:** Verify acceptable battery drain

**Steps:**
1. Install app on physical device (Android/iOS)
2. Charge to 100%
3. Play continuously for 30 minutes
4. Check battery level
5. Calculate drain rate

**Expected Behavior:**
- ✅ Battery drain: 10-15% per 30 minutes
- ✅ No excessive heat generation
- ✅ No "high battery usage" warnings from OS

**Common Bugs:**
- ❌ Rapid drain (>20% per 30 min) - check background tasks, animations
- ❌ Device overheating (GPU/CPU throttling)

### 9. Accessibility Testing

#### Test Scenario 9.1: Voice Commands (Optional)
**Objective:** Test speech-to-text integration

**Prerequisites:** Microphone permission granted

**Steps:**
1. Navigate to Settings
2. Enable "Voice Commands"
3. Return to gameplay
4. Speak commands: "Next", "Undo", "Pause"
5. Observe command recognition and execution

**Expected Behavior:**
- ✅ Microphone permission requested on first use
- ✅ Voice commands recognized (speech_to_text package)
- ✅ Commands execute corresponding actions
- ✅ Visual feedback for recognized commands

**Note:** Voice commands currently disabled by default; enable in settings

**Common Bugs:**
- ❌ Recognition accuracy low (ambient noise, language model)
- ❌ Commands trigger unintended actions (command mapping)

#### Test Scenario 9.2: Text-to-Speech (Optional)
**Objective:** Verify TTS for accessibility

**Steps:**
1. Enable TTS in device accessibility settings (OS-level)
2. Launch app
3. Navigate menus
4. Observe TTS announcements for buttons, labels

**Expected Behavior:**
- ✅ Screen reader announces button labels
- ✅ Game state changes announced (score updates)
- ✅ flutter_tts package provides custom announcements

**Note:** TTS implementation depends on app-level integration; verify current state

---

## Expected Behavior vs Common Bugs

### Expected Behavior Matrix

| Feature | Expected Behavior | Performance Target |
|---------|-------------------|-------------------|
| **App Launch** | Splash screen → Main Menu in 2-3 seconds | <3s cold start |
| **Level Load** | Gameplay screen ready in 1-2 seconds | <2s |
| **Drag Response** | Immediate visual feedback (<16ms) | 60 FPS maintained |
| **Scoring** | Real-time score updates on each action | <16ms update |
| **Audio** | Sound effects within 50ms of action | <50ms latency |
| **Haptics** | Vibration synced with visual feedback | <20ms delay |
| **IAP Load** | Products loaded in 1-3 seconds | <3s |
| **Ad Load** | Rewarded ad ready in 2-4 seconds | <5s |
| **Daily Challenge** | Data fetched in 1-3 seconds | <3s (with cache) |
| **Settings Change** | Immediate effect (no restart) | <100ms |
| **Achievement Unlock** | Notification appears within 500ms | <500ms |
| **Share Sheet** | Native dialog in <1 second | <1s |

### Common Bugs & Fixes

#### Startup Issues

**Bug:** App crashes on launch
- **Symptom:** White screen or instant crash
- **Cause:** Missing .env file or malformed environment variables
- **Fix:** Verify .env exists and has valid syntax (no quotes around values)

**Bug:** Stuck on splash screen
- **Symptom:** Splash screen shows indefinitely
- **Cause:** Initialization hanging (network timeout, service init failure)
- **Fix:** Check logs for error messages, verify Supabase connectivity

#### Gameplay Issues

**Bug:** Items won't drag
- **Symptom:** Items unresponsive to touch
- **Cause:** Gesture detector conflict or z-index issue
- **Fix:** Restart level, check for modal overlays blocking input

**Bug:** Score not updating
- **Symptom:** Score stuck at 0 or previous value
- **Cause:** State management issue (setState not called)
- **Fix:** Hot restart (press 'R'), verify reactive state listeners

**Bug:** No audio playback
- **Symptom:** Silence during gameplay
- **Cause:** Audio assets missing (graceful degradation active)
- **Fix:** Check `assets/audio/` directory, verify pubspec.yaml asset declarations
- **Note:** App continues to work without audio files

**Bug:** Missing haptic feedback
- **Symptom:** No vibration on actions
- **Cause:** Haptics disabled in settings or simulator (iOS)
- **Fix:** Enable in Settings > Haptic Feedback, test on physical device

#### Monetization Issues

**Bug:** IAP products not loading
- **Symptom:** Store shows "No products available"
- **Cause:** Not connected to Google Play/App Store, invalid product IDs
- **Fix:** Verify device has Play Store access, check product IDs match console setup

**Bug:** Purchase fails with "pending"
- **Symptom:** Purchase state stuck at pending
- **Cause:** Payment method issue or sandbox account misconfigured
- **Fix:** Restart app to retry, verify sandbox tester account setup

**Bug:** Ads fail to load
- **Symptom:** Error message or no ad shown
- **Cause:** Network issue, test ad ID misconfiguration, or Google Ads SDK init failure
- **Fix:** Check internet connection, verify AdMob initialization in logs

#### Backend Issues

**Bug:** Daily challenge won't load
- **Symptom:** Loading spinner indefinitely
- **Cause:** Supabase URL incorrect or network timeout
- **Fix:** Verify SUPABASE_URL in .env, check internet connection, verify fallback data

**Bug:** Analytics events not logging
- **Symptom:** No analytics output in logs
- **Cause:** AnalyticsService not initialized or event throttling
- **Fix:** Check initialization sequence, verify event parameters

#### Performance Issues

**Bug:** Low frame rate (janky animations)
- **Symptom:** Choppy UI, red bars in performance overlay
- **Cause:** Too many widgets rebuilding, expensive operations on UI thread
- **Fix:** Use `--profile` build, check DevTools timeline for bottlenecks

**Bug:** App unresponsive after extended play
- **Symptom:** Lag increasing over time
- **Cause:** Memory leak (listeners, animation controllers not disposed)
- **Fix:** Check dispose() methods, use DevTools memory profiler

---

## Performance Benchmarks

### Target Metrics (Mobile)

| Metric | Target | Acceptable | Unacceptable |
|--------|--------|------------|--------------|
| **Cold Start Time** | <2s | 2-4s | >4s |
| **Hot Start Time** | <1s | 1-2s | >2s |
| **Level Load Time** | <1.5s | 1.5-3s | >3s |
| **FPS (Gameplay)** | 60 | 45-60 | <45 |
| **FPS (Menus)** | 60 | 55-60 | <55 |
| **Memory Usage (Idle)** | <100MB | 100-150MB | >150MB |
| **Memory Usage (Active)** | <150MB | 150-200MB | >200MB |
| **IAP Load Time** | <2s | 2-4s | >4s |
| **Ad Load Time (Rewarded)** | <3s | 3-5s | >5s |
| **Daily Challenge Fetch** | <2s | 2-4s | >4s |
| **Share Sheet Open** | <0.5s | 0.5-1s | >1s |
| **Settings Save** | <100ms | 100-200ms | >200ms |

### Measurement Tools

#### DevTools Performance Profiler
```bash
# Run in profile mode
flutter run --profile

# Open DevTools (URL in console output)
# Navigate to Performance tab
# Record timeline during gameplay
# Analyze UI/Raster thread jank
```

#### Memory Profiler
```bash
# Profile mode
flutter run --profile

# DevTools > Memory
# Snapshot heap before/after gameplay
# Diff snapshots to detect leaks
# Look for retained instances of controllers, listeners
```

#### Frame Rate Overlay
```bash
# In running app terminal, press 'P'
# Green bars = 60 FPS (good)
# Yellow bars = 45-60 FPS (acceptable)
# Red bars = <45 FPS (investigate)
```

#### Build Size Analysis
```bash
# Android APK size
flutter build apk --analyze-size

# iOS IPA size
flutter build ipa --analyze-size

# Target: <50MB download size
```

### Platform-Specific Considerations

**Android:**
- **Min SDK 23:** Performance on older devices (Android 6.0) may be degraded
- **Emulator vs Physical:** Emulators typically 20-30% slower
- **Hardware Acceleration:** Ensure AVD uses hardware graphics (not software)

**iOS:**
- **Simulator vs Physical:** Simulator performance not representative (uses macOS GPU)
- **Thermal Throttling:** Extended play on physical devices may trigger throttling
- **Metal Rendering:** Leverages iOS graphics APIs for optimal performance

---

## Troubleshooting Guide

### Installation Issues

#### Flutter SDK Not Found
```bash
# Symptom: "flutter: command not found"
# Fix: Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Verify
flutter --version
```

#### Android Licenses Not Accepted
```bash
# Symptom: "Android license status unknown"
# Fix:
flutter doctor --android-licenses
# Press 'y' for all prompts
```

#### iOS CocoaPods Failure
```bash
# Symptom: "pod install" fails
# Fix 1: Update CocoaPods
sudo gem install cocoapods --pre

# Fix 2: Clear cache
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
cd ..
```

#### Dependency Conflicts
```bash
# Symptom: "version solving failed"
# Fix 1: Clean and re-fetch
flutter clean
flutter pub get

# Fix 2: Update all packages
flutter pub upgrade

# Fix 3: Check pubspec.yaml for conflicting versions
flutter pub outdated
```

### Runtime Issues

#### App Crashes on Launch
**Check logs:**
```bash
# Android
adb logcat | grep -i flutter

# iOS
open -a Console (filter by device name)
```

**Common causes:**
1. Missing .env file → Create from .env.example
2. Malformed environment variables → Remove quotes, check syntax
3. Permission issues → Grant camera/microphone permissions
4. Dependency init failure → Check logs for specific service errors

#### Black Screen After Splash
**Symptom:** App loads but shows black screen instead of Main Menu

**Fix:**
1. Hot restart: Press **'R'** in terminal
2. Check for modal overlays blocking UI
3. Verify no errors in logs (`flutter logs`)
4. Rebuild: `flutter clean && flutter run`

#### Network Errors
**Symptom:** "Failed to fetch daily challenge" or similar

**Fix:**
1. Verify internet connection
2. Check Supabase URL in .env (no trailing slash)
3. Test endpoint directly:
   ```bash
   curl https://your-project.supabase.co/rest/v1/daily_challenges
   ```
4. Verify fallback logic activates (check logs for "Using fallback challenge")

#### Permission Denied Errors
**Symptom:** "Camera permission denied" or "Microphone permission denied"

**Fix:**
1. **Android:** Settings > Apps > SortBliss > Permissions > Enable
2. **iOS:** Settings > SortBliss > Enable Camera/Microphone
3. **Emulator:** Some permissions require physical device
4. Restart app after granting permissions

### Testing Issues

#### Test Ad Units Not Showing
**Symptom:** Ads fail to load with "No fill" error

**Fix:**
1. Verify using Google test ad IDs:
   ```
   Rewarded: ca-app-pub-3940256099942544/5224354917
   Interstitial: ca-app-pub-3940256099942544/1033173712
   ```
2. Check internet connection (ads require network)
3. Wait 30-60 seconds for first ad load
4. Review logs for AdMob initialization errors

#### IAP Sandbox Not Working
**Symptom:** "Item not available" or "User canceled" immediately

**Fix:**
1. **Android:**
   - Add test account in Google Play Console > Setup > License Testing
   - Use account signed into Play Store on device
   - Product must be published to closed testing track
2. **iOS:**
   - Create sandbox tester in App Store Connect > Users and Access
   - Sign out of App Store on device
   - App will prompt for sandbox account on purchase
3. Verify product IDs match exactly in console

#### Daily Challenge Always Returns Fallback
**Symptom:** Same challenge shown every time, no countdown

**Fix:**
1. Check Supabase connection:
   ```bash
   # In .env
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbG...
   SUPABASE_DAILY_CHALLENGE_ENDPOINT=https://xxxxx.supabase.co/rest/v1/daily_challenges
   ```
2. Verify endpoint returns data:
   ```bash
   curl -H "apikey: YOUR_ANON_KEY" "https://xxxxx.supabase.co/rest/v1/daily_challenges"
   ```
3. Check for CORS issues (if using custom domain)
4. Verify cache TTL (clear app data to force refresh)

### Performance Issues

#### Low FPS During Gameplay
**Diagnosis:**
```bash
# Run with performance overlay
flutter run --profile
# Press 'P' to toggle overlay
```

**Fixes:**
1. **Emulator:** Use hardware acceleration (AVD settings)
2. **Release build:** Test with `flutter run --release` (much faster)
3. **Widget rebuilds:** Reduce setState() scope
4. **Animations:** Use `AnimatedBuilder` to limit rebuilds
5. **Images:** Ensure assets are properly sized (no runtime scaling)

#### High Memory Usage
**Diagnosis:**
```bash
# DevTools > Memory > Snapshot
# Play 10+ levels
# Take another snapshot
# Diff to find retained objects
```

**Fixes:**
1. **Controllers:** Ensure all `AnimationController`s disposed in `dispose()`
2. **Listeners:** Remove all listeners in `dispose()`
3. **Streams:** Close all `StreamController`s
4. **Images:** Use `precacheImage()` for frequently used assets

#### Slow App Startup
**Diagnosis:** Add timing logs to identify bottleneck

**Common causes:**
1. **Synchronous I/O:** Move file reads to async init
2. **Heavy initialization:** Defer non-critical service init
3. **Network calls:** Use cached data for first render
4. **Large assets:** Optimize image sizes, use lazy loading

### Platform-Specific Issues

#### Android: Gradle Build Failures
```bash
# Clear Gradle cache
cd android
./gradlew clean
cd ..

# Update Gradle wrapper
cd android
./gradlew wrapper --gradle-version=8.0
cd ..

# Rebuild
flutter clean
flutter pub get
flutter run
```

#### iOS: Code Signing Errors
**Symptom:** "Signing for 'Runner' requires a development team"

**Fix:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select "Runner" project in navigator
3. Go to "Signing & Capabilities"
4. Select a Team (Personal Team works for local testing)
5. Close Xcode and retry `flutter run`

#### iOS: Provisioning Profile Issues
**Symptom:** "No profiles for 'com.sortbliss.app'"

**Fix:**
1. Use automatic signing (Xcode > Signing & Capabilities)
2. Or manually create provisioning profile in Apple Developer portal
3. For simulators, no provisioning needed

---

## Quick Reference Commands

### Essential Flutter Commands
```bash
# Check environment setup
flutter doctor -v

# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Hot reload (in running app terminal)
r

# Hot restart (in running app terminal)
R

# Clean build artifacts
flutter clean

# Update dependencies
flutter pub get

# Run tests
flutter test

# Build APK (Android)
flutter build apk --debug

# Build for iOS simulator
flutter build ios --simulator

# Profile mode (for performance testing)
flutter run --profile

# Release mode (optimized, no debugging)
flutter run --release

# Analyze code for issues
flutter analyze

# Format code
flutter format lib/
```

### Debugging Commands
```bash
# View logs
flutter logs

# Android logs
adb logcat | grep flutter

# Clear app data (Android)
adb shell pm clear com.sortbliss.app

# iOS logs
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'

# Performance overlay (in running app)
P

# Widget inspector overlay
w

# Dump widget tree
d

# Dump render tree
t
```

### Environment Management
```bash
# Create .env from template
cp .env.example .env

# Edit .env
nano .env  # or vim, code, etc.

# Verify .env loaded
flutter run | grep -i "environment"
```

---

## Success Criteria

### Minimum Viable Demo
**Before considering the app "demo-ready," verify:**

✅ **Startup:**
- App launches without crashes
- Splash screen → Main Menu transition smooth
- Player stats visible (levels, coins, streak)

✅ **Core Gameplay:**
- Can start a level from Main Menu
- Drag-and-drop works smoothly (60 FPS)
- Scoring updates in real-time
- Level completes with results screen
- Audio and haptics functional (if enabled)

✅ **Monetization (Testable):**
- IAP products load (5 products visible)
- Can initiate test purchase (sandbox)
- Ads load (test ad units)
- Can watch rewarded ad and receive reward

✅ **Progression:**
- Settings persist across app restarts
- Achievements unlock and display
- Daily challenge loads (backend or fallback)

✅ **Performance:**
- Maintains 60 FPS during normal gameplay
- No crashes during 15-minute play session
- Memory usage <200MB

### Production Readiness Checklist
**For soft launch preparation:**

✅ **Configuration:**
- Real Supabase production URLs (not example values)
- Production ad unit IDs (replace test IDs)
- IAP products published to testing tracks
- Firebase configuration added (if needed for crashlytics)

✅ **Testing:**
- All 9 feature test scenarios passed
- Tested on 3+ different devices (Android/iOS mix)
- No critical bugs remaining
- Performance benchmarks met

✅ **Legal/Compliance:**
- Privacy policy linked in app
- Terms of service accessible
- COPPA compliance (if targeting kids)
- GDPR consent flow (if targeting EU)

✅ **Store Preparation:**
- App icon finalized (1024x1024)
- Screenshots for all device sizes
- Store listing copy written
- Age rating determined

---

## Next Steps After Testing

Once all test scenarios pass, proceed to:

1. **Review DEMO_SCRIPT.md** - Prepare 5-minute buyer walkthrough
2. **Review DEBUG_CHECKLIST.md** - Complete pre-launch QA
3. **Implement Production Hardening** - Error boundaries, telemetry
4. **Execute Quick-Win Improvements** - Polish identified during testing
5. **Build Release Candidates** - `flutter build apk --release`, `flutter build ios --release`
6. **Distribute to Testers** - Firebase App Distribution, TestFlight
7. **Iterate Based on Feedback** - Fix critical bugs, refine UX
8. **Prepare Soft Launch** - Limited rollout (1-2 countries)
9. **Monitor KPIs** - Retention, monetization, crashes
10. **Scale or Pivot** - Based on data, expand or iterate

---

## Support & Resources

### Documentation
- **Flutter Docs:** https://docs.flutter.dev
- **Firebase Setup:** https://firebase.google.com/docs/flutter/setup
- **Google Mobile Ads:** https://developers.google.com/admob/flutter/quick-start
- **In-App Purchase:** https://pub.dev/packages/in_app_purchase

### Debugging Tools
- **Flutter DevTools:** https://docs.flutter.dev/tools/devtools
- **Android Studio Profiler:** Built-in profiling tools
- **Xcode Instruments:** iOS performance analysis

### Community
- **Flutter Discord:** https://discord.gg/flutter
- **Stack Overflow:** Tag questions with `flutter`, `dart`
- **GitHub Issues:** https://github.com/flutter/flutter/issues

---

**Testing Guide Version:** 1.0
**Compatible with:** SortBliss v1.0 (16,421 lines of code)
**Last Verified:** 2025-11-16

**Ready to test?** Start with the [Quick Start](#quick-start-5-minute-setup) and complete the [Feature Testing Scenarios](#feature-testing-scenarios). Good luck! 🎮
