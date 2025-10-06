import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:sortbliss/core/gesture_controller.dart';
import 'package:sortbliss/presentation/gameplay_screen/widgets/adaptive_tutorial_widget.dart';

class _MockGestureController extends Mock implements GestureController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue<String>('');
    registerFallbackValue<bool>(false);
  });

  late _MockGestureController gestureController;

  setUp(() {
    gestureController = _MockGestureController();
    when(() => gestureController.dispose()).thenReturn(null);
    when(() => gestureController.ttsEnabled).thenReturn(true);
    when(() => gestureController.announceGameEvent(any(),
            interrupt: any(named: 'interrupt')))
        .thenAnswer((_) async {});
  });

  Widget _buildWidget({required GestureController controller}) {
    return MaterialApp(
      home: AdaptiveTutorialWidget(
        currentLevel: 1,
        isFirstTime: true,
        userSpeed: 1.0,
        completedActions: const [],
        onActionCompleted: (_) {},
        onTutorialCompleted: () {},
        gestureController: controller,
      ),
    );
  }

  testWidgets('voice hints are enabled only after initialization completes',
      (tester) async {
    final completer = Completer<void>();
    when(() => gestureController.initialize()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_buildWidget(controller: gestureController));

    final state =
        tester.state(find.byType(AdaptiveTutorialWidget)) as dynamic;
    expect(state.voiceEnabledForTesting, isFalse);
    verify(() => gestureController.initialize()).called(1);
    verifyNever(() => gestureController.announceGameEvent(any(),
        interrupt: any(named: 'interrupt')));

    completer.complete();
    await tester.pump();

    expect(state.voiceEnabledForTesting, isTrue);
    verify(() => gestureController.announceGameEvent(any(),
        interrupt: any(named: 'interrupt'))).called(1);
  });

  testWidgets('voice hints remain disabled when initialization fails',
      (tester) async {
    when(() => gestureController.initialize())
        .thenThrow(Exception('initialization failed'));

    await tester.pumpWidget(_buildWidget(controller: gestureController));
    await tester.pump();

    final state =
        tester.state(find.byType(AdaptiveTutorialWidget)) as dynamic;
    expect(state.voiceEnabledForTesting, isFalse);

    verifyNever(() => gestureController.announceGameEvent(any(),
        interrupt: any(named: 'interrupt')));
  });
}
