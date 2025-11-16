# SortBliss Debug Checklist
## Pre-Launch QA & Production Readiness Validation

**Last Updated:** 2025-11-16
**Purpose:** Comprehensive quality assurance before soft launch
**Target:** Zero critical bugs, minimal known issues

---

## How to Use This Checklist

### Priority Levels
- **🔴 P0 (Blocker):** Must fix before launch—app-breaking bugs
- **🟠 P1 (Critical):** Fix before launch—major functionality impaired
- **🟡 P2 (Important):** Fix during soft launch—UX issues, minor bugs
- **🟢 P3 (Nice-to-have):** Backlog—polish, optimizations

### Testing Environments
- **Local Dev:** Your development machine (emulators/simulators)
- **TestFlight/Internal Testing:** Beta testers (small group)
- **Soft Launch:** 1-2 countries, limited rollout
- **Production:** Full global release

### Status Tracking
- [ ] Not Started
- [⏳] In Progress
- [✅] Passed
- [❌] Failed (see Known Issues section)
- [⚠️] Partial Pass (acceptable with workarounds)

---

## Checklist Overview

| Category | Tests | P0 Count | Status |
|----------|-------|----------|--------|
| **1. Installation & First Launch** | 8 | 6 | [ ] |
| **2. Core Gameplay** | 12 | 8 | [ ] |
| **3. User Interface & UX** | 10 | 5 | [ ] |
| **4. Monetization (IAP)** | 9 | 7 | [ ] |
| **5. Advertising** | 8 | 5 | [ ] |
| **6. Analytics & Tracking** | 7 | 3 | [ ] |
| **7. Retention Features** | 8 | 4 | [ ] |
| **8. Settings & Preferences** | 6 | 2 | [ ] |
| **9. Performance & Stability** | 10 | 6 | [ ] |
| **10. Security & Privacy** | 7 | 5 | [ ] |
| **11. Platform-Specific (Android)** | 6 | 4 | [ ] |
| **12. Platform-Specific (iOS)** | 6 | 4 | [ ] |
| **13. Edge Cases & Error Handling** | 8 | 6 | [ ] |
| **14. Accessibility** | 5 | 0 | [ ] |
| **TOTAL** | **110** | **65** | **0%** |

---

## 1. Installation & First Launch

### Test Environment: Fresh device/emulator (no prior install)

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 1.1 | 🔴 P0 | Install app from store (TestFlight/Internal Testing) | App installs without errors, icon appears on home screen | [ ] | |
| 1.2 | 🔴 P0 | Launch app for the first time (cold start) | Splash screen appears within 2 seconds, no crash | [ ] | |
| 1.3 | 🔴 P0 | Splash screen transitions to Main Menu | Main Menu loads within 3 seconds total from launch | [ ] | |
| 1.4 | 🟠 P1 | App requests necessary permissions (camera, microphone) | Permission dialogs appear with clear explanations, can deny without crash | [ ] | Currently optional |
| 1.5 | 🔴 P0 | Default player profile created | Main Menu shows: 47 levels, 12 streak, 2,850 coins, 2 achievements | [ ] | |
| 1.6 | 🔴 P0 | Default settings applied | Sound ON, Music ON, Haptics ON, Notifications ON | [ ] | |
| 1.7 | 🟡 P2 | Adaptive tutorial triggers on first gameplay | Tutorial overlay appears with gesture guidance | [ ] | |
| 1.8 | 🔴 P0 | App survives device orientation changes | Portrait mode enforced, no crash on device rotation | [ ] | |

**Pass Criteria:** 6/6 P0 tests passed, 1/1 P1 tests passed

---

## 2. Core Gameplay

