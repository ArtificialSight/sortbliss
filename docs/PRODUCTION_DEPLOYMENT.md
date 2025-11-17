# SortBliss Production Deployment Guide

**Version**: 1.0
**Last Updated**: 2025-11-17
**Estimated Timeline**: 2-3 weeks to production
**Target Valuation**: $2.5M+ with live validation

---

## 🎯 Overview

This guide provides step-by-step instructions for deploying SortBliss to production, enabling immediate revenue validation and accelerating acquisition timeline.

**Business Impact**: Reduces time-to-acquisition by 4-6 weeks by enabling immediate soft launch.

---

## 📋 Pre-Deployment Checklist

### Phase 1: Backend Infrastructure (Week 1)

- [ ] **Supabase Project Setup**
  - Create project at https://supabase.com
  - Configure authentication (email/password + OAuth)
  - Set up PostgreSQL database schema
  - Enable Row Level Security (RLS)
  - Cost: $25/month (Pro plan)

- [ ] **Database Schema** (`/docs/database_schema.sql`)
  ```sql
  -- Users table
  CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    device_id TEXT
  );

  -- Cloud saves table
  CREATE TABLE cloud_saves (
    user_id UUID REFERENCES users(id),
    current_level INTEGER NOT NULL,
    levels_completed INTEGER NOT NULL,
    coins_earned INTEGER NOT NULL,
    level_progress FLOAT NOT NULL,
    unlocked_achievements JSONB,
    last_modified TIMESTAMP DEFAULT NOW(),
    version INTEGER NOT NULL,
    PRIMARY KEY (user_id)
  );

  -- Leaderboards table
  CREATE TABLE leaderboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    player_name TEXT NOT NULL,
    score INTEGER NOT NULL,
    level INTEGER NOT NULL,
    stars INTEGER NOT NULL,
    submitted_at TIMESTAMP DEFAULT NOW(),
    leaderboard_type TEXT NOT NULL -- 'allTime', 'weekly', 'daily'
  );

  CREATE INDEX idx_leaderboards_type_score ON leaderboards(leaderboard_type, score DESC);
  ```

- [ ] **Firebase Setup** (Push Notifications + Analytics)
  - Create Firebase project
  - Add Android app (com.sortbliss.app)
  - Add iOS app (com.sortbliss.app)
  - Download google-services.json (Android)
  - Download GoogleService-Info.plist (iOS)
  - Enable Cloud Messaging
  - Enable Analytics
  - Cost: Free (Spark plan), $25/month (Blaze if scaling)

- [ ] **Google AdMob Setup**
  - Create AdMob account
  - Create app in AdMob console
  - Generate ad unit IDs for:
    - Interstitial ads
    - Rewarded video ads
  - Replace test ad unit IDs in `ad_manager.dart`
  - Expected revenue: $0.50/user from ads

- [ ] **In-App Purchase Setup**
  - Google Play Console: Create products
    - sortbliss_remove_ads ($2.99)
    - sortbliss_coin_pack_small ($0.99)
    - sortbliss_coin_pack_large ($2.99)
    - sortbliss_coin_pack_epic ($6.99)
    - sortbliss_sort_pass_premium ($4.99/month)
  - Apple App Store Connect: Create products
  - Test purchases in sandbox environment
  - Expected revenue: $0.42/user from IAP

---

### Phase 2: App Store Configuration (Week 1-2)

#### Google Play Store

- [ ] **Developer Account**
  - Create Google Play Developer account ($25 one-time fee)
  - Complete identity verification
  - Set up merchant account for paid apps

- [ ] **App Listing**
  - App name: "SortBliss - Sorting Puzzle Game"
  - Short description: "The ultimate sorting puzzle game! Drag items into categories, earn rewards, and compete globally."
  - Full description: See `/docs/app_store_description.md`
  - Screenshots: 1080x1920 (phone), 1920x1080 (tablet) - 8 required
  - Feature graphic: 1024x500
  - App icon: 512x512
  - Category: Puzzle
  - Content rating: Everyone
  - Privacy policy URL: https://sortbliss.com/privacy

