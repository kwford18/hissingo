import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

import 'roach.dart';

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

  final List<Roach> roaches = [];

  // Methods
  @override
  Future<void> onLoad() async {
    terrariumWorld = World();
    add(terrariumWorld);

    boundaries = Rect.fromLTWH(0, 0, worldWidth, worldHeight);
    terrariumWorld.add(Substrate(worldWidth, worldHeight));

    _spawnInitialRoaches();

    cam = CameraComponent(world: terrariumWorld);
    final bounds = Rectangle.fromLTWH(0, 0, worldWidth, worldHeight);
    cam.setBounds(bounds);

    cam.viewfinder.zoom = 1.0;
    cam.viewfinder.position = Vector2(worldWidth / 2, worldHeight / 2);
    add(cam);
  }

  void _spawnInitialRoaches() {
    final testRoach = Roach(
      id: 'roach_1',
      name: 'Barnaby',
      position: Vector2(worldWidth / 2, worldHeight / 2),
    );

    roaches.add(testRoach);
    terrariumWorld.add(RoachComponent(testRoach));
  }

  // Simulation
  @override
  void update(double dt) {
    super.update(dt);

    final scaledDt = dt * SimConfig.timeScale;
    for (final roach in roaches) {
      roach.update(scaledDt, boundaries);
    }
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
  final double width;
  final double height;
  late final Paint bgPaint;
  late final Paint borderPaint;

  Substrate(this.width, this.height) {
    size = Vector2(width, height);
    bgPaint = Paint()..color = const Color(0xFF3E2723);
    borderPaint = Paint()
      ..color = const Color(0xFF1B0000)
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
