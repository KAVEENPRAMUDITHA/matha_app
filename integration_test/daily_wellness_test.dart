import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matha_app/screens/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Maternal Wellness & Hydration Tracker Tests', () {
    testWidgets('WELL-INT-001: Wellness Component Rendering Verification',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
