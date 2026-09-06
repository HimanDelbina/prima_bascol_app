import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/widgets/app_card.dart';

void main() {
  testWidgets('AppCard with ListTile paints ink splashes without Flutter assertion',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            child: ListTile(
              title: const Text('تنظیمات امنیتی'),
              selectedColor: const Color(0xFF0F766E),
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('تنظیمات امنیتی'), findsOneWidget);

    // Tap ListTile to trigger ink splash
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
