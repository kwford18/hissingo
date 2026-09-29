import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hissingo/main.dart';
import 'package:hissingo/terrarium_game.dart';

void main() {
  testWidgets('Hissingo app loads UI and GameWidget', (
    WidgetTester tester,
  ) async {
    // Build app and trigger a frame
    await tester.pumpWidget(const HissingoApp());

    // Verify that the Flame GameWidget is present
    expect(find.byType(GameWidget<TerrariumGame>), findsOneWidget);

    // Verify UI elements loaded properly
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
