import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

import 'roach.dart';
import 'environment.dart';

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

  final List<Roach> roaches = [];
  final List<Hide> hides = [];
  final List<Food> foods = [];
  final List<WaterPellet> waterPellets = [];

  final Random _random = Random();

  // Methods
  @override
  Future<void> onLoad() async {
    terrariumWorld = World();
    add(terrariumWorld);

    boundaries = Rect.fromLTWH(0, 0, worldWidth, worldHeight);
    terrariumWorld.add(Substrate(worldWidth, worldHeight));

    _spawnEnvironment();
    createDefaultTerrarium();

    cam = CameraComponent(world: terrariumWorld);
    final bounds = Rectangle.fromLTWH(0, 0, worldWidth, worldHeight);
    cam.setBounds(bounds);

    cam.viewfinder.zoom = 1.0;
    cam.viewfinder.position = Vector2(worldWidth / 2, worldHeight / 2);
    add(cam);
  }

  void _spawnEnvironment() {
    final heatZone = WarmSpot(Vector2(1000, 1000), 800);
    terrariumWorld.add(heatZone);

    final mainHide = Hide(Vector2(600, 600), Vector2(400, 150));
    hides.add(mainHide);
    terrariumWorld.add(mainHide);
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

    _addPredefinedRoach(
      'Ringo',
      const Personality(
        activity: 0.8,
        appetite: 0.5,
        friendliness: 0.5,
        skittishness: 0.2,
      ),
      Vector2(1000, 900),
    );
    _addPredefinedRoach(
      'Bingo',
      const Personality(
        activity: 0.5,
        appetite: 0.8,
        friendliness: 0.5,
        skittishness: 0.5,
      ),
      Vector2(1100, 900),
    );
    _addPredefinedRoach(
      'Singo',
      const Personality(
        activity: 0.5,
        appetite: 0.5,
        friendliness: 0.8,
        skittishness: 0.2,
      ),
      Vector2(1000, 1100),
    );
    _addPredefinedRoach(
      'Lingo',
      const Personality(
        activity: 0.2,
        appetite: 0.5,
        friendliness: 0.2,
        skittishness: 0.8,
      ),
      Vector2(1100, 1100),
    );
  }

  void _addPredefinedRoach(String name, Personality p, Vector2 pos) {
    final newRoach = Roach(
      id: 'roach_${DateTime.now().millisecondsSinceEpoch}_$name',
      name: name,
      position: pos,
      personality: p,
    );
    roaches.add(newRoach);
    terrariumWorld.add(
      RoachComponent(newRoach, onSelect: (r) => selectedRoach.value = r),
    );
  }

  // Spawns a roach with a randomly generated personality
  void adoptRoach(String name) {
    final newRoach = Roach(
      id: 'roach_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      position: Vector2(worldWidth / 2, worldHeight / 2),
      personality: Personality(
        activity: 0.3 + _random.nextDouble() * 0.4,
        appetite: 0.3 + _random.nextDouble() * 0.4,
        friendliness: 0.3 + _random.nextDouble() * 0.4,
        skittishness: 0.3 + _random.nextDouble() * 0.4,
      ),
    );
    roaches.add(newRoach);
    terrariumWorld.add(
      RoachComponent(newRoach, onSelect: (r) => selectedRoach.value = r),
    );
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

  // Calculates the exact amount of hunger across the colony and dispenses that exact total
  void dispenseFood() {
    final totalHunger = roaches.fold(0.0, (sum, r) => sum + r.needs.hunger);
    for (final f in foods) {
      f.removeFromParent();
    }
    foods.clear();

    if (totalHunger > 0) {
      final newFood = Food(Vector2(1200, 800), totalHunger);
      foods.add(newFood);
      terrariumWorld.add(newFood);
    }
  }

  // Calculates the exact amount of thirst across the colony and dispenses that exact total
  void dispenseWater() {
    final totalThirst = roaches.fold(0.0, (sum, r) => sum + r.needs.thirst);
    for (final w in waterPellets) {
      w.removeFromParent();
    }
    waterPellets.clear();

    if (totalThirst > 0) {
      final newWater = WaterPellet(Vector2(1300, 800), totalThirst);
      waterPellets.add(newWater);
      terrariumWorld.add(newWater);
    }
  }

  // Simulation
  @override
  void update(double dt) {
    super.update(dt);

    final scaledDt = dt * SimConfig.timeScale;

    for (final roach in roaches) {
      roach.update(scaledDt, boundaries, foods, waterPellets);
    }

    // Sweep the environment and remove fully consumed resources
    foods.removeWhere((f) {
      if (f.amount <= 0) {
        f.removeFromParent();
        return true;
      }
      return false;
    });

    waterPellets.removeWhere((w) {
      if (w.amount <= 0) {
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

class Substrate extends PositionComponent {
  @override
  final double width;

  @override
  final double height;

  late final Paint bgPaint;
  late final Paint borderPaint;

  Substrate(this.width, this.height) {
    size = Vector2(width, height);

    bgPaint = Paint()..color = const Color(0xFF5D4037);
    borderPaint = Paint()
      ..color = const Color(0xFF27150C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect, borderPaint);
  }
}
