import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/environment/gift_item.dart';
import 'package:hissingo/game/terrarium_game.dart';
import 'package:hissingo/roach/activity.dart';

void main() {
  test('TerrariumGame initializes with default roaches', () async {
    final game = TerrariumGame();
    // Awaiting onLoad directly ensures the test environment safely mounts components
    // without triggering Flutter widget lifecycle timing errors
    await game.onLoad();

    expect(game.roaches.length, 4);
  });

  test('TerrariumGame can adopt and rehome roaches', () async {
    final game = TerrariumGame();
    await game.onLoad();

    final initialCount = game.roaches.length;

    game.adoptRoach('Barnaby');
    expect(game.roaches.length, initialCount + 1);
    expect(game.roaches.last.name, 'Barnaby');

    final roach = game.roaches.last;
    game.rehomeRoach(roach);

    expect(game.roaches.length, initialCount);
    expect(game.selectedRoach.value, isNull);
  });

  test('Renaming a roach updates its name and triggers UI refresh', () async {
    final game = TerrariumGame();
    await game.onLoad();

    final roach = game.roaches.first;
    game.selectedRoach.value = roach;

    game.renameRoach(roach, 'New Name');

    expect(roach.name, 'New Name');
    expect(game.selectedRoach.value, roach);
  });

  test('TerrariumGame dispenseTreat forces colony activity update', () async {
    final game = TerrariumGame();
    await game.onLoad();

    game.dispenseTreat();

    expect(game.roaches.first.currentActivity, Activity.excitedForTreat);
  });

  test('Collecting a gift increments the collectedGifts counter', () async {
    final game = TerrariumGame();
    await game.onLoad();

    final initialGifts = game.collectedGifts.value;

    game.spawnGift(position: Vector2.zero());

    final gift = game.terrariumWorld.children.whereType<GiftItem>().first;
    gift.onCollect(gift);

    expect(game.collectedGifts.value, initialGifts + 1);
  });
}
