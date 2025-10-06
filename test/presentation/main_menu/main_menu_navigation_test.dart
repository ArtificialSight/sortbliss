import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'package:sortbliss/presentation/main_menu/main_menu.dart';
import 'package:sortbliss/routes/app_routes.dart';

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    pushedRoutes.add(route);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tapping the play button navigates to gameplay',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object?>{});

      final _RecordingNavigatorObserver observer =
          _RecordingNavigatorObserver();

      await tester.pumpWidget(
        Sizer(
          builder: (BuildContext context, Orientation orientation,
              DeviceType deviceType) {
            return MaterialApp(
              routes: AppRoutes.routes,
              navigatorObservers: <NavigatorObserver>[observer],
              home: const MainMenu(),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final Finder playButtonFinder = find.text('PLAY');
      expect(playButtonFinder, findsOneWidget);

      await tester.tap(playButtonFinder);
      await tester.pumpAndSettle();

      expect(
        observer.pushedRoutes.map((Route<dynamic> route) => route.settings.name),
        contains(AppRoutes.gameplay),
      );
    },
  );
}