### Test Environment: Fresh level start from Main Menu

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 2.1 | 🔴 P0 | Tap "Play" button from Main Menu | Gameplay screen loads within 2 seconds, no crash | [ ] | |
| 2.2 | 🔴 P0 | Gameplay screen displays all UI elements | 8 emoji items visible, 4 containers visible, HUD shows score/time/moves | [ ] | |
| 2.3 | 🔴 P0 | Drag an item from center pile | Item follows finger/cursor, visual feedback (shadow, scale), no lag | [ ] | |
| 2.4 | 🔴 P0 | Drop item into correct container | Item snaps to container, score increases, particle effects, sound effect | [ ] | |
| 2.5 | 🔴 P0 | Drop item into incorrect container | Item returns to pile OR error feedback, no score change, no crash | [ ] | Check implementation |
| 2.6 | 🟠 P1 | Build a 3x combo | Combo counter appears, score multiplied (100 → 300), visual celebration | [ ] | |
| 2.7 | 🔴 P0 | Complete a level (sort all items) | Level Complete screen appears with stars, score, coins earned | [ ] | |
| 2.8 | 🔴 P0 | Tap "Next Level" on Level Complete screen | Next level loads, level number increments | [ ] | |
| 2.9 | 🟠 P1 | Pause game (if pause button exists) | Gameplay pauses, pause menu appears, resume works | [ ] | Check implementation |
| 2.10 | 🟡 P2 | Tap "Replay" on Level Complete screen | Same level restarts from beginning, score resets | [ ] | |
| 2.11 | 🔴 P0 | Play 10 levels consecutively | No crashes, no memory leaks, consistent performance | [ ] | |
| 2.12 | 🔴 P0 | Return to Main Menu from gameplay | Navigation works, gameplay state saved/discarded appropriately | [ ] | |

**Pass Criteria:** 8/8 P0 tests passed, 2/2 P1 tests passed

---

## 3. User Interface & UX

### Test Environment: Navigate through all screens

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 3.1 | 🔴 P0 | All screens load without crashes | Splash, Main Menu, Gameplay, Level Complete, Settings, Achievements, Daily Challenge, Storefront | [ ] | |
| 3.2 | 🟠 P1 | All buttons respond to taps | Visual feedback (ripple, press state), action executes, no double-tap issues | [ ] | |
| 3.3 | 🟠 P1 | Text is readable on all screen sizes | No truncation, no overflow, proper scaling | [ ] | Test on small (iPhone SE) and large (iPad) devices |
| 3.4 | 🟡 P2 | Animations are smooth (60 FPS) | No stuttering on transitions, particle effects, confetti | [ ] | Use performance overlay |
| 3.5 | 🔴 P0 | No visual glitches or overlapping UI | Z-index correct, modals block background interactions | [ ] | |
| 3.6 | 🟠 P1 | Back button/gesture returns to previous screen | Android back button, iOS swipe-back (if enabled) | [ ] | |
| 3.7 | 🟡 P2 | Loading states shown for async operations | Spinner for daily challenge load, IAP load, ad load | [ ] | |
| 3.8 | 🔴 P0 | Error messages are user-friendly | No technical jargon, clear action items ("Try again", "Check internet") | [ ] | |
| 3.9 | 🟡 P2 | Confetti and particle effects render correctly | No clipping, proper layering, disposal after animation | [ ] | |
| 3.10 | 🟢 P3 | Dark mode support (if implemented) | Colors readable, assets optimized for dark backgrounds | [ ] | Not implemented yet |

**Pass Criteria:** 3/3 P0 tests passed, 3/3 P1 tests passed

---

## 4. Monetization (IAP)

### Test Environment: Sandbox/testing mode (Google Play/App Store)

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 4.1 | 🔴 P0 | IAP products load from store | 5 products appear: remove_ads, 3 coin packs, premium pass | [ ] | Requires store connection |
| 4.2 | 🔴 P0 | Product details display correctly | Title, description, localized price (e.g., "$2.99") | [ ] | |
| 4.3 | 🔴 P0 | Initiate purchase (consumable: 250 coins) | Native payment sheet appears, sandbox account charged | [ ] | Use test account |
| 4.4 | 🔴 P0 | Complete purchase successfully | Coins added to balance (2,850 → 3,100), confirmation message shown | [ ] | |
| 4.5 | 🔴 P0 | Purchase fails gracefully (cancel payment) | No coins added, user returned to store, no crash, clear error message | [ ] | |
| 4.6 | 🔴 P0 | Non-consumable purchase (remove ads) | Ads disabled after purchase, entitlement persisted | [ ] | |
| 4.7 | 🟠 P1 | Restore Purchases button works | Previous non-consumables restored, consumables not restored | [ ] | Uninstall/reinstall to test |
| 4.8 | 🔴 P0 | Duplicate non-consumable prevented | Can't buy "remove ads" twice, show "Already Purchased" message | [ ] | |
| 4.9 | 🟠 P1 | Analytics events logged for all IAP actions | `iap_purchase_initiated`, `iap_purchase_success`, `iap_purchase_failed`, `iap_restore` | [ ] | Check logs |

