import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/game/terrarium_game.dart';
import 'package:hissingo/roach/activity.dart';
import 'package:hissingo/ui/resource_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ResourceButtons trigger game treat method', (
    WidgetTester tester,
  ) async {
    // Required to safely initialize Flame's storage call during widget pump
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

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
    // and resolve the mock SharedPreferences call
    await tester.pump();
    await tester
        .pump(); // Added an extra pump to ensure async setup concludes cleanly

    // Tap the treat button
    await tester.tap(find.text('Treat'));
    await tester.pump();

    expect(game.roaches.first.currentActivity, Activity.excitedForTreat);
  });
}
