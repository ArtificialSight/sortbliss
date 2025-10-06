import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sortbliss/widgets/custom_icon_widget.dart';

void main() {
  testWidgets('falls back to help icon for unknown icon names', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomIconWidget(iconName: 'non_existent_icon'),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, equals(Icons.help_outline));
  });
}
