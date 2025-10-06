import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:sortbliss/core/gesture_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GestureController dispose', () {
    late GestureController controller;

    setUp(() {
      controller = GestureController();
      controller.setTestMode(true);
      controller.setInitializationOverride(() async {});
    });

    tearDown(() {
      controller.setSensorSubscriptionsForTesting();
      controller.setInitializationOverride(null);
      controller.setTestMode(false);
    });

    test('cancels sensor subscriptions', () async {
      var accelerometerCancelled = false;
      var gyroscopeCancelled = false;

      final accelerometerController = StreamController<AccelerometerEvent>(
        onCancel: () {
          accelerometerCancelled = true;
          return Future.value();
        },
      );
      final gyroscopeController = StreamController<GyroscopeEvent>(
        onCancel: () {
          gyroscopeCancelled = true;
          return Future.value();
        },
      );

      final accelerometerSubscription =
          accelerometerController.stream.listen((_) {});
      final gyroscopeSubscription = gyroscopeController.stream.listen((_) {});

      controller.setSensorSubscriptionsForTesting(
        accelerometer: accelerometerSubscription,
        gyroscope: gyroscopeSubscription,
      );

      controller.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(accelerometerCancelled, isTrue);
      expect(gyroscopeCancelled, isTrue);

      await accelerometerController.close();
      await gyroscopeController.close();
    });
  });
}
