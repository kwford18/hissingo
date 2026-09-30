import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

import '../config/sim_config.dart';
import '../environment/climbing_branch.dart';
import '../environment/food.dart';
import '../environment/hide.dart';
import '../environment/warm_spot.dart';
import '../environment/water_pellet.dart';
import '../roach/personality.dart';
import '../roach/roach.dart';
import '../roach/roach_component.dart';
import 'lighting_overlay.dart';
import 'substrate.dart';

// Main game class for the terrarium simulation
class TerrariumGame extends FlameGame
    with PanDetector, ScaleDetector, ScrollDetector {
  // World Configuration
  final double worldWidth = 2000;
  final double worldHeight = 2000;

  late final Rect boundaries;

  // Camera Configuration
  final double minZoom = 0.5;
  final double maxZoom = 3.0;

  late double startZoom;

  // Game State
  late final World terrariumWorld;
  late final CameraComponent cam;

  final ValueNotifier<Roach?> selectedRoach = ValueNotifier(null);
  final ValueNotifier<Hide?> selectedHide = ValueNotifier(null);

  final List<Roach> roaches = [];
  final List<Hide> hides = [];
  final List<ClimbingBranch> branches = [];
  final List<Food> foods = [];
  final List<WaterPellet> waterPellets = [];

  final Random _random = Random();

  double dayCycleTimer = 0.0;
  bool get isDayTime => dayCycleTimer < (SimConfig.dayLengthSeconds / 2);

  // Methods
  @override
  Future<void> onLoad() async {
    terrariumWorld = World();
    add(terrariumWorld);

    boundaries = Rect.fromLTWH(0, 0, worldWidth, worldHeight);
    terrariumWorld.add(Substrate(width: worldWidth, height: worldHeight));

    _spawnEnvironment();
    createDefaultTerrarium();

    terrariumWorld.add(LightingOverlay(this));

    cam = CameraComponent(world: terrariumWorld);
    final bounds = Rectangle.fromLTWH(0, 0, worldWidth, worldHeight);
    cam.setBounds(bounds);

    cam.viewfinder.zoom = 1.0;
    cam.viewfinder.position = Vector2(worldWidth / 2, worldHeight / 2);
    add(cam);
  }

  // Selection callbacks shared by every tappable component in the world
  void _selectRoach(Roach roach) {
    selectedRoach.value = roach;
    selectedHide.value = null;
  }

  void _selectHide(Hide hide) {
    selectedHide.value = hide;
    selectedRoach.value = null;
  }

  void _spawnEnvironment() {
    final heatZone = WarmSpot(position: Vector2(1000, 1000), radius: 800);
    terrariumWorld.add(heatZone);

    final mainHide = Hide(
      position: Vector2(600, 600),
      size: Vector2(400, 150),
      shape: HideShape.log,
      onSelect: _selectHide,
    );
    hides.add(mainHide);
    terrariumWorld.add(mainHide);

    final stoneHide = Hide(
      position: Vector2(200, 1200),
      size: Vector2(250, 200),
      shape: HideShape.stone,
      onSelect: _selectHide,
    );
    hides.add(stoneHide);
    terrariumWorld.add(stoneHide);

    final leafHide = Hide(
      position: Vector2(1400, 400),
      size: Vector2(300, 150),
      shape: HideShape.leaf,
      onSelect: _selectHide,
    );
    hides.add(leafHide);
    terrariumWorld.add(leafHide);

    final largeBranch = ClimbingBranch(
      position: Vector2(1200, 1400),
      size: Vector2(500, 80),
    );
    branches.add(largeBranch);
    terrariumWorld.add(largeBranch);

    final smallBranch = ClimbingBranch(
      position: Vector2(300, 300),
      size: Vector2(80, 400),
    );
    branches.add(smallBranch);
    terrariumWorld.add(smallBranch);
  }

  // Replaces the terrarium occupants with the predefined default squad
  void createDefaultTerrarium() {
    roaches.clear();
    final oldRoaches = terrariumWorld.children
        .whereType<RoachComponent>()
        .toList();
    for (final c in oldRoaches) {
      c.removeFromParent();
    }
    selectedRoach.value = null;
    selectedHide.value = null;

    _addPredefinedRoach(
      name: 'Ringo',
      personality: const Personality(
        activity: 0.8,
        appetite: 0.7,
        friendliness: 1.0,
        skittishness: 0.2,
      ),
      position: Vector2(1000, 900),
      color: const Color.fromARGB(255, 85, 36, 25),
      scale: 0.7,
    );
    _addPredefinedRoach(
      name: 'Bingo',
      personality: const Personality(
        activity: 0.5,
        appetite: 0.4,
        friendliness: 0.5,
        skittishness: 0.5,
      ),
      position: Vector2(1100, 900),
      color: const Color.fromARGB(255, 141, 110, 99),
      scale: 0.5,
    );
    _addPredefinedRoach(
      name: 'Singo',
      personality: const Personality(
        activity: 0.5,
        appetite: 0.8,
        friendliness: 0.8,
        skittishness: 0.2,
      ),
      position: Vector2(1200, 1200),
      color: const Color.fromARGB(255, 82, 14, 26),
      scale: 1.05,
    );
    _addPredefinedRoach(
      name: 'Lingo',
      personality: const Personality(
        activity: 0.3,
        appetite: 0.5,
        friendliness: 0.1,
        skittishness: 0.8,
      ),
      position: Vector2(1100, 1100),
      color: const Color.fromARGB(255, 27, 10, 5),
      scale: 0.65,
    );
  }

  void _addPredefinedRoach({
    required String name,
    required Personality personality,
    required Vector2 position,
    required Color color,
    required double scale,
  }) {
    _addRoach(
      Roach(
        id: 'roach_${DateTime.now().millisecondsSinceEpoch}_$name',
        name: name,
        position: position,
        personality: personality,
        color: color,
        scale: scale,
      ),
    );
  }

  // Spawns a roach with a randomly generated personality and appearance
  void adoptRoach(String name) {
    _addRoach(
      Roach(
        id: 'roach_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        position: Vector2(worldWidth / 2, worldHeight / 2),
        personality: Personality(
          activity: 0.3 + _random.nextDouble() * 0.4,
          appetite: 0.3 + _random.nextDouble() * 0.4,
          friendliness: 0.3 + _random.nextDouble() * 0.4,
          skittishness: 0.3 + _random.nextDouble() * 0.4,
        ),
      ),
    );
  }

  // Adds a roach to the domain layer and the game world
  void _addRoach(Roach roach) {
    roaches.add(roach);
    terrariumWorld.add(RoachComponent(roach, onSelect: _selectRoach));
  }

  // Removes a roach from the domain layer and the game world
  void rehomeRoach(Roach roach) {
    roaches.remove(roach);
    final components = terrariumWorld.children
        .whereType<RoachComponent>()
        .toList();
    for (final comp in components) {
      if (comp.roach == roach) {
        comp.removeFromParent();
      }
    }
    if (selectedRoach.value == roach) {
      selectedRoach.value = null;
    }
  }

  // Renames a roach and refreshes the inspection panel to show the new name
  void renameRoach(Roach roach, String name) {
    roach.name = name;

    // Force a rebuild of the inspection panel by resetting the listener
    final current = selectedRoach.value;
    selectedRoach.value = null;
    selectedRoach.value = current;
  }

  // Coaxes a roach out of its hide and refreshes the hide inspection panel
  void coaxRoachOut(Roach roach) {
    roach.coaxOut();

    // Force UI refresh to update the occupant count
    final currentHide = selectedHide.value;
    selectedHide.value = null;
    selectedHide.value = currentHide;
  }

  // Scatters food pieces equal to the population size plus a buffer
  void dispenseFood() {
    for (final f in foods) {
      f.removeFromParent();
    }
    foods.clear();

    final spawnCount = roaches.length + 4;
    for (var i = 0; i < spawnCount; i++) {
      final newFood = Food(position: _randomSpawnPosition());

      foods.add(newFood);
      terrariumWorld.add(newFood);
    }
  }

  // Scatters water droplets equal to the population size plus a buffer
  void dispenseWater() {
    for (final w in waterPellets) {
      w.removeFromParent();
    }
    waterPellets.clear();

    final spawnCount = roaches.length + 4;
    for (var i = 0; i < spawnCount; i++) {
      final newWater = WaterPellet(position: _randomSpawnPosition());

      waterPellets.add(newWater);
      terrariumWorld.add(newWater);
    }
  }

  // Picks a random coordinate inside the world, keeping clear of the edges
  Vector2 _randomSpawnPosition() {
    final rx =
        boundaries.left + 200 + _random.nextDouble() * (boundaries.width - 400);
    final ry =
        boundaries.top + 200 + _random.nextDouble() * (boundaries.height - 400);
    return Vector2(rx, ry);
  }

  // Simulation
  @override
  void update(double dt) {
    super.update(dt);
    final scaledDt = dt * SimConfig.timeScale;

    dayCycleTimer += scaledDt;
    if (dayCycleTimer >= SimConfig.dayLengthSeconds) {
      dayCycleTimer = 0.0;
    }

    for (final roach in roaches) {
      // Create a list of all other roaches to pass to the interaction logic
      final otherRoaches = roaches.where((r) => r != roach).toList();

      roach.update(
        scaledDt,
        boundaries: boundaries,
        availableFoods: foods,
        availableWater: waterPellets,
        availableHides: hides,
        availableBranches: branches,
        otherRoaches: otherRoaches,
        isDayTime: isDayTime,
      );
    }

    // Sweep the environment and remove fully consumed resources
    foods.removeWhere((f) {
      if (f.isDepleted) {
        f.removeFromParent();
        return true;
      }
      return false;
    });

    waterPellets.removeWhere((w) {
      if (w.isDepleted) {
        w.removeFromParent();
        return true;
      }
      return false;
    });
  }

  // Camera Input Handling
  @override
  void onPanUpdate(DragUpdateInfo info) {
    cam.viewfinder.position -= info.delta.global / cam.viewfinder.zoom;
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    startZoom = cam.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final currentZoom = startZoom * info.scale.global.x;
    cam.viewfinder.zoom = currentZoom.clamp(minZoom, maxZoom);
  }

  @override
  void onScroll(PointerScrollInfo info) {
    final zoomDelta = info.scrollDelta.global.y * -0.001;
    cam.viewfinder.zoom = (cam.viewfinder.zoom + zoomDelta).clamp(
      minZoom,
      maxZoom,
    );
  }
}
