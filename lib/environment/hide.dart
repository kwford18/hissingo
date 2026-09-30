import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

enum HideShape { log, stone, leaf }

// Represents a dark area where roaches feel secure
class Hide extends PositionComponent with TapCallbacks {
  final void Function(Hide) onSelect;
  final HideShape shape;

  late final Paint basePaint;
  late final Paint shadowPaint;
  late final Paint linePaint;

  Hide({
    required Vector2 position,
    required Vector2 size,
    required this.shape,
    required this.onSelect,
  }) {
    this.position = position;
    this.size = size;
    priority = 50;

    shadowPaint = Paint()..color = const Color(0xAA000000);
    linePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    if (shape == HideShape.stone) {
      basePaint = Paint()..color = const Color(0xFF546E7A);
    } else if (shape == HideShape.leaf) {
      basePaint = Paint()..color = const Color(0xFF558B2F);
    } else {
      basePaint = Paint()..color = const Color(0xFF4E342E);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onSelect(this);
  }

  // Returns the bottom center edge coordinate to act as the mandatory entrance
  Vector2 getEntrance() {
    return Vector2(position.x + size.x / 2, position.y + size.y);
  }

  // Returns a random coordinate safely inside the bounds of the hide
  Vector2 getRandomInterior(Random random) {
    const padding = 30.0;
    final rx = padding + random.nextDouble() * (size.x - padding * 2);
    final ry = padding + random.nextDouble() * (size.y - padding * 2);
    return Vector2(position.x + rx, position.y + ry);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    if (shape == HideShape.stone) {
      canvas.drawOval(rect.translate(15, 15), shadowPaint);
      canvas.drawOval(rect, basePaint);
    } else if (shape == HideShape.leaf) {
      final path = Path();
      path.moveTo(0, size.y / 2);
      path.quadraticBezierTo(size.x / 2, -20, size.x, size.y / 2);
      path.quadraticBezierTo(size.x / 2, size.y + 20, 0, size.y / 2);

      final shadowPath = Path();
      shadowPath.moveTo(15, size.y / 2 + 15);
      shadowPath.quadraticBezierTo(
        size.x / 2 + 15,
        -5,
        size.x + 15,
        size.y / 2 + 15,
      );
      shadowPath.quadraticBezierTo(
        size.x / 2 + 15,
        size.y + 35,
        15,
        size.y / 2 + 15,
      );

      canvas.drawPath(shadowPath, shadowPaint);
      canvas.drawPath(path, basePaint);

      // Draw a central vein for the leaf
      canvas.drawLine(
        Offset(0, size.y / 2),
        Offset(size.x, size.y / 2),
        linePaint,
      );
    } else {
      // Default log shape
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
}
