import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/game/terrarium_save_state.dart';
import 'package:hissingo/roach/roach.dart';

void main() {
  test('TerrariumSaveState serializes and deserializes correctly', () {
    final roach = Roach(
      id: 'test_id',
      name: 'Test Roach',
      position: Vector2(100, 200),
      color: const Color.fromARGB(255, 141, 110, 99),
      scale: 0.95,
    );
    roach.needs.hunger = 45.0;

    final state = TerrariumSaveState(
      roaches: [roach],
      collectedGifts: 5,
      lastSavedTimestamp: 1600000000,
    );

    final json = state.toJson();
    final loadedState = TerrariumSaveState.fromJson(json);

    expect(loadedState.collectedGifts, 5);
    expect(loadedState.lastSavedTimestamp, 1600000000);
    expect(loadedState.roaches.length, 1);

    final loadedRoach = loadedState.roaches.first;
    expect(loadedRoach.id, 'test_id');
    expect(loadedRoach.name, 'Test Roach');
    expect(loadedRoach.position.x, 100.0);
    expect(loadedRoach.bodyColor.toARGB32(), 0xFF8D6E63);
    expect(loadedRoach.scaleModifier, 0.95);
    expect(loadedRoach.needs.hunger, 45.0);
  });
}
