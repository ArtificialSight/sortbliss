# Monetization Optimization Guide

**Objective:** Maximize revenue per user while maintaining excellent user experience and retention.

---

## Table of Contents

1. [Dynamic Pricing Strategy](#dynamic-pricing-strategy)
2. [Ad Frequency Optimization](#ad-frequency-optimization)
3. [Cross-Sell System](#cross-sell-system)
4. [A/B Testing Framework](#ab-testing-framework)
5. [Revenue Analytics](#revenue-analytics)
6. [Implementation Roadmap](#implementation-roadmap)

---

## Dynamic Pricing Strategy

### Price Elasticity Model

**Goal:** Find optimal price points that maximize revenue (price × conversion rate)

**Tiered Pricing:**
```
Coin Packs (Base Prices):
- Small (500 coins): $0.99
- Medium (1,200 coins): $1.99 (20% bonus)
- Large (3,000 coins): $4.99 (50% bonus)
- Mega (7,500 coins): $9.99 (100% bonus)

Remove Ads:
- One-time: $2.99

Premium Skins:
- Individual: $0.99-1.99
- Bundle (5 skins): $3.99
```

### Dynamic Pricing Implementation

**Price Testing Matrix:**
```dart
class DynamicPricingService {
  // A/B test groups
  static const Map<String, Map<String, double>> priceVariants = {
    'control': {
      'small_pack': 0.99,
      'medium_pack': 1.99,
      'large_pack': 4.99,
      'mega_pack': 9.99,
      'remove_ads': 2.99,
    },
    'variant_a': {  // 20% lower
      'small_pack': 0.79,
      'medium_pack': 1.59,
      'large_pack': 3.99,
      'mega_pack': 7.99,
      'remove_ads': 2.39,
    },
    'variant_b': {  // 20% higher
      'small_pack': 1.19,
      'medium_pack': 2.39,
      'large_pack': 5.99,
      'mega_pack': 11.99,
      'remove_ads': 3.59,
    },
  };

  // Assign user to pricing group (consistent per user)
  String getPricingGroup(String userId) {
    final hash = userId.hashCode;
    final groups = ['control', 'variant_a', 'variant_b'];
    return groups[hash.abs() % groups.length];
  }

  double getPrice(String userId, String productId) {
    final group = getPricingGroup(userId);
    return priceVariants[group]![productId]!;
  }
}
```

### Regional Pricing

**Purchasing Power Parity (PPP) Adjustment:**
```
Tier 1 (US, CA, UK, AU, DE, FR): 100% base price
Tier 2 (ES, IT, JP, KR): 80% base price
Tier 3 (MX, BR, RU, IN): 50% base price
Tier 4 (Other): 60% base price
```

**Implementation:**
```dart
double getRegionalPrice(String productId, String countryCode) {
  final basePrice = getPrice(userId, productId);
  final multiplier = _getRegionalMultiplier(countryCode);
  return basePrice * multiplier;
}

double _getRegionalMultiplier(String countryCode) {
  const tier1 = ['US', 'CA', 'GB', 'AU', 'DE', 'FR'];
  const tier2 = ['ES', 'IT', 'JP', 'KR'];
  const tier3 = ['MX', 'BR', 'RU', 'IN'];

  if (tier1.contains(countryCode)) return 1.0;
  if (tier2.contains(countryCode)) return 0.8;
  if (tier3.contains(countryCode)) return 0.5;
  return 0.6;
}
```

### Limited-Time Offers

**Flash Sales (3-6 hours):**
- 30-50% discount on coin packs
- Countdown timer creates urgency
- Trigger after level 10, 25, 50 completion
- Maximum 1 per week per user

**Starter Pack (First 24 hours):**
- 1,000 coins + Remove Ads: $1.99 (70% off)
- One-time offer, new users only
- Shown after tutorial completion

**Comeback Offer (Lapsed users):**
- 500 coins + Premium Skin: $0.99
- Shown to users returning after 7+ days inactive
- Maximum 3 per year

**Implementation:**
```dart
class SpecialOfferService {
  SpecialOffer? getCurrentOffer(String userId) {
    // Check eligibility for each offer type
    if (_isEligibleForStarterPack(userId)) {
      return StarterPackOffer(
        price: 1.99,
        coins: 1000,
        includesAdRemoval: true,
        expiresAt: _installDate.add(Duration(hours: 24)),
      );
    }

    if (_isEligibleForFlashSale(userId)) {
      return FlashSaleOffer(
        productId: 'large_pack',
        discountPercent: 40,
        expiresAt: DateTime.now().add(Duration(hours: 3)),
      );
    }

    if (_isEligibleForComebackOffer(userId)) {
      return ComebackOffer(
        price: 0.99,
        coins: 500,
        skinId: 'premium_ocean',
        expiresAt: DateTime.now().add(Duration(hours: 48)),
      );
    }

    return null;
  }
}
```

---

## Ad Frequency Optimization

### Ad Placement Strategy

**Rewarded Ads (High Value):**
- After failed level (offer 100 coins to retry)
- Daily rewards (double reward for ad watch)
- Unlock next level early (save 5 stars)
- Hint system (get sorting hint)

**Interstitial Ads (Medium Value):**
- Between levels (every 3rd level)
- After 5+ minute session
- When exiting to main menu
- Maximum 1 per 3 minutes

**Banner Ads (Low Value):**
- Main menu only
- Removed during gameplay
- Removed for premium users

### Frequency Capping Model

**Prevent Ad Fatigue:**
```dart
class AdFrequencyOptimizer {
  static const int maxInterstitialsPerHour = 4;
  static const int maxInterstitialsPerDay = 20;
  static const int minSecondsBetweenAds = 180; // 3 minutes

  Future<bool> canShowInterstitial() async {
    final lastShown = await _getLastInterstitialTime();
    if (lastShown != null) {
      final secondsSince = DateTime.now().difference(lastShown).inSeconds;
      if (secondsSince < minSecondsBetweenAds) {
        return false;
      }
    }

    final hourCount = await _getInterstitialsInLastHour();
    if (hourCount >= maxInterstitialsPerHour) {
      return false;
    }

    final dayCount = await _getInterstitialsInLastDay();
    if (dayCount >= maxInterstitialsPerDay) {
      return false;
    }

    return true;
  }

  // Adaptive frequency based on engagement
  int getOptimalAdInterval(double sessionDuration) {
    if (sessionDuration < 5) return 5; // Every 5 levels (short sessions)
    if (sessionDuration < 15) return 3; // Every 3 levels (medium)
    return 2; // Every 2 levels (long engaged sessions)
  }
}
```

### ARPDAU Optimization

**Target Metrics:**
- Rewarded ad watch rate: 35-45%
- Interstitial view rate: 60-70%
- eCPM target: $5-10 (rewarded), $2-4 (interstitial)
- Target ARPDAU: $0.15-0.25

**Revenue Mix:**
```
Target Split (Free Users):
- Rewarded ads: 60% of ad revenue
- Interstitial ads: 35% of ad revenue
- Banner ads: 5% of ad revenue

Target Split (Overall Revenue):
- IAP: 70%
- Ads: 30%
```

### Progressive Ad Frequency

**Engagement-Based Scaling:**
```dart
double getAdMultiplier(int daysActive) {
  if (daysActive < 3) return 0.5;   // 50% fewer ads (onboarding)
  if (daysActive < 7) return 0.75;  // 25% fewer ads (early retention)
  if (daysActive < 30) return 1.0;  // Normal frequency
  return 1.25;                       // 25% more ads (power users)
}
```

---

## Cross-Sell System

### Product Recommendation Engine

**Context-Based Offers:**

1. **Coin Scarcity → Coin Pack**
   ```
   Trigger: Coins < 100
   Offer: Small coin pack ($0.99)
   Message: "Running low on coins! Get 500 for $0.99"
   ```

2. **Ad Frustration → Remove Ads**
   ```
   Trigger: 3+ interstitial ads watched in session
   Offer: Remove ads ($2.99)
   Message: "Tired of ads? Remove them forever for $2.99"
   ```

3. **Progression Block → Unlock Pack**
   ```
   Trigger: Stuck on level for 5+ attempts
   Offer: Medium coin pack + hint ($1.99)
   Message: "Need help? Get coins + hints to beat this level"
   ```

4. **Customization Interest → Skin Bundle**
   ```
   Trigger: Viewed skins 3+ times
   Offer: Premium skin bundle ($3.99)
   Message: "Love customization? Get 5 premium skins for $3.99"
   ```

### Bundle Strategy

**Value Bundles:**
```
Starter Bundle ($1.99):
- 1,000 coins
- Remove ads
- 1 premium skin
- 70% savings vs individual

Premium Bundle ($9.99):
- 10,000 coins
- Remove ads
- All skins unlocked
- Exclusive particle effects
- 80% savings vs individual
```

### Upsell Flow

**Post-Purchase Upsell:**
```dart
void showUpsellOffer(String purchasedProduct) {
  if (purchasedProduct == 'small_pack') {
    // Offer medium pack at 20% discount
    showOffer(
      'Loving SortBliss? Get 1,200 coins for just $1.59 (20% off)',
      'medium_pack_upsell',
      discountedPrice: 1.59,
    );
  } else if (purchasedProduct == 'medium_pack') {
    // Offer remove ads
    showOffer(
      'Complete your experience! Remove ads for $2.99',
      'remove_ads_upsell',
    );
  }
}
```

---

## A/B Testing Framework

### Price Testing

**Test Setup:**
```dart
class PriceTest {
  final String testId;
  final Map<String, double> controlPrices;
  final Map<String, double> variantPrices;
  final DateTime startDate;
  final DateTime endDate;
  final double trafficAllocation; // 0.0-1.0

  // Assign users to test groups
  String getTestGroup(String userId) {
    final hash = '$testId:$userId'.hashCode;
    final random = (hash.abs() % 100) / 100.0;

    if (random < trafficAllocation) {
      return (hash.abs() % 2 == 0) ? 'control' : 'variant';
    }
    return 'excluded';
  }
}
```

### Key Metrics to Track

**Per Test Group:**
```
Conversion Metrics:
- View rate (% saw offer)
- Click rate (% clicked CTA)
- Purchase rate (% completed purchase)
- Revenue per user
- Revenue per purchaser

Retention Impact:
- D1, D7, D30 retention
- Session duration
- Levels completed

Long-term Value:
- LTV (30/60/90 day)
- Repeat purchase rate
- Time to second purchase
```

### Statistical Significance

**Minimum Requirements:**
- 1,000+ users per variant
- 7+ days test duration
- 95% confidence level (p < 0.05)
- 10%+ lift to be meaningful

**Sample Size Calculator:**
```dart
int calculateRequiredSampleSize({
  required double baselineConversion,
  required double minimumDetectableEffect,
  required double confidenceLevel,
  required double statisticalPower,
}) {
  // Simplified formula
  final z_alpha = 1.96; // 95% confidence
  final z_beta = 0.84;  // 80% power

  final p1 = baselineConversion;
  final p2 = baselineConversion * (1 + minimumDetectableEffect);

  final pooled = (p1 + p2) / 2;
  final n = pow((z_alpha + z_beta), 2) * pooled * (1 - pooled) /
      pow((p2 - p1), 2);

  return n.ceil();
}
```

---

## Revenue Analytics

### Dashboard Metrics

**Daily Monitoring:**
```
Revenue Metrics:
- Total revenue (IAP + Ads)
- ARPU (Average Revenue Per User)
- ARPDAU (Average Revenue Per Daily Active User)
- Conversion rate (% making purchase)
- eCPM (Effective Cost Per Mille for ads)

User Segmentation:
- Whales (top 1%): > $100 spent
- Dolphins (top 10%): $10-100 spent
- Minnows (paying users): $0.01-10 spent
- Free users: $0 spent

Product Performance:
- Revenue by SKU
- Conversion rate by product
- Refund rate by product
```

### Cohort Analysis

**Track LTV by Install Cohort:**
```
Cohort: Jan 2024
- D1 LTV: $0.05
- D7 LTV: $0.15
- D30 LTV: $0.50
- D90 LTV: $1.20

Payback Period: 45 days (LTV = CAC)
```

### Segmented Reporting

**Revenue by User Segment:**
```dart
class RevenueSegmentation {
  Map<String, double> getRevenueBySegment() {
    return {
      'whales_1%': totalRevenue * 0.40,      // 40% from top 1%
      'dolphins_9%': totalRevenue * 0.35,    // 35% from next 9%
      'minnows_15%': totalRevenue * 0.20,    // 20% from next 15%
      'free_75%': totalRevenue * 0.05,       // 5% from free users (ads)
    };
  }
}
```

---

## Implementation Roadmap

### Week 1: Foundation
- [ ] Implement DynamicPricingService
- [ ] Set up A/B testing framework
- [ ] Add revenue analytics tracking
- [ ] Test price variants (control vs 2 variants)

### Week 2: Ad Optimization
- [ ] Implement AdFrequencyOptimizer
- [ ] Add frequency capping logic
- [ ] Test adaptive ad intervals
- [ ] Monitor ARPDAU impact

### Week 3: Cross-Sell
- [ ] Build recommendation engine
- [ ] Create bundle offers
- [ ] Implement upsell flows
- [ ] Test contextual offers

### Week 4: Regional Pricing
- [ ] Implement PPP adjustments
- [ ] A/B test regional price points
- [ ] Monitor conversion by region
- [ ] Optimize for local markets

### Ongoing: Optimization
- [ ] Weekly A/B test reviews
- [ ] Monthly pricing adjustments
- [ ] Quarterly bundle refreshes
- [ ] Continuous analytics monitoring

---

## Best Practices

### Do's ✅
- Test price changes with A/B tests (never change globally without data)
- Cap ad frequency to prevent user frustration
- Offer value bundles (10x coins for 5x price)
- Use limited-time offers sparingly (maintains urgency)
- Track refund rates (high refunds = pricing issue)
- Segment users by spending behavior
- Optimize for LTV, not just initial conversion

### Don'ts ❌
- Don't show ads during core gameplay
- Don't exceed 4 interstitials per hour
- Don't price discriminate without testing
- Don't ignore regional purchasing power
- Don't spam upsells (1 per session max)
- Don't sacrifice retention for short-term revenue
- Don't test multiple variables simultaneously

---

## Success Metrics

**Target KPIs (Month 3):**
- Conversion rate: 2-3% (paying users)
- ARPU: $0.50-0.80
- ARPDAU: $0.15-0.25
- Ad revenue per user: $0.10-0.15/day
- IAP revenue per payer: $5-10
- LTV/CAC ratio: 3:1 minimum
- Refund rate: <2%

**Whale Targeting:**
- Top 1% LTV: $100+
- Top 10% LTV: $10+
- Revenue concentration: 60-70% from top 10%

---

## Revenue Projections

**Conservative Estimates (10K DAU):**
```
Daily Revenue:
- IAP (2.5% conversion × $5 ARPPU): $1,250
- Ads (ARPDAU $0.15): $1,500
- Total: $2,750/day

Monthly Revenue: $82,500
Annual Revenue: $990,000

At 10x revenue multiple:
Valuation Impact: ~$10M
```

**Optimized Scenarios (with dynamic pricing + cross-sell):**
```
Conversion rate increase: 2.5% → 3.5% (+40%)
ARPPU increase: $5 → $7 (+40%)
ARPDAU increase: $0.15 → $0.22 (+47%)

New Monthly Revenue: $140,000 (+70%)
New Annual Revenue: $1.68M

Additional Valuation: +$6.8M
```

---

## Resources

- [F2P Monetization Best Practices](https://www.deconstructoroffun.com/)
- [Mobile Game Pricing Strategies](https://www.pocketgamer.biz/monetization)
- [A/B Testing Calculator](https://www.optimizely.com/sample-size-calculator/)
- [Regional Pricing Data](https://steamdb.info/sales/)
- [ARPDAU Benchmarks](https://www.gamesight.io/benchmarks)

---

**Estimated Impact:** +$100K-150K valuation from optimized monetization (20-30% revenue increase)
