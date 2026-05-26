// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtf_shared/services/services.dart';

import 'package:guru_app/main.dart';

void main() {
  testWidgets('Guru app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': false});

    await tester.pumpWidget(
      ProviderScope(child: GuruApp(authService: AuthService())),
    );

    expect(find.byType(GuruApp), findsOneWidget);
  });
}
