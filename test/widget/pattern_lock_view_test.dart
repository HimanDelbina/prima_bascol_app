import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/security/presentation/widgets/pattern_lock_view.dart';

void main() {
  testWidgets('PatternLockView renders and triggers onPatternComplete with touched nodes',
      (WidgetTester tester) async {
    List<int>? capturedPattern;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PatternLockView(
              dimension: 300,
              onPatternComplete: (pattern) {
                capturedPattern = pattern;
              },
            ),
          ),
        ),
      ),
    );

    // Find the PatternLockView
    final patternFinder = find.byType(PatternLockView);
    expect(patternFinder, findsOneWidget);

    // Perform a pan gesture across top row: from (50, 50) to (150, 50) to (250, 50)
    final topLeft = tester.getTopLeft(patternFinder);

    final node0 = topLeft + const Offset(50, 50);
    final node1 = topLeft + const Offset(150, 50);
    final node2 = topLeft + const Offset(250, 50);
    final node5 = topLeft + const Offset(250, 150);

    final gesture = await tester.startGesture(node0);
    await tester.pump();

    await gesture.moveTo(node1);
    await tester.pump();

    await gesture.moveTo(node2);
    await tester.pump();

    await gesture.moveTo(node5);
    await tester.pump();

    await gesture.up();
    await tester.pumpAndSettle();

    expect(capturedPattern, isNotNull);
    expect(capturedPattern, containsAllInOrder([0, 1, 2, 5]));
  });
}