**Pass Criteria:** 7/7 P0 tests passed, 2/2 P1 tests passed

---

## 5. Advertising

### Test Environment: Test ad units (Google test IDs)

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 5.1 | 🔴 P0 | Rewarded ad loads on Level Complete screen | "Watch Ad for 2x Coins" button appears, tappable | [ ] | |
| 5.2 | 🔴 P0 | Tap rewarded ad button | Ad loads within 5 seconds, plays full video (30s) | [ ] | |
| 5.3 | 🔴 P0 | Complete rewarded ad | Coins doubled (e.g., 100 → 200), confirmation shown | [ ] | |
| 5.4 | 🟠 P1 | Close rewarded ad early (if skip button available) | No reward granted, return to Level Complete screen | [ ] | |
| 5.5 | 🔴 P0 | Interstitial ad shows after 3-5 levels | Ad appears between levels (not mid-gameplay), skippable after 5s | [ ] | |
| 5.6 | 🟠 P1 | Ad fails to load (airplane mode test) | Error message shown, fallback to "Skip Ad" or continue without ad | [ ] | |
| 5.7 | 🔴 P0 | Ads respect "Remove Ads" purchase | Interstitials disabled, rewarded ads still available (user opt-in) | [ ] | |
| 5.8 | 🟠 P1 | Analytics events logged for all ad actions | `ad_load_success`, `ad_show`, `ad_impression`, `ad_failed`, `ad_earned_reward` | [ ] | Check logs |

**Pass Criteria:** 5/5 P0 tests passed, 3/3 P1 tests passed

---

## 6. Analytics & Tracking

### Test Environment: All screens, monitor logs

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 6.1 | 🔴 P0 | `app_open` event logged on launch | Event appears in logs with timestamp | [ ] | |
| 6.2 | 🟠 P1 | `level_start` event logged on gameplay start | Event includes level number, difficulty | [ ] | |
| 6.3 | 🔴 P0 | `level_complete` event logged on level finish | Event includes stars, score, time, moves | [ ] | |
| 6.4 | 🔴 P0 | All IAP events logged | `iap_purchase_initiated`, `iap_purchase_success`, `iap_purchase_failed` | [ ] | |
| 6.5 | 🟠 P1 | All ad events logged | `ad_rewarded_show`, `ad_rewarded_earned_reward`, `ad_interstitial_show` | [ ] | |
| 6.6 | 🟡 P2 | User settings changes logged | `settings_changed` with parameter (audio: false, haptics: true, etc.) | [ ] | |
| 6.7 | 🟡 P2 | Social share events logged | `share_initiated`, `share_completed` with platform (WhatsApp, Twitter) | [ ] | |

**Pass Criteria:** 3/3 P0 tests passed, 2/2 P1 tests passed

---

## 7. Retention Features

### Test Environment: Daily Challenge, Achievements, Social

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 7.1 | 🔴 P0 | Daily Challenge widget visible on Main Menu | Shows title, countdown timer, "Play" button | [ ] | |
| 7.2 | 🟠 P1 | Tap Daily Challenge | Challenge screen loads with details (title, description, rewards) | [ ] | |
| 7.3 | 🟠 P1 | Complete Daily Challenge | "Claim Reward" button enabled, rewards added to account | [ ] | |
| 7.4 | 🔴 P0 | Daily Challenge resets after 24 hours | New challenge appears, countdown resets, previous challenge marked complete | [ ] | Manual time change test |
| 7.5 | 🟡 P2 | Achievement unlocks trigger notification | "Social Butterfly" unlocks after 3 shares, popup appears | [ ] | |
| 7.6 | 🔴 P0 | Achievements screen displays all unlocked achievements | Icons, titles, unlock dates visible | [ ] | |
| 7.7 | 🟠 P1 | Share button on Level Complete screen | Native share sheet opens, share text includes score + link | [ ] | |
| 7.8 | 🔴 P0 | Share count increments after sharing | Player profile share count: 0 → 1 → 2 → 3 (unlocks achievement) | [ ] | |

**Pass Criteria:** 4/4 P0 tests passed, 3/3 P1 tests passed

---

## 8. Settings & Preferences

