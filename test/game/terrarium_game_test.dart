import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/game/terrarium_game.dart';

void main() {
  testWidgets('TerrariumGame initializes with default roaches', (
    WidgetTester tester,
  ) async {
    final game = TerrariumGame();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump();

    // The game loads 4 default roaches during initialization
    expect(game.roaches.length, 4);
  });

  testWidgets('TerrariumGame can adopt and rehome roaches', (
    WidgetTester tester,
  ) async {
    final game = TerrariumGame();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump();

    final initialCount = game.roaches.length;

    game.adoptRoach('Barnaby');
    expect(game.roaches.length, initialCount + 1);
    expect(game.roaches.last.name, 'Barnaby');

    final roach = game.roaches.last;
    game.rehomeRoach(roach);

    expect(game.roaches.length, initialCount);
    expect(game.selectedRoach.value, isNull);
  });

  testWidgets(
    'TerrariumGame dispenses correct amount of food based on population size',
    (WidgetTester tester) async {
      final game = TerrariumGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();

      game.dispenseFood();

      // The total spawn count is defined as population size + 4
      expect(game.foods.length, game.roaches.length + 4);

      // Dispensing again clears the old food before spawning new ones
      game.dispenseFood();
      expect(game.foods.length, game.roaches.length + 4);
    },
  );

  testWidgets(
    'TerrariumGame dispenses correct amount of water based on population size',
    (WidgetTester tester) async {
      final game = TerrariumGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();

      game.dispenseWater();

      expect(game.waterPellets.length, game.roaches.length + 4);
    },
  );

  testWidgets('Renaming a roach updates its name and triggers UI refresh', (
    WidgetTester tester,
  ) async {
    final game = TerrariumGame();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump();

    final roach = game.roaches.first;
    game.selectedRoach.value = roach;

    game.renameRoach(roach, 'New Name');

    expect(roach.name, 'New Name');
    expect(game.selectedRoach.value, roach);
  });
}
