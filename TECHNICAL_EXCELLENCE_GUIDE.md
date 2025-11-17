# Technical Excellence Guide

**Objective:** Ensure SortBliss runs smoothly on all devices, handles errors gracefully, and works offline.

---

## Table of Contents

1. [Performance Optimization](#performance-optimization)
2. [Offline Mode Implementation](#offline-mode-implementation)
3. [Error Recovery System](#error-recovery-system)
4. [Testing Strategy](#testing-strategy)
5. [Security Best Practices](#security-best-practices)
6. [Production Checklist](#production-checklist)

---

## Performance Optimization

### Target Metrics

**Frame Rate:**
- Maintain 60 FPS during gameplay
- 30 FPS minimum acceptable
- No dropped frames during animations

**Memory:**
- < 150 MB base memory usage
- < 300 MB peak usage (with caching)
- No memory leaks during extended play

**App Launch Time:**
- Cold start: < 2 seconds
- Warm start: < 1 second
- Hot resume: < 0.5 seconds

**Battery Usage:**
- < 5% per hour during active play
- < 1% per hour in background

### Optimization Techniques

#### 1. Widget Performance

**Use const constructors:**
```dart
// Bad
Widget build(BuildContext context) {
  return Container(
    child: Text('Level 1'),
  );
}

// Good
Widget build(BuildContext context) {
  return const Text('Level 1');
}
```

**Avoid expensive builds:**
```dart
// Bad - rebuilds entire list
ListView.builder(
  itemCount: levels.length,
  itemBuilder: (context, index) {
    return LevelCard(level: levels[index]);
  },
);

// Good - use keys for efficient updates
ListView.builder(
  itemCount: levels.length,
  itemBuilder: (context, index) {
    return LevelCard(
      key: ValueKey(levels[index].id),
      level: levels[index],
    );
  },
);
```

#### 2. Image Optimization

**Caching strategy:**
```dart
class OptimizedImageLoader {
  static final Map<String, ui.Image> _cache = {};

  static Future<ui.Image> loadImage(String path) async {
    if (_cache.containsKey(path)) {
      return _cache[path]!;
    }

    final data = await rootBundle.load(path);
    final image = await decodeImageFromList(data.buffer.asUint8List());
    _cache[path] = image;

    return image;
  }

  static void clearCache() {
    _cache.clear();
  }
}
```

**Image sizing:**
```
Never load 4K images for small thumbnails:
- Thumbnails: 128x128 max
- Cards: 512x512 max
- Full screen: 1024x1024 max
```

#### 3. Animation Performance

**Use AnimatedBuilder instead of setState:**
```dart
// Bad - rebuilds entire widget tree
class AnimatedCard extends StatefulWidget {
  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      transform: Matrix4.rotationZ(_controller.value * 3.14),
      child: ExpensiveWidget(), // Rebuilds every frame!
    );
  }
}

// Good - only rebuilds animated portion
class AnimatedCard extends StatelessWidget {
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 3.14,
          child: child,
        );
      },
      child: const ExpensiveWidget(), // Built once!
    );
  }
}
```

#### 4. List Performance

**Use ListView.builder for long lists:**
```dart
// Bad - builds all items upfront
ListView(
  children: List.generate(1000, (i) => LevelCard(level: i)),
)

// Good - builds only visible items
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) => LevelCard(level: index),
)
```

**Virtual scrolling with slivers:**
```dart
CustomScrollView(
  slivers: [
    SliverAppBar(/* header */),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => LevelCard(level: index),
        childCount: levels.length,
      ),
    ),
  ],
)
```

#### 5. Compute Isolation

**Offload heavy computations:**
```dart
Future<List<Level>> generateLevels() async {
  return await compute(_generateLevelsIsolate, 100);
}

// Runs in separate isolate (no UI blocking)
static List<Level> _generateLevelsIsolate(int count) {
  final levels = <Level>[];
  for (int i = 0; i < count; i++) {
    // Heavy level generation logic
    levels.add(_generateComplexLevel(i));
  }
  return levels;
}
```

#### 6. Lazy Loading

**Defer non-critical initialization:**
```dart
class AppInitializer {
  static Future<void> initialize() async {
    // Critical (blocking)
    await Firebase.initializeApp();
    await PlayerProfileService.instance.ensureInitialized();

    // Non-critical (async)
    unawaited(AchievementsTrackerService.instance.initialize());
    unawaited(DailyRewardsService.instance.initialize());
    unawaited(NotificationService.instance.initialize());
  }
}
```

### Performance Monitoring

**Track frame rendering:**
```dart
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static void startMonitoring() {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameDuration = timing.totalSpan.inMilliseconds;

        if (frameDuration > 16) {
          // Dropped frame (60 FPS = 16.67ms per frame)
          AnalyticsLogger.logEvent('frame_jank', parameters: {
            'duration_ms': frameDuration,
            'build_ms': timing.buildDuration.inMilliseconds,
            'raster_ms': timing.rasterDuration.inMilliseconds,
          });
        }
      }
    });
  }
}
```

---

## Offline Mode Implementation

### Core Gameplay Offline

**SortBliss should work fully offline for gameplay:**

```dart
class OfflineManager {
  static bool isOffline = false;

  // Check connectivity
  static Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    isOffline = result == ConnectivityResult.none;

    if (isOffline) {
      AnalyticsLogger.logEvent('app_offline_detected');
    }
  }

  // Queue operations for later sync
  static final List<PendingOperation> _queue = [];

  static void queueOperation(PendingOperation op) {
    _queue.add(op);
    _saveQueue();
  }

  // Sync when online
  static Future<void> syncWhenOnline() async {
    if (isOffline || _queue.isEmpty) return;

    for (final op in _queue) {
      try {
        await op.execute();
        _queue.remove(op);
      } catch (e) {
        // Keep in queue, retry later
        break;
      }
    }

    await _saveQueue();
  }
}
```

### Offline Data Sync

**Queue system for pending operations:**
```dart
abstract class PendingOperation {
  Future<void> execute();
  Map<String, dynamic> toJson();
}

class PurchaseOperation extends PendingOperation {
  final String productId;
  final String receiptData;

  PurchaseOperation(this.productId, this.receiptData);

  @override
  Future<void> execute() async {
    // Validate receipt with backend when online
    await MonetizationManager.instance.validateReceipt(
      productId: productId,
      receiptData: receiptData,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'purchase',
    'product_id': productId,
    'receipt_data': receiptData,
  };
}
```

### Offline Indicators

**Show offline banner:**
```dart
class OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final isOffline = snapshot.data == ConnectivityResult.none;

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          color: Colors.orange,
          padding: EdgeInsets.all(2.h),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white),
              SizedBox(width: 2.w),
              const Text(
                'You\'re offline. Some features may be limited.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## Error Recovery System

### Graceful Error Handling

**Try-catch with fallbacks:**
```dart
Future<List<Level>> loadLevels() async {
  try {
    // Try loading from network
    return await _loadLevelsFromNetwork();
  } catch (e) {
    debugPrint('Network load failed, trying cache');

    try {
      // Fallback to cache
      return await _loadLevelsFromCache();
    } catch (e2) {
      debugPrint('Cache load failed, using defaults');

      // Fallback to defaults
      return _getDefaultLevels();
    }
  }
}
```

### Retry Logic

**Exponential backoff:**
```dart
class RetryHelper {
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxAttempts) {
          rethrow;
        }

        debugPrint('Retry attempt $attempts after ${delay.inSeconds}s');
        await Future.delayed(delay);

        // Exponential backoff: 1s, 2s, 4s, 8s...
        delay *= 2;
      }
    }
  }
}

// Usage:
final levels = await RetryHelper.retry(
  operation: () => api.fetchLevels(),
  maxAttempts: 3,
);
```

### Error Reporting

**User-friendly error messages:**
```dart
class ErrorHandler {
  static void handle(dynamic error, StackTrace? stackTrace) {
    // Log to analytics
    TelemetryManager.instance.recordError(error, stackTrace);

    // Show user-friendly message
    final message = _getUserMessage(error);
    _showErrorSnackbar(message);
  }

  static String _getUserMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    }
    if (error is AuthException) {
      return 'Authentication failed. Please sign in again.';
    }
    if (error is ServerException) {
      return 'Server error. We\'re working on it!';
    }
    return 'Something went wrong. Please try again.';
  }

  static void _showErrorSnackbar(String message) {
    // Show snackbar to user
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'RETRY',
          onPressed: () {
            // Retry last operation
          },
        ),
      ),
    );
  }
}
```

### Crash Recovery

**Save state before crash:**
```dart
class CrashRecovery {
  static Future<void> saveGameState() async {
    try {
      final state = GameState(
        currentLevel: GameManager.instance.currentLevel,
        score: GameManager.instance.score,
        moves: GameManager.instance.moves,
        boardState: GameManager.instance.boardState,
      );

      await _prefs.setString('crash_recovery_state', jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('Failed to save crash recovery state: $e');
    }
  }

  static Future<GameState?> recoverGameState() async {
    try {
      final stateJson = _prefs.getString('crash_recovery_state');
      if (stateJson == null) return null;

      final state = GameState.fromJson(jsonDecode(stateJson));
      await _prefs.remove('crash_recovery_state'); // Clear after recovery

      return state;
    } catch (e) {
      debugPrint('Failed to recover game state: $e');
      return null;
    }
  }
}

// On app start:
final recoveredState = await CrashRecovery.recoverGameState();
if (recoveredState != null) {
  // Show recovery dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Recover Game?'),
      content: const Text('We detected an incomplete game. Resume?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Start Fresh'),
        ),
        FilledButton(
          onPressed: () {
            GameManager.instance.restoreState(recoveredState);
            Navigator.pop(context);
          },
          child: const Text('Resume'),
        ),
      ],
    ),
  );
}
```

---

## Testing Strategy

### Unit Tests

**Test business logic:**
```dart
void main() {
  group('LevelProgressionService', () {
    late LevelProgressionService service;

    setUp(() {
      service = LevelProgressionService.instance;
      service.resetForTesting();
    });

    test('unlocks first tier on initialization', () async {
      await service.initialize();
      final unlocked = service.getUnlockedLevels();

      expect(unlocked.length, 10);
      expect(unlocked.first, 1);
      expect(unlocked.last, 10);
    });

    test('awards XP correctly', () async {
      await service.initialize();
      final result = await service.completeLevel(
        level: 1,
        starsEarned: 3,
        baseScore: 1000,
        isPerfect: true,
      );

      expect(result.xpEarned, 100 + (3 * 50) + 150); // 400 XP
      expect(result.starsEarned, 3);
    });

    test('unlocks tier when stars requirement met', () async {
      await service.initialize();

      // Complete 5 levels with 3 stars each (15 stars)
      for (int i = 1; i <= 5; i++) {
        await service.completeLevel(
          level: i,
          starsEarned: 3,
          baseScore: 1000,
        );
      }

      final unlocked = service.getUnlockedLevels();
      expect(unlocked.length, 20); // Initial 10 + next tier 10
    });
  });
}
```

### Widget Tests

**Test UI components:**
```dart
void main() {
  testWidgets('LevelCardWidget shows lock icon when locked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LevelCardWidget(
          level: 15,
          isUnlocked: false,
          stars: 0,
          difficulty: LevelDifficulty.medium,
        ),
      ),
    );

    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text('15'), findsNothing);
  });

  testWidgets('LevelCardWidget shows stars when unlocked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LevelCardWidget(
          level: 5,
          isUnlocked: true,
          stars: 2,
          difficulty: LevelDifficulty.easy,
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(2));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });
}
```

### Integration Tests

**Test end-to-end flows:**
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete level and claim reward flow', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Navigate to level 1
    await tester.tap(find.text('Level 1'));
    await tester.pumpAndSettle();

    // Complete level
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    // ... gameplay interactions ...

    // Verify level complete screen
    expect(find.text('Level Complete'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(3));

    // Claim daily reward
    await tester.tap(find.text('Claim Reward'));
    await tester.pumpAndSettle();

    // Verify coins increased
    expect(find.textContaining('100 coins'), findsOneWidget);
  });
}
```