### Test Environment: Settings screen, verify persistence

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 8.1 | 🔴 P0 | Toggle Sound Effects OFF | No sound effects in gameplay, setting persists after app restart | [ ] | |
| 8.2 | 🔴 P0 | Toggle Background Music OFF | Music stops immediately, setting persists | [ ] | |
| 8.3 | 🟠 P1 | Toggle Haptic Feedback OFF | No vibration on item placement, setting persists | [ ] | |
| 8.4 | 🟡 P2 | Adjust Difficulty slider | Gameplay difficulty changes (time limits, item count, etc.) | [ ] | Check implementation |
| 8.5 | 🟡 P2 | Toggle Notifications OFF | No push notifications sent (requires backend integration) | [ ] | Future feature |
| 8.6 | 🟠 P1 | Settings survive app reinstall (if cloud sync enabled) | Settings restored after uninstall/reinstall | [ ] | Requires cloud save |

**Pass Criteria:** 2/2 P0 tests passed, 2/2 P1 tests passed

---

## 9. Performance & Stability

### Test Environment: Profile mode, DevTools, physical devices

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 9.1 | 🔴 P0 | Cold start time (app closed → Main Menu) | <3 seconds on mid-tier device (Pixel 5, iPhone 12) | [ ] | |
| 9.2 | 🔴 P0 | Level load time (tap Play → gameplay ready) | <2 seconds | [ ] | |
| 9.3 | 🔴 P0 | Frame rate during gameplay | Consistent 60 FPS, no red bars in performance overlay | [ ] | |
| 9.4 | 🔴 P0 | Memory usage (idle) | <150MB RAM on Android, <200MB on iOS | [ ] | Use DevTools Memory profiler |
| 9.5 | 🔴 P0 | Memory usage (active gameplay, 20 levels) | No continuous growth, garbage collection occurs, <200MB peak | [ ] | |
| 9.6 | 🟠 P1 | Battery drain (30 min continuous play) | <15% battery consumption on full charge | [ ] | Physical device only |
| 9.7 | 🔴 P0 | No crashes during 60-minute play session | App remains stable, no ANR (Android) or watchdog (iOS) | [ ] | |
| 9.8 | 🟠 P1 | App survives background/foreground transitions | Tap home, open other apps, return—state preserved | [ ] | |
| 9.9 | 🟡 P2 | Low-end device performance (Android API 23) | Playable on Moto G4 or equivalent, 30-45 FPS acceptable | [ ] | |
| 9.10 | 🟡 P2 | Network interruption handling | Switch to airplane mode mid-game, no crash, offline features work | [ ] | |

**Pass Criteria:** 6/6 P0 tests passed, 2/2 P1 tests passed

---

## 10. Security & Privacy

### Test Environment: Code review, runtime checks

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 10.1 | 🔴 P0 | No hardcoded API keys or secrets in codebase | Search for "api_key", "secret", "token"—all use environment variables | [ ] | `grep -r "api_key" lib/` |
| 10.2 | 🔴 P0 | .env file not committed to version control | `.env` in `.gitignore`, only `.env.example` in repo | [ ] | `git ls-files | grep .env` |
| 10.3 | 🔴 P0 | HTTPS used for all network requests | No http:// URLs, only https:// (check Supabase, API calls) | [ ] | |
| 10.4 | 🟠 P1 | User data encrypted at rest (sensitive data) | flutter_secure_storage used for tokens, SharedPreferences for non-sensitive | [ ] | |
| 10.5 | 🔴 P0 | No PII logged to analytics | No usernames, emails, device IDs in analytics events | [ ] | Review AnalyticsService |
| 10.6 | 🔴 P0 | Privacy policy accessible in-app | Link in Settings screen to privacy policy URL | [ ] | Add before launch |
| 10.7 | 🟠 P1 | Terms of Service accessible in-app | Link in Settings screen to ToS URL | [ ] | Add before launch |

**Pass Criteria:** 5/5 P0 tests passed, 2/2 P1 tests passed

---

## 11. Platform-Specific (Android)

### Test Environment: Android emulator (API 23-33) + physical device

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 11.1 | 🔴 P0 | App installs on Android 6.0 (API 23) | No "Incompatible" error in Play Store | [ ] | Minimum SDK check |
| 11.2 | 🔴 P0 | App installs on Android 13 (API 33) | Installs and runs without issues | [ ] | Latest OS check |
| 11.3 | 🔴 P0 | Back button navigation works | Returns to previous screen, exits app from Main Menu (with confirmation) | [ ] | |
| 11.4 | 🟠 P1 | Permissions requested at runtime (not install-time) | Camera, microphone permissions only asked when feature used | [ ] | |
| 11.5 | 🔴 P0 | App survives Activity lifecycle (rotate, background, memory pressure) | No crash on orientation change, background/foreground | [ ] | |
| 11.6 | 🟡 P2 | APK size <50MB | `flutter build apk --analyze-size` shows <50MB download | [ ] | |

