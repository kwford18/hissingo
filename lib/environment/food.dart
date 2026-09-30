import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// A piece of food that completely refills hunger when consumed
class Food extends PositionComponent {
  bool isDepleted = false;
  late final Paint foodPaint;

  Food({required Vector2 position}) {
    this.position = position;
    size = Vector2(15, 15);
    anchor = Anchor.center;
    priority = 25;

    foodPaint = Paint()..color = const Color(0xFF689F38);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), foodPaint);
  }
}
