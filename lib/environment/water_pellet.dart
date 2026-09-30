import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// A drop of water that completely refills thirst when consumed
class WaterPellet extends PositionComponent {
  bool isDepleted = false;
  late final Paint waterPaint;

  WaterPellet({required Vector2 position}) {
    this.position = position;
    size = Vector2(12, 12);
    anchor = Anchor.center;
    priority = 25;

    waterPaint = Paint()..color = const Color(0xFF4FC3F7);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), waterPaint);
  }
}
