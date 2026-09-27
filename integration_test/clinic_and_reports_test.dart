import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matha_app/screens/clinic_screen.dart';
import 'package:matha_app/screens/reports_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Clinic Timeline & Medical Reports Integration Tests', () {
    testWidgets('CLINIC-INT-001: Clinic Screen Initial Rendering', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ClinicScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('සායන වාර්තා / CLINIC TIMELINE'), findsOneWidget);
    });

    testWidgets('REP-INT-001: Medical Reports Screen and Category Filter Badges',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReportsScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('සියල්ල'), findsWidgets);
      expect(find.text('📷 ස්කෑන් (Scans)'), findsOneWidget);
      expect(find.text('🧪 රුධිර (Blood)'), findsOneWidget);
      expect(find.text('💊 බෙහෙත් (Rx)'), findsOneWidget);
    });
  });
}
