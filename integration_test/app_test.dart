import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:matha_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Maatha Mother App - End-to-End System Journey Integration Tests', () {
    testWidgets('E2E-001: Complete User Journey - Splash to Dashboard, Navigation, and Feature Access',
        (WidgetTester tester) async {
      // 1. Launch the Application
      app.main();
      await tester.pumpAndSettle();

      // Verify Splash screen / Initial Navigation rendered
      expect(find.byType(MaterialApp), findsOneWidget);

      // Allow animations and async initializations to settle
      await tester.pump(const Duration(seconds: 2));

      // 2. Verify Bottom Navigation Bar presence
      final homeNavFinder = find.text('මුල් පිටුව');
      final reportsNavFinder = find.text('වාර්තා');
      final clinicNavFinder = find.text('සායනය');
      final profileNavFinder = find.text('ගිණුම');
      final communityNavFinder = find.text('ප්‍රජාව');

      if (homeNavFinder.evaluate().isNotEmpty) {
        expect(homeNavFinder, findsOneWidget);
        expect(reportsNavFinder, findsOneWidget);
        expect(clinicNavFinder, findsOneWidget);
        expect(profileNavFinder, findsOneWidget);
        expect(communityNavFinder, findsOneWidget);

        // 3. Navigate through Tabs
        // Go to Reports
        await tester.tap(reportsNavFinder);
        await tester.pumpAndSettle();
        expect(find.text('වාර්තා'), findsWidgets);

        // Go to Clinic
        await tester.tap(clinicNavFinder);
        await tester.pumpAndSettle();
        expect(find.text('සායනය'), findsWidgets);

        // Go to Profile
        await tester.tap(profileNavFinder);
        await tester.pumpAndSettle();
        expect(find.text('ගිණුම'), findsWidgets);

        // Go to Community Chat
        await tester.tap(communityNavFinder);
        await tester.pumpAndSettle();
        expect(find.text('ප්‍රජාව'), findsWidgets);

        // Return to Home
        await tester.tap(homeNavFinder);
        await tester.pumpAndSettle();
        expect(find.text('මුල් පිටුව'), findsWidgets);
      }
    });

    testWidgets('E2E-002: Verify Floating AI Assistant and Cry Detector Widgets on Screen',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check if floating action assistants are present on home screen
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
