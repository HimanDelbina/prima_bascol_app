import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/widgets/iranian_plate_widget.dart';

void main() {
  testWidgets('IranianPlateWidget renders parts properly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IranianPlateWidget(
            plateNumber: '12ع34572',
            compact: false,
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('ع'), findsOneWidget);
    expect(find.text('345'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('ایران'), findsOneWidget);
  });
}
