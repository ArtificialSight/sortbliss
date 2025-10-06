import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import 'package:sortbliss/presentation/level_complete_screen/level_complete_screen.dart';
import 'package:sortbliss/presentation/level_complete_screen/widgets/action_buttons_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleLevelData = <String, dynamic>{
    'level': 5,
    'levelTitle': 'Level 5 Complete',
    'completionTime': 'in 02:15',
    'difficulty': 'Expert',
    'starsEarned': 3,
    'basePoints': 1250,
    'timeBonus': 450,
    'moveEfficiency': 300,
    'totalScore': 2000,
    'progressToNext': 0.65,
    'nextMilestone': 'Unlock Hard Mode',
    'bestMoves': 28,
    'coinsEarned': 75,
  };

  Widget _buildTestWidget(LevelCompleteScreen screen) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          home: Scaffold(body: screen),
        );
      },
    );
  }

  group('LevelCompleteScreen', () {
    const MethodChannel shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

    MethodCall? lastShareCall;

    setUp(() {
      lastShareCall = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(shareChannel, (methodCall) async {
        lastShareCall = methodCall;
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(shareChannel, null);
    });

    testWidgets('renders successfully with provided level data', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          LevelCompleteScreen(levelData: sampleLevelData),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Level 5 Complete'), findsOneWidget);
      expect(find.textContaining('Expert'), findsOneWidget);
      expect(find.text('Total Score'), findsOneWidget);
      expect(find.byType(ActionButtonsWidget), findsOneWidget);
    });

    testWidgets('invokes callbacks for share and action buttons', (tester) async {
      var nextInvoked = false;
      var replayInvoked = false;
      var adInvoked = false;
      var shareCallbackInvoked = false;

      await tester.pumpWidget(
        _buildTestWidget(
          LevelCompleteScreen(
            levelData: sampleLevelData,
            onNextLevel: () => nextInvoked = true,
            onReplayLevel: () => replayInvoked = true,
            onWatchAd: () => adInvoked = true,
            onShareScore: () => shareCallbackInvoked = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Next Level'));
      await tester.pump();

      await tester.tap(find.text('Replay'));
      await tester.pump();

      await tester.tap(find.text('Share'));
      await tester.pump();

      await tester.tap(find.text('Watch Ad for 2x Coins'));
      await tester.pump();

      expect(nextInvoked, isTrue);
      expect(replayInvoked, isTrue);
      expect(adInvoked, isTrue);
      expect(shareCallbackInvoked, isTrue);
      expect(lastShareCall, isNotNull);
      expect(lastShareCall!.method, equals('share'));
    });
  });
}
