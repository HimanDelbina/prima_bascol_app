import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/widgets/status_badge.dart';
import 'package:prima_bascol_app/core/widgets/risk_badge.dart';

void main() {
  testWidgets('StatusBadge displays correct text and color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(code: 'completed', label: 'تکمیل شده'),
        ),
      ),
    );

    expect(find.text('تکمیل شده'), findsOneWidget);
  });

  testWidgets('RiskBadge displays score and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RiskBadge(riskScore: 85, riskLevel: 'critical'),
        ),
      ),
    );

    expect(find.text('بحرانی (85)'), findsOneWidget);
  });
}