- [ ] **Release Configuration**
  - Create internal testing track (for beta)
  - Add 50-100 testers
  - Upload signed AAB (App Bundle)
  - Enable staged rollout (10% → 50% → 100%)

#### Apple App Store

- [ ] **Developer Account**
  - Enroll in Apple Developer Program ($99/year)
  - Complete identity verification

- [ ] **App Store Connect**
  - Create new app
  - Bundle ID: com.sortbliss.app
  - Primary language: English
  - Screenshots: 6.5" display (iPhone 14 Pro Max) - 6-10 required
  - App preview videos: Optional but recommended
  - App icon: 1024x1024
  - Category: Games > Puzzle
  - Age rating: 4+
  - Privacy policy URL: https://sortbliss.com/privacy

- [ ] **TestFlight Beta**
  - Upload build to TestFlight
  - Add 50-100 external testers
  - Collect feedback for 1 week before public launch

---

### Phase 3: Code Updates (Week 2)

- [ ] **Environment Configuration** (`/lib/config/environment.dart`)
  ```dart
  class Environment {
    static const bool isProduction = true; // Change to true for production
    static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
    static const String supabaseAnonKey = 'YOUR_ANON_KEY';
    static const String firebaseMessagingSenderId = 'YOUR_SENDER_ID';
  }
  ```

- [ ] **Ad Unit IDs** (`/lib/core/monetization/ad_manager.dart`)
  - Replace test IDs with production ad unit IDs
  - Android interstitial: ca-app-pub-XXXXX/YYYYYY
  - Android rewarded: ca-app-pub-XXXXX/ZZZZZZ
  - iOS interstitial: ca-app-pub-XXXXX/AAAAAA
  - iOS rewarded: ca-app-pub-XXXXX/BBBBBB

- [ ] **API Endpoints** (Update all services)
  - CloudSaveService: POST/GET https://api.sortbliss.com/cloud-save
  - LeaderboardService: POST/GET https://api.sortbliss.com/leaderboard
  - AnalyticsLogger: POST https://api.sortbliss.com/analytics

- [ ] **Build Configuration**
  - Increment version number (pubspec.yaml)
  - Version: 1.0.0+1
  - Update build.gradle (Android)
  - Update Info.plist (iOS)
  - Enable ProGuard/R8 for release builds
  - Enable code obfuscation

---

### Phase 4: Testing & QA (Week 2)

- [ ] **Automated Tests**
  ```bash
  flutter test
  flutter test --coverage
  ```
  - Target: 80%+ code coverage
  - Run all unit tests
  - Run integration tests
  - Verify all critical paths

- [ ] **Manual Testing Checklist**
  - [ ] Onboarding flow completes successfully
  - [ ] Level 1-10 playable without crashes
  - [ ] Interstitial ads show every 3 levels
  - [ ] Rewarded ads work for hints
  - [ ] IAP purchases complete successfully
  - [ ] Daily rewards claim works
  - [ ] Push notifications deliver
  - [ ] Leaderboards update correctly
  - [ ] Cloud save syncs across devices
  - [ ] Achievement unlocks work
  - [ ] Power-ups activate correctly
  - [ ] A/B test assignments persist

- [ ] **Performance Testing**
  - Frame rate: 55+ fps sustained
  - Memory usage: <120 MB average
  - App size: <50 MB download
  - Cold start time: <2 seconds
  - API latency: <500ms average

- [ ] **Device Testing**
  - Test on 5+ Android devices (various manufacturers)
  - Test on 3+ iOS devices (various screen sizes)
  - Test on tablets
  - Test on different OS versions

---

### Phase 5: Soft Launch (Week 3)

- [ ] **Target Markets** (Start small, scale up)
  - Primary: US, Canada, UK
  - Secondary: Australia, New Zealand
  - Language: English only (MVP)

- [ ] **User Acquisition**
  - Budget: $500-1000 for initial testing
  - Platforms: Facebook Ads, Google App Campaigns
  - Target: 500-1000 installs in week 1
  - CPI target: $0.50-1.00
  - Target demographics:
    - Age: 18-45
    - Interests: Puzzle games, casual games, brain training

