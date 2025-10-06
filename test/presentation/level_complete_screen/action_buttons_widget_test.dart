import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import 'package:sortbliss/presentation/level_complete_screen/widgets/action_buttons_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget _buildTestWidget() {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          home: Scaffold(
            body: ActionButtonsWidget(
              onNextLevel: () {},
              onReplayLevel: () {},
              onShareScore: () {},
              showAdButton: false,
            ),
          ),
        );
      },
    );
  }

  testWidgets('renders replay and share icons for secondary buttons', (tester) async {
    await tester.pumpWidget(_buildTestWidget());
    await tester.pump();

    expect(find.byIcon(Icons.replay), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
  });
}
