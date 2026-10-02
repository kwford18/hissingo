import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// Represents a warm spot in the terrarium using an optimized low-opacity fill
class WarmSpot extends PositionComponent {
  late final Paint heatPaint;

  WarmSpot({required Vector2 position, required double radius}) {
    this.position = position;
    size = Vector2(radius * 2, radius * 2);
    anchor = Anchor.center;
    priority = 10;

    heatPaint = Paint()
      ..color = const Color.fromARGB(14, 255, 87, 34)
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, heatPaint);
  }
}
