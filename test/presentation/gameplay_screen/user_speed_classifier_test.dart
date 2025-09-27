import 'package:flutter_test/flutter_test.dart';
import 'package:sortbliss/presentation/gameplay_screen/user_speed_classifier.dart';

void main() {
  group('classifyUserSpeed', () {
    test('identifies fast users at or above the fast threshold', () {
      expect(classifyUserSpeed(kFastUserSpeedThreshold), UserSpeedProfile.fast);
      expect(classifyUserSpeed(2.0), UserSpeedProfile.fast);
    });

    test('identifies slow users at or below the slow threshold', () {
      expect(classifyUserSpeed(kSlowUserSpeedThreshold), UserSpeedProfile.slow);
      expect(classifyUserSpeed(0.5), UserSpeedProfile.slow);
    });

    test('defaults to balanced when within thresholds', () {
      expect(classifyUserSpeed(1.0), UserSpeedProfile.balanced);
    });
  });

  group('calculateAdaptiveDelay', () {
    test('returns fast delay for fast users', () {
      expect(
        calculateAdaptiveDelay(kFastUserSpeedThreshold),
        kFastUserAdaptiveDelay,
      );
    });

    test('returns slow delay for slow users', () {
      expect(
        calculateAdaptiveDelay(kSlowUserSpeedThreshold),
        kSlowUserAdaptiveDelay,
      );
    });

    test('returns balanced delay otherwise', () {
      expect(
        calculateAdaptiveDelay(1.0),
        kBalancedUserAdaptiveDelay,
      );
    });

    test('supports custom thresholds and delays', () {
      const customFastThreshold = 1.2;
      const customSlowThreshold = 0.9;
      const customFastDelay = 0.5;
      const customSlowDelay = 1.8;
      const customBalancedDelay = 1.1;

      expect(
        calculateAdaptiveDelay(
          1.3,
          fastThreshold: customFastThreshold,
          slowThreshold: customSlowThreshold,
          fastDelay: customFastDelay,
          slowDelay: customSlowDelay,
          balancedDelay: customBalancedDelay,
        ),
        customFastDelay,
      );

      expect(
        calculateAdaptiveDelay(
          0.8,
          fastThreshold: customFastThreshold,
          slowThreshold: customSlowThreshold,
          fastDelay: customFastDelay,
          slowDelay: customSlowDelay,
          balancedDelay: customBalancedDelay,
        ),
        customSlowDelay,
      );

      expect(
        calculateAdaptiveDelay(
          1.0,
          fastThreshold: customFastThreshold,
          slowThreshold: customSlowThreshold,
          fastDelay: customFastDelay,
          slowDelay: customSlowDelay,
          balancedDelay: customBalancedDelay,
        ),
        customBalancedDelay,
      );
    });
  });
}
