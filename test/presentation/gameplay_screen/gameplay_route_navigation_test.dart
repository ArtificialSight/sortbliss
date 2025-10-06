import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortbliss/routes/app_routes.dart';

void main() {
  testWidgets('navigating to gameplay without args shows fallback UI', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.gameplay,
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        "We couldn't load this level. Please return to the main menu and try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('Return to Main Menu'), findsOneWidget);
  });
}