**Pass Criteria:** 4/4 P0 tests passed, 1/1 P1 tests passed

---

## 12. Platform-Specific (iOS)

### Test Environment: iOS simulator (iOS 12-17) + physical device

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 12.1 | 🔴 P0 | App installs on iOS 12.0 | No "Requires iOS 13+" error | [ ] | Minimum OS check |
| 12.2 | 🔴 P0 | App installs on iOS 17 | Installs and runs without issues | [ ] | Latest OS check |
| 12.3 | 🔴 P0 | Swipe-back gesture works (if enabled) | Swipe from left edge returns to previous screen | [ ] | |
| 12.4 | 🟠 P1 | Privacy permission dialogs show correct usage text | Camera: "for gesture detection", Microphone: "for voice commands" | [ ] | Check Info.plist |
| 12.5 | 🔴 P0 | App survives background/foreground (home button, app switcher) | State preserved, no crash | [ ] | |
| 12.6 | 🟡 P2 | IPA size <50MB | `flutter build ipa --analyze-size` shows <50MB download | [ ] | |

**Pass Criteria:** 4/4 P0 tests passed, 1/1 P1 tests passed

---

## 13. Edge Cases & Error Handling

### Test Environment: Simulate failure conditions

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 13.1 | 🔴 P0 | Launch app in airplane mode (no network) | App loads, offline features work, daily challenge shows fallback | [ ] | |
| 13.2 | 🔴 P0 | Network drops mid-gameplay | Gameplay continues, IAP/ads fail gracefully with error message | [ ] | |
| 13.3 | 🟠 P1 | IAP fails (insufficient funds, canceled payment) | Clear error message, no coins added, user returned to store | [ ] | |
| 13.4 | 🟠 P1 | Ad fails to load (no fill, network timeout) | Error message or "Skip Ad" option, gameplay continues | [ ] | |
| 13.5 | 🔴 P0 | Device storage full | App shows "Storage full" error, suggests clearing cache/data | [ ] | Simulate with low storage |
| 13.6 | 🔴 P0 | Device low memory (background apps consuming RAM) | App doesn't crash, may show performance degradation warning | [ ] | |
| 13.7 | 🔴 P0 | Clock changed manually (daily challenge exploit test) | Challenge reset logic validates server time or fails gracefully | [ ] | |
| 13.8 | 🔴 P0 | Rapid tapping/button mashing | No duplicate actions (double purchase, double level start), UI locks during async | [ ] | |

**Pass Criteria:** 6/6 P0 tests passed, 2/2 P1 tests passed

---

## 14. Accessibility

### Test Environment: Enable accessibility features (OS-level)

| ID | Priority | Test Case | Expected Result | Status | Notes |
|----|----------|-----------|-----------------|--------|-------|
| 14.1 | 🟡 P2 | Screen reader (TalkBack/VoiceOver) announces buttons | All interactive elements have labels, states announced | [ ] | |
| 14.2 | 🟡 P2 | Large text mode (OS accessibility setting) | Text scales appropriately, no overflow (TextScaler currently fixed at 1.0) | [ ] | May need refactor |
| 14.3 | 🟢 P3 | High contrast mode | UI remains readable with high contrast enabled | [ ] | |
| 14.4 | 🟢 P3 | Color blindness simulation | Game playable without relying solely on color (emoji shapes help) | [ ] | |
| 14.5 | 🟢 P3 | Voice commands work (if enabled) | "Next", "Undo", "Pause" recognized and executed | [ ] | Currently disabled |

**Pass Criteria:** 0/0 P0 tests (all accessibility is P2-P3), 2/2 P2 tests recommended

---

## Known Issues

**Document bugs found during QA here. Track with issue IDs.**

### Critical Issues (Block Launch)
| Issue ID | Description | Priority | Status | Assigned To | ETA |
|----------|-------------|----------|--------|-------------|-----|
| - | No critical issues yet | - | - | - | - |

