import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// Represents a warm spot in the terrarium using a radial gradient
class WarmSpot extends PositionComponent {
  late final Paint heatPaint;

  WarmSpot({required Vector2 position, required double radius}) {
    this.position = position;
    size = Vector2(radius * 2, radius * 2);
    anchor = Anchor.center;
    priority = 10;

    final gradient = RadialGradient(
      colors: [const Color(0x11FF5722), const Color(0x00FF5722)],
    );

    heatPaint = Paint()..shader = gradient.createShader(size.toRect());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), heatPaint);
  }
}
