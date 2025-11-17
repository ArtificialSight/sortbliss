# UX Polish & Accessibility Guide

**Objective:** Elevate SortBliss to premium app standards through refined animations, tactile feedback, and comprehensive accessibility support.

---

## Table of Contents

1. [Animation Best Practices](#animation-best-practices)
2. [Haptic Feedback Strategy](#haptic-feedback-strategy)
3. [Accessibility Compliance](#accessibility-compliance)
4. [Visual Feedback Systems](#visual-feedback-systems)
5. [Sound Design Integration](#sound-design-integration)
6. [Implementation Checklist](#implementation-checklist)

---

## Animation Best Practices

### Core Principles

1. **Purposeful Motion** - Every animation should communicate something (state change, progress, success)
2. **Respect Reduce Motion** - Honor user accessibility preferences
3. **Performance First** - Keep animations at 60 FPS minimum
4. **Consistent Timing** - Use standardized easing curves and durations

### Animation Timing Standards

```dart
// Standard animation durations (based on Material Design)
static const Duration instant = Duration(milliseconds: 100);
static const Duration quick = Duration(milliseconds: 200);
static const Duration standard = Duration(milliseconds: 300);
static const Duration emphasized = Duration(milliseconds: 500);
static const Duration cinematic = Duration(milliseconds: 800);

// Easing curves
static const Curve easeOut = Curves.easeOut;          // For enter animations
static const Curve easeIn = Curves.easeIn;            // For exit animations
static const Curve easeInOut = Curves.easeInOutCubic; // For transitions
static const Curve bounce = Curves.elasticOut;        // For playful moments
```

### Page Transitions

**Implementation:**

```dart
// Custom page route for consistent transitions
class SlideUpPageRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Check reduce motion setting
            final reduceMotion = UserSettingsService.instance
                .settings.value.reduceMotion;

            if (reduceMotion) {
              // Instant fade for accessibility
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            }

            // Standard slide up animation
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

// Usage:
Navigator.of(context).push(
  SlideUpPageRoute(page: const LevelCompleteScreen()),
);
```

### Card Animations

**Stagger animations for card lists:**

```dart
class StaggeredCardList extends StatelessWidget {
  final List<Widget> cards;

  const StaggeredCardList({required this.cards});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return cards[index]
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 50 * index),
              duration: const Duration(milliseconds: 300),
            )
            .slideY(
              begin: 0.2,
              end: 0,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}
```

### Loading States

**Skeleton screens instead of spinners:**

```dart
class SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(1.h),
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          ).shimmer(
            duration: 1500.ms,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          SizedBox(height: 1.h),
          Container(
            width: 40.w,
            height: 1.5.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(0.75.h),
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          ).shimmer(
            duration: 1500.ms,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}
```

### Micro-interactions

**Button press feedback:**

```dart
class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const BounceButton({required this.child, required this.onPressed});

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
```

---

## Haptic Feedback Strategy

### Feedback Levels

```dart
enum HapticIntensity {
  light,    // Subtle interactions (toggle switches)
  medium,   // Standard interactions (button presses)
  heavy,    // Important actions (level complete)
  success,  // Positive outcomes (achievement unlocked)
  warning,  // Attention needed (low coins)
  error,    // Failed actions (invalid move)
}

class HapticService {
  static Future<void> trigger(HapticIntensity intensity) async {
    final enabled = UserSettingsService.instance.settings.value.hapticsEnabled;
    if (!enabled) return;

    switch (intensity) {
      case HapticIntensity.light:
        await HapticFeedback.selectionClick();
        break;
      case HapticIntensity.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticIntensity.success:
        await _playSuccessPattern();
        break;
      case HapticIntensity.warning:
        await HapticFeedback.vibrate();
        break;
      case HapticIntensity.error:
        await _playErrorPattern();
        break;
    }

    AnalyticsLogger.logEvent('haptic_feedback', parameters: {
      'intensity': intensity.name,
    });
  }

  static Future<void> _playSuccessPattern() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  static Future<void> _playErrorPattern() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }
}
```

### Usage Guidelines

**DO:**
- ✅ Trigger haptics for successful sort completion
- ✅ Use light haptics for drag start/end
- ✅ Heavy haptics for level completion
- ✅ Success pattern for perfect completion (3 stars)

**DON'T:**
- ❌ Haptics on every frame during drag (too much)
- ❌ Haptics during continuous scrolling
- ❌ Multiple haptics within 100ms (overlapping)

---

## Accessibility Compliance

### WCAG 2.1 Level AA Requirements

#### 1. Color Contrast

**Minimum contrast ratios:**
- Normal text: 4.5:1
- Large text (18pt+): 3:1
- UI components: 3:1

**Implementation:**

```dart
// High contrast mode support
Color getContrastColor(Color background) {
  final highContrast = UserSettingsService.instance
      .settings.value.highContrastMode;

  if (!highContrast) {
    return Theme.of(context).colorScheme.onSurface;
  }

  // Calculate luminance
  final luminance = background.computeLuminance();

  // Return maximum contrast color
  return luminance > 0.5 ? Colors.black : Colors.white;
}
```

#### 2. Text Sizing

**Support user text scale preferences:**

```dart
// Respect user text scale setting
Text buildScalableText(String text, TextStyle? baseStyle) {
  final userScale = UserSettingsService.instance.settings.value.textScale;

  return Text(
    text,
    style: baseStyle?.copyWith(
      fontSize: (baseStyle.fontSize ?? 14.0) * userScale,
    ),
  );
}
```

#### 3. Screen Reader Support

**Semantic labels for all interactive elements:**

```dart
// Good - Semantic labels
Semantics(
  label: 'Daily reward available. Tap to claim 100 coins.',
  button: true,
  enabled: true,
  child: GestureDetector(
    onTap: _claimReward,
    child: const Icon(Icons.card_giftcard),
  ),
);

// Better - Include context
Semantics(
  label: 'Level 5. Locked. Earn 10 more stars to unlock.',
  button: false,
  child: LevelCardWidget(...),
);
```

#### 4. Keyboard Navigation (Desktop/Web)

```dart
// Focus management for keyboard users
class KeyboardNavigableCard extends StatelessWidget {
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          onActivate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            decoration: BoxDecoration(
              border: hasFocus
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: InkWell(
              onTap: onActivate,
              child: Card(...),
            ),
          );
        },
      ),
    );
  }
}
```

#### 5. Motion Sensitivity

**Respect reduce motion preference:**

```dart
// Check before playing animations
bool shouldAnimate() {
  return !UserSettingsService.instance.settings.value.reduceMotion;
}

// Conditional animation
Widget buildAnimatedWidget() {
  return Container(...)
      .animate(
        onPlay: shouldAnimate()
            ? (controller) => controller.forward()
            : null,
      )
      .fadeIn(duration: shouldAnimate() ? 300.ms : 0.ms);
}
```

---

## Visual Feedback Systems

### Success States

```dart
class SuccessFeedbackOverlay extends StatelessWidget {
  final String message;
  final IconData icon;

  const SuccessFeedbackOverlay({
    required this.message,
    this.icon = Icons.check_circle,
  });

  static void show(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => SuccessFeedbackOverlay(message: message),
    );

    // Auto-dismiss after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (context.mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4.w),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48.sp,
              color: Theme.of(context).colorScheme.primary,
            ).animate().scale(
                  duration: 300.ms,
                  curve: Curves.elasticOut,
                ),
            SizedBox(height: 2.h),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms)
          .scale(begin: const Offset(0.8, 0.8)),
    );
  }
}

// Usage:
void onLevelComplete() {
  SuccessFeedbackOverlay.show(context, 'Level Complete!');
  HapticService.trigger(HapticIntensity.success);
}
```

### Error States

```dart
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  static void show(BuildContext context, String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 2.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// Usage:
void onPurchaseFailed() {
  ErrorBanner.show(
    context,
    'Purchase failed. Please try again.',
    onRetry: _retryPurchase,
  );
  HapticService.trigger(HapticIntensity.error);
}
```

---

## Sound Design Integration

### Sound Categories

```dart
enum SoundEffect {
  // UI Interactions
  buttonTap,
  toggleOn,
  toggleOff,
  pageTransition,

  // Gameplay
  itemPlaced,
  sortCorrect,
  sortIncorrect,
  levelComplete,

  // Achievements
  achievementUnlocked,
  milestoneReached,
  rewardClaimed,

  // Errors
  errorSound,
  warningSound,
}

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(SoundEffect effect) async {
    final enabled = UserSettingsService.instance
        .settings.value.soundEffectsEnabled;

    if (!enabled) return;

    final filePath = _getSoundPath(effect);
    await _player.play(AssetSource(filePath));

    AnalyticsLogger.logEvent('sound_effect_played', parameters: {
      'effect': effect.name,
    });
  }

  static String _getSoundPath(SoundEffect effect) {
    return 'sounds/${effect.name}.mp3';
  }
}

// Usage with haptic coordination:
void onSortCorrect() {
  SoundService.play(SoundEffect.sortCorrect);
  HapticService.trigger(HapticIntensity.medium);
}
```

---

## Implementation Checklist

### Phase 1: Foundation (Week 1)
- [ ] Implement custom page transitions with reduce motion support
- [ ] Add HapticService with intensity patterns
- [ ] Create SuccessFeedbackOverlay and ErrorBanner components
- [ ] Add semantic labels to all interactive elements
- [ ] Test with VoiceOver (iOS) and TalkBack (Android)

### Phase 2: Polish (Week 2)
- [ ] Add stagger animations to list views
- [ ] Implement skeleton loading states
- [ ] Create bounce/scale micro-interactions for buttons
- [ ] Add sound effects with volume control
- [ ] Coordinate haptics + sound for major events

### Phase 3: Accessibility (Week 3)
- [ ] Audit color contrast ratios (use Contrast Checker tool)
- [ ] Implement high contrast mode
- [ ] Add keyboard navigation for all interactive elements
- [ ] Test with text scale at 1.4x
- [ ] Verify reduce motion disables all non-essential animations

### Phase 4: Testing & Refinement (Week 4)
- [ ] User testing with accessibility tools enabled
- [ ] Performance testing (60 FPS on low-end devices)
- [ ] A/B test animation durations for optimal feel
- [ ] Analytics review of reduce motion adoption rate
- [ ] Final polish based on user feedback

---

## Performance Monitoring

### Animation Performance

```dart
// Track animation frame rate
class AnimationPerformanceMonitor {
  static void trackAnimation(String name, VoidCallback animation) {
    final stopwatch = Stopwatch()..start();

    animation();

    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;

    if (duration > 16) {
      // Dropped frames (60 FPS = 16.67ms per frame)
      AnalyticsLogger.logEvent('animation_jank', parameters: {
        'animation_name': name,
        'duration_ms': duration,
      });
    }
  }
}
```

---

## Success Metrics

**Track these KPIs:**

1. **Accessibility Adoption**
   - % users enabling reduce motion
   - % users adjusting text scale
   - Screen reader usage rate

2. **Engagement Impact**
   - Session duration change after UX polish
   - Feature discovery rate (before/after animations)
   - Conversion rate on animated CTAs

3. **Performance**
   - Average FPS during animations
   - Animation jank rate (frames dropped)
   - Battery impact of particle effects

---

## Resources

- [Material Design Motion](https://m3.material.io/styles/motion/overview)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Animate Package](https://pub.dev/packages/flutter_animate)
- [iOS HIG - Haptic Feedback](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- [Android Motion Design](https://m3.material.io/styles/motion/transitions/transition-patterns)

---

**Estimated Impact:** +$30K-60K valuation from premium UX and accessibility compliance