### Performance Tests

**Measure frame rate:**
```dart
void main() {
  testWidgets('maintains 60 FPS during gameplay', (tester) async {
    await tester.pumpWidget(const GameplayScreen());

    final binding = tester.binding;
    int droppedFrames = 0;

    binding.addPersistentFrameCallback((duration) {
      if (duration.inMilliseconds > 16) {
        droppedFrames++;
      }
    });

    // Simulate 5 seconds of gameplay
    for (int i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Allow max 5% dropped frames
    expect(droppedFrames, lessThan(15));
  });
}
```

---

## Security Best Practices

### 1. API Key Security

**Never commit secrets to git:**
```dart
// Bad
const String apiKey = 'sk_live_1234567890abcdef';

// Good - use environment variables
final apiKey = dotenv.env['API_KEY']!;
```

**Git ignore sensitive files:**
```
.env
.env.local
google-services.json
GoogleService-Info.plist
firebase_options.dart
```

### 2. Input Validation

**Sanitize user input:**
```dart
String sanitizeInput(String input) {
  // Remove HTML tags
  input = input.replaceAll(RegExp(r'<[^>]*>'), '');

  // Limit length
  if (input.length > 100) {
    input = input.substring(0, 100);
  }

  // Escape special characters
  input = HtmlEscape().convert(input);

  return input;
}
```

