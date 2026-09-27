import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matha_app/screens/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication & Session Integration Tests', () {
    testWidgets('AUTH-INT-001: Validate Empty Input Submissions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Locate login button and tap without entering NIC / Password
      final loginButtonFinder = find.widgetWithText(ElevatedButton, 'ඇතුල් වන්න / Login');
      expect(loginButtonFinder, findsOneWidget);

      await tester.tap(loginButtonFinder);
      await tester.pump();

      // Expect error SnackBar
      expect(
        find.text('කරුණාකර සියලු විස්තර ඇතුළත් කරන්න.\nPlease fill all details.'),
        findsOneWidget,
      );
    });

    testWidgets('AUTH-INT-002: Enter Invalid Credentials and Verify Error Handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Enter invalid NIC and Password
      await tester.enterText(textFields.first, '999999999V');
      await tester.enterText(textFields.last, 'wrongpassword');
      await tester.pump();

      final loginButtonFinder = find.widgetWithText(ElevatedButton, 'ඇතුල් වන්න / Login');
      await tester.tap(loginButtonFinder);
      await tester.pump();

      // Verify loading state appears
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
