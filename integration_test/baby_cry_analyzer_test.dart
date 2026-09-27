import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matha_app/screens/baby_cry_analyzer_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Baby Cry Analyzer AI Module Integration Tests', () {
    testWidgets('CRY-INT-001: Cry Analyzer Screen Initial State and UI Elements Verification',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BabyCryAnalyzerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify UI title, instructions, and microphone button
      expect(find.text('බිළිඳු හඬ විශ්ලේෂකය'), findsOneWidget);
      expect(find.text('AI BABY CRY ANALYZER'), findsOneWidget);
      expect(find.text('හඬ පටිගත කරන්න (5s)'), findsOneWidget);

      // Verify Info Tip Card
      expect(find.text('උපදෙස් / How it works:'), findsOneWidget);
    });

    testWidgets('CRY-INT-002: Cry Analyzer Modal Close and Navigation Behavior',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BabyCryAnalyzerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Close IconButton exists
      final closeButtonFinder = find.byIcon(Icons.close_rounded);
      expect(closeButtonFinder, findsOneWidget);
    });
  });
}