### 3. Secure Storage

**Use flutter_secure_storage for sensitive data:**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Store
await storage.write(key: 'user_token', value: token);

// Read
final token = await storage.read(key: 'user_token');

// Delete
await storage.delete(key: 'user_token');
```

### 4. Certificate Pinning

**Prevent man-in-the-middle attacks:**
```dart
import 'package:dio/dio.dart';
import 'package:dio_cert_pinning/dio_cert_pinning.dart';

final dio = Dio();

// Pin certificate
await dio.interceptors.add(
  CertificatePinningInterceptor(
    allowedSHAFingerprints: [
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    ],
  ),
);
```

### 5. ProGuard/R8 (Android)

**Obfuscate code in release builds:**
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

## Production Checklist

### Pre-Launch

#### Code Quality
- [ ] All warnings resolved
- [ ] No debug print statements in production
- [ ] Proper error handling everywhere
- [ ] Analytics tracking on all key events
- [ ] Crash reporting configured

#### Performance
- [ ] App launch < 2 seconds
- [ ] No frame drops during gameplay
- [ ] Memory leaks fixed
- [ ] Battery usage < 5%/hour
- [ ] App size < 150 MB

#### Testing
- [ ] Unit tests passing (80%+ coverage)
- [ ] Widget tests passing
- [ ] Integration tests passing
- [ ] Manual QA on 5+ devices
- [ ] Beta testing complete (50+ users)

#### Security
- [ ] API keys in environment variables
- [ ] Certificate pinning enabled
- [ ] Code obfuscation enabled (release)
- [ ] Sensitive data encrypted
- [ ] Receipt validation implemented

#### Monetization
- [ ] IAP products configured
- [ ] Ad units created (production IDs)
- [ ] Receipt validation tested
- [ ] Payment flow tested
- [ ] Refund policy documented

#### Compliance
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] COPPA compliance (if applicable)
- [ ] GDPR compliance (EU users)
- [ ] App Store guidelines reviewed

### Post-Launch Monitoring

**Week 1:**
- [ ] Monitor crash-free rate (target: 99.5%+)
- [ ] Check ANR rate (target: <0.5%)
- [ ] Review retention metrics (D1, D7)
- [ ] Monitor IAP transaction success rate
- [ ] Check ad fill rate and eCPM

**Week 2-4:**
- [ ] A/B test results review
- [ ] Performance optimization based on data
- [ ] Bug fixes for top reported issues
- [ ] Prepare first content update

---

## Performance Benchmarks

**Target Device Classes:**
```
High-end (iPhone 13+, Pixel 6+):
- 60 FPS constant
- Launch: < 1.5 seconds
- Memory: < 200 MB

Mid-range (iPhone 11, Pixel 4a):
- 60 FPS gameplay, 45 FPS animations
- Launch: < 2 seconds
- Memory: < 250 MB

Low-end (iPhone 8, Pixel 3a):
- 45 FPS gameplay, 30 FPS animations
- Launch: < 3 seconds
- Memory: < 300 MB
```

---

## Estimated Impact

**Technical Excellence Benefits:**
- 99.5%+ crash-free rate → Better ratings (4.5+ stars)
- Offline mode → +5% retention (playable anywhere)
- Fast loading → -20% bounce rate (first impression)
- Low battery usage → Longer sessions (+10-15%)
- Smooth performance → Better reviews and word-of-mouth

**Valuation Impact:** +$50K-100K (reduced churn from technical issues)
