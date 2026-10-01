import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/game/terrarium_game.dart';
import 'package:hissingo/roach/activity.dart';
import 'package:hissingo/ui/resource_buttons.dart';

void main() {
  testWidgets('ResourceButtons trigger game treat method', (
    WidgetTester tester,
  ) async {
    final game = TerrariumGame();

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

    // Advance the test framework to allow Flame to run its internal load cycle
    await tester.pump();

    // Tap the treat button
    await tester.tap(find.text('Treat'));
    await tester.pump();

    expect(game.roaches.first.currentActivity, Activity.excitedForTreat);
  });
}
