import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// Basic enrichment object that fills empty space and provides stimulation
class ClimbingBranch extends PositionComponent {
  late final Paint woodPaint;
  late final Paint shadowPaint;

  ClimbingBranch({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
    priority = 20;

    woodPaint = Paint()..color = const Color(0xFF6D4C41);
    shadowPaint = Paint()..color = const Color(0x66000000);
  }

  // Returns a random coordinate safely on the branch for climbing
  Vector2 getRandomClimbSpot(Random random) {
    final rx = 10.0 + random.nextDouble() * (size.x - 20.0);
    final ry = 10.0 + random.nextDouble() * (size.y - 20.0);
    return Vector2(position.x + rx, position.y + ry);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(10, 10),
        const Radius.circular(15),
      ),
      shadowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(15)),
      woodPaint,
    );
  }
}