### Important Issues (Fix During Soft Launch)
| Issue ID | Description | Priority | Status | Assigned To | ETA |
|----------|-------------|----------|--------|-------------|-----|
| - | Storefront UI is placeholder ("Coming soon") | 🟡 P2 | Open | - | Sprint 2 |
| - | Audio assets missing (graceful degradation active) | 🟡 P2 | Open | - | Sprint 2 |

### Nice-to-Have Issues (Backlog)
| Issue ID | Description | Priority | Status | Assigned To | ETA |
|----------|-------------|----------|--------|-------------|-----|
| - | TextScaler fixed at 1.0 (no dynamic text sizing) | 🟢 P3 | Open | - | Backlog |
| - | Dark mode not implemented | 🟢 P3 | Open | - | Backlog |

---

## Performance Optimization Opportunities

**Low-effort, high-impact improvements identified during testing:**

### UI/UX Polish
1. **Add skeleton loaders** for async operations (daily challenge load, IAP load)
   - **Effort:** 2 hours
   - **Impact:** Perceived performance boost, less jarring loading states

2. **Optimize particle effects** for low-end devices
   - **Effort:** 4 hours
   - **Impact:** Smooth gameplay on Android API 23-25 devices

3. **Preload next level assets** during Level Complete screen
   - **Effort:** 3 hours
   - **Impact:** Instant level start (<500ms instead of 1-2s)

### Performance Gains
4. **Implement image caching** for frequently used assets
   - **Effort:** 2 hours
   - **Impact:** Reduce memory churn, faster asset loads

5. **Lazy-load Achievements screen** (only fetch data when opened)
   - **Effort:** 1 hour
   - **Impact:** Faster app startup

6. **Reduce widget rebuilds** in gameplay HUD (use `const` widgets, `AnimatedBuilder`)
   - **Effort:** 4 hours
   - **Impact:** 5-10% FPS improvement

### Engagement Boosters
7. **Add "Rate Us" prompt** after 5 level completions
   - **Effort:** 2 hours
   - **Impact:** Boost App Store/Play Store ratings (critical for ASO)

8. **Implement reward streak UI** (3 days, 7 days, 30 days bonuses)
   - **Effort:** 6 hours
   - **Impact:** 10-15% increase in D7 retention

9. **Add "Invite Friends" button** with referral code generation
   - **Effort:** 8 hours (requires backend integration)
   - **Impact:** Organic user acquisition, reduced CAC

10. **Daily login rewards** (coins, exclusive items)
    - **Effort:** 6 hours
    - **Impact:** 20-30% increase in D1 retention

**Total Estimated Effort:** 38 hours (1 week sprint)
**Recommended Priority:** Items 1, 3, 7, 10 (14 hours total)

---

## Crash Prevention Verification

**Critical checks to prevent app-breaking bugs:**

### Code-Level Checks
- [ ] All `AnimationController`s have corresponding `dispose()` calls
- [ ] All `StreamController`s closed in `dispose()`
- [ ] All `ValueNotifier` / `ChangeNotifier` listeners removed in `dispose()`
- [ ] No synchronous file I/O on UI thread
- [ ] All `Future`s handled with `.then()` or `await` (no unhandled exceptions)
- [ ] All `async` functions have `try-catch` blocks
- [ ] All user input fields have validation
- [ ] All list accesses check bounds or use `.firstWhere(orElse: ...)`
- [ ] All null-safety operators (`!`, `as`) justified with comments

### Runtime Checks
- [ ] No uncaught exceptions in logs during 60-minute play session
- [ ] No memory leaks detected in DevTools Memory profiler
- [ ] No ANR (Application Not Responding) on Android
- [ ] No watchdog terminations on iOS
- [ ] No "rebuilding too many times" Flutter errors
- [ ] No "setState called after dispose" errors
- [ ] No "A RenderFlex overflowed" layout errors

### Platform-Specific Checks
**Android:**
- [ ] No `java.lang.OutOfMemoryError` in logcat
- [ ] No `android.os.NetworkOnMainThreadException`
- [ ] ProGuard/R8 rules configured (if release build minified)

