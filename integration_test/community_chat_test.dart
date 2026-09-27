import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matha_app/screens/community_chat_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Maternal Community Chat & Guidelines Integration Tests', () {
    testWidgets('COMM-INT-001: Community Chat Screen Filter Badges Verification',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommunityChatScreen(isTab: true),
          ),
        ),
      );
      await tester.pump();

      // Verify category filter chips
      expect(find.text('සියල්ල'), findsWidgets);
      expect(find.text('💬 සාමාන්‍ය'), findsOneWidget);
      expect(find.text('❓ ප්‍රශ්න'), findsOneWidget);
      expect(find.text('💡 උපදෙස්'), findsOneWidget);
      expect(find.text('👩‍⚕️ වින්නඹු උපදෙස්'), findsOneWidget);
    });
  });
}
