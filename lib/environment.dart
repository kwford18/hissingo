import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// Represents a dark area where roaches feel secure
class Hide extends PositionComponent {
  late final Paint basePaint;
  late final Paint shadowPaint;
  late final Paint linePaint;

  Hide(Vector2 pos, Vector2 hideSize) {
    position = pos;
    size = hideSize;

    basePaint = Paint()..color = const Color(0xFF4E342E);
    shadowPaint = Paint()..color = const Color(0xAA000000);
    linePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(15, 15),
        const Radius.circular(20),
      ),
      shadowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      basePaint,
    );

    canvas.drawLine(const Offset(20, 20), Offset(size.x - 20, 30), linePaint);
    canvas.drawLine(const Offset(10, 50), Offset(size.x - 10, 60), linePaint);
    canvas.drawLine(const Offset(40, 80), Offset(size.x - 30, 90), linePaint);
  }
}

// Represents a warm spot in the terrarium using a radial gradient
class WarmSpot extends PositionComponent {
  late final Paint heatPaint;

  WarmSpot(Vector2 pos, double radius) {
    position = pos;
    size = Vector2(radius * 2, radius * 2);
    anchor = Anchor.center;

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