- [ ] **Metrics Collection** (First 7 Days)
  - D1 Retention: Target 60%
  - D7 Retention: Target 55%
  - Blended ARPU: Target $1.15
  - Viral Coefficient: Target 0.35
  - IAP Conversion: Target 4.5%
  - Subscription Conversion: Target 12%
  - Ad Completion Rate: Target 78%
  - Crash Rate: Target <0.1%

- [ ] **A/B Tests to Launch**
  1. Ad Frequency (every 2/3/4 levels)
  2. Hint Pricing (50/75/100 coins)
  3. Trial Length (7/14 days)
  - Run for minimum 1000 users per variant
  - Statistical significance: 95% confidence

---

### Phase 6: Monitoring & Optimization (Ongoing)

- [ ] **Analytics Dashboards**
  - Firebase Analytics: User engagement, retention
  - AdMob: Ad performance, eCPM
  - App Store Analytics: Downloads, conversion rate
  - Custom dashboard: Investor KPI dashboard in-app

- [ ] **Error Monitoring**
  - Firebase Crashlytics: Crash reports
  - Target: <0.1% crash rate
  - Set up alerts for crash spikes

- [ ] **Performance Monitoring**
  - Use PerformanceMonitorService
  - Track frame rate, memory, API latency
  - Set up alerts for degradation

- [ ] **User Feedback**
  - Monitor app store reviews
  - Set up in-app feedback mechanism
  - Respond to critical issues within 24h

---

## 💰 Expected Financial Outcomes

### Week 1-2 (Soft Launch Validation)
- **Users**: 500-1000
- **Revenue**: $500-1150 (validation of ARPU)
- **Key Metrics**: D1 60%, D7 55%, ARPU $1.15
- **Valuation Impact**: Proves metrics claims → $2.5M supportable

### Week 3-4 (Scaling)
- **Users**: 5000-10000
- **Revenue**: $5000-11500
- **Key Metrics**: A/B test winners implemented, viral coefficient proven
- **Valuation Impact**: Optimization proven → $2.75M supportable

### Month 2+ (Full Launch)
- **Users**: 50000+ (organic + paid)
- **Revenue**: $50000+/month
- **Key Metrics**: All KPIs stable, growth proven
- **Valuation Impact**: Sustainable business → $3.0M+ supportable

---

## 🚨 Critical Success Factors

1. **Backend Reliability**
   - Supabase uptime: 99.9%+ required
   - Cloud save must not lose data
   - API response times <500ms

2. **Monetization Integration**
   - IAP must process correctly
   - Ads must not disrupt experience
   - Subscription billing must work flawlessly

3. **User Experience**
   - Onboarding completion: 85%+
   - Tutorial skip rate: <15%
   - First level completion: 90%+

4. **Technical Stability**
   - Crash rate: <0.1%
   - ANR rate: <0.5%
   - No critical bugs in first week

---

## 📞 Support & Escalation

### Internal Team
- **Product Lead**: [Name]
- **Lead Developer**: [Name]
- **DevOps Engineer**: [Name]

### External Resources
- Supabase Support: support@supabase.io
- Firebase Support: Console → Help
- AdMob Support: admob.google.com/support

### Escalation Path
1. Developer investigates (<2h)
2. If not resolved, escalate to team lead
3. If critical (crashes >1%), hotfix within 24h
4. Post-mortem analysis within 48h

---

## 🎯 Success Criteria for Acquisition

After 2-3 weeks of production:
- ✅ 55%+ D7 retention validated
- ✅ $1.15+ ARPU validated
- ✅ 0.35+ viral coefficient validated
- ✅ <0.1% crash rate proven
- ✅ A/B test infrastructure operational
- ✅ 5-10% continuous improvement demonstrated

**Result**: Application ready for premium acquisition conversations with validated metrics proving $2.5M+ valuation.

---

## 📚 Additional Resources

- [Database Schema](/docs/database_schema.sql)
- [API Documentation](/docs/API_SPEC.md)
- [App Store Assets](/docs/app_store_assets/)
- [Privacy Policy Template](/docs/privacy_policy.md)
- [Terms of Service Template](/docs/terms_of_service.md)

---

**Questions?** Contact: [Your Email] or see `/docs/FAQ.md`