**iOS:**
- [ ] No `EXC_BAD_ACCESS` crashes
- [ ] No auto-layout constraint warnings
- [ ] Bitcode disabled (Flutter apps don't use bitcode)

---

## Pre-Launch Deployment Checklist

**Final steps before submitting to App Store/Play Store:**

### Configuration
- [ ] Replace test ad unit IDs with production IDs (AdMob dashboard)
- [ ] Replace Supabase URLs with production URLs (if using staging)
- [ ] Set `flutter build --release` mode (remove `--debug` flags)
- [ ] Verify `.env` not included in release build (use `--dart-define` for production)
- [ ] Increment version number in `pubspec.yaml` (e.g., 1.0.0 → 1.0.1)
- [ ] Update build number for both platforms (`version: 1.0.1+2`)

### Android
- [ ] Generate signed APK/AAB with release keystore
- [ ] Verify `android/app/build.gradle` has correct `versionCode` and `versionName`
- [ ] Test signed APK on physical device (different from debug signature)
- [ ] Upload to Play Console Internal Testing track first
- [ ] Verify IAP products in Production status (not Draft)
- [ ] Add privacy policy URL in Play Console

### iOS
- [ ] Generate signed IPA with distribution certificate
- [ ] Verify `ios/Runner/Info.plist` has correct `CFBundleShortVersionString`
- [ ] Test IPA via TestFlight (external testing group)
- [ ] Verify IAP products in "Ready to Submit" status
- [ ] Add privacy policy URL in App Store Connect
- [ ] Submit for App Review with clear testing instructions

### Analytics
- [ ] Firebase Analytics configured (if using Firebase)
- [ ] Verify analytics events logging to production dashboard (not debug)
- [ ] Set up custom conversions (IAP purchases, ad impressions)
- [ ] Configure BigQuery export (optional, for advanced analysis)

### Monitoring
- [ ] Enable crashlytics (Firebase Crashlytics or Sentry)
- [ ] Set up performance monitoring (Firebase Performance)
- [ ] Configure alerting for critical issues (crash rate >1%, ANR rate >0.5%)

---

## QA Sign-Off

**Completed by:** [QA Tester Name]
**Date:** [Date]
**Build Version:** [e.g., 1.0.0+1]

### Summary
- **Total Tests:** 110
- **Passed:** [ ] / 110
- **Failed:** [ ] / 110
- **Skipped:** [ ] / 110
- **Pass Rate:** [ ]%

### P0 Blocker Status
- **Total P0 Tests:** 65
- **P0 Passed:** [ ] / 65
- **P0 Failed:** [ ] / 65
- **P0 Pass Rate:** [ ]%

### Recommendation
- [ ] **APPROVED FOR LAUNCH** - All P0 tests passed, <5% P1 failures
- [ ] **APPROVED WITH CONDITIONS** - P0 passed, P1 failures documented with workarounds
- [ ] **NOT APPROVED** - Critical P0 failures, launch blocked

### Comments
[Add any additional notes, concerns, or observations here]

---

## Regression Testing (Post-Update)

**After every code update, re-run:**

### Smoke Test (15 minutes)
- [ ] App launches without crash
- [ ] Play 1 level end-to-end
- [ ] Complete 1 IAP test purchase
- [ ] Watch 1 rewarded ad
- [ ] Navigate to all screens (no crashes)

### Full Regression (4 hours)
- [ ] Re-run all 65 P0 tests
- [ ] Re-run all 45 P1 tests
- [ ] Performance profiling (FPS, memory)
- [ ] Check for new crashes in crashlytics

**Trigger Regression After:**
- Any code merge to `main` branch
- Before every release candidate build
- After fixing critical bugs
- Before soft launch deployment

---

## Resources

### Testing Tools
- **Flutter DevTools:** `flutter pub global activate devtools` → `flutter pub global run devtools`
- **Android Studio Profiler:** Tools > Profiler
- **Xcode Instruments:** Product > Profile (⌘I)
- **Charles Proxy:** Network traffic inspection
- **Flipper:** Mobile debugging platform

### Useful Commands
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/services/daily_challenge_service_test.dart

# Run tests with coverage
flutter test --coverage

# Performance profiling
flutter run --profile

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ios --release
```

### Documentation
- **Flutter Testing Docs:** https://docs.flutter.dev/testing
- **Google Play Pre-Launch Report:** https://support.google.com/googleplay/android-developer/answer/7002270
- **TestFlight Beta Testing:** https://developer.apple.com/testflight/

---

**Debug Checklist Version:** 1.0
**Last Updated:** 2025-11-16
**Compatible with:** SortBliss v1.0.0

**Ready to test? Start with P0 blockers, then P1 critical issues. Track all failures in the Known Issues section. Good luck! 🐛**
