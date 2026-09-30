import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/ui/inspector/need_row.dart';

void main() {
  testWidgets('NeedRow formats value to exactly one decimal place', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NeedRow(label: 'Hunger', value: 33.383)),
      ),
    );

    expect(find.text('Hunger'), findsOneWidget);
    expect(find.text('33.4'), findsOneWidget);
  });
}
