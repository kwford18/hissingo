import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:hissingo/game/terrarium_game.dart';
import 'package:hissingo/game/terrarium_save_state.dart';
import 'package:hissingo/roach/roach.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Offline progression calculates correctly for 1 hour away', () async {
    // Required to safely interact with SharedPreferences during the game load
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final game = TerrariumGame();
    // Explicitly await the load phase so terrariumWorld mounts
    await game.onLoad();

    // Setup a mock save state from exactly 1 hour ago
    final oneHourAgo = DateTime.now()
        .subtract(const Duration(hours: 1))
        .millisecondsSinceEpoch;

    final roach = Roach(id: 'test_1', name: 'Sleepy', position: Vector2.zero());
    roach.needs.fatigue = 50.0; // Should reset to 0
    roach.needs.hunger = 0.0; // Should significantly increase

    final state = TerrariumSaveState(
      roaches: [roach],
      collectedGifts: 0,
      lastSavedTimestamp: oneHourAgo,
    );

    game.restoreState(state);

    final summary = game.offlineSummary.value;
    expect(summary, isNotNull);
    expect(summary!.timeAway.inHours, 1);

    final updatedRoach = game.roaches.first;
    // Fatigue drops completely while away
    expect(updatedRoach.needs.fatigue, 0.0);
    // Hunger accumulates over the hour
    expect(updatedRoach.needs.hunger, greaterThan(0.0));
  });
}
