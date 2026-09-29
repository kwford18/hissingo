import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// Represents a dark area where roaches feel secure
class Hide extends PositionComponent {
  late final Paint areaPaint;

  Hide(Vector2 pos, Vector2 hideSize) {
    position = pos;
    size = hideSize;

    // Semi-transparent black to simulate a shadow or cover
    areaPaint = Paint()..color = const Color(0x88000000);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      areaPaint,
    );
  }
}

// A piece of food for the roaches
class Food extends PositionComponent {
  late final Paint foodPaint;

  Food(Vector2 pos) {
    position = pos;
    size = Vector2(15, 15);
    anchor = Anchor.center;

    foodPaint = Paint()..color = const Color(0xFF689F38);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), foodPaint);
  }
}

// A source of hydration
class WaterPellet extends PositionComponent {
  late final Paint waterPaint;

  WaterPellet(Vector2 pos) {
    position = pos;
    size = Vector2(12, 12);
    anchor = Anchor.center;

    waterPaint = Paint()..color = const Color(0xFF4FC3F7);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), waterPaint);
  }
}
