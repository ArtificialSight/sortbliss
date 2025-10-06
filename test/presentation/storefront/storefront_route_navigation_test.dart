import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortbliss/routes/app_routes.dart';

void main() {
  testWidgets('navigating to storefront shows storefront screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.storefront,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Storefront'), findsOneWidget);
    expect(
      find.text(
        'Unlock premium audio sets and seasonal themes to personalize your experience.',
      ),
      findsOneWidget,
    );
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
