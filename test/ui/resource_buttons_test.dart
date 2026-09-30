import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/game/terrarium_game.dart';
import 'package:hissingo/ui/resource_buttons.dart';

void main() {
  testWidgets('ResourceButtons trigger game dispense methods', (
    WidgetTester tester,
  ) async {
    final game = TerrariumGame();

    // Mount the game so terrariumWorld is initialized
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GameWidget(game: game),
              ResourceButtons(game: game),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final initialFoodCount = game.foods.length;
    final initialWaterCount = game.waterPellets.length;

    // Tap the food button
    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(game.foods.length, greaterThan(initialFoodCount));

    // Tap the water button
    await tester.tap(find.text('Water'));
    await tester.pump();
    expect(game.waterPellets.length, greaterThan(initialWaterCount));
  });
}
