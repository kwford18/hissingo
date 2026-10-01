import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// A central water dish that provides an infinite source of hydration
class WaterDish extends PositionComponent {
  late final Paint dishPaint;
  late final Paint waterPaint;

  WaterDish({required Vector2 position}) {
    this.position = position;
    size = Vector2(50, 50);
    anchor = Anchor.center;
    priority = 15;

    dishPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..style = PaintingStyle.fill;

    waterPaint = Paint()..color = const Color(0xFF4FC3F7);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawOval(rect, dishPaint);
    canvas.drawOval(rect.deflate(6), waterPaint);
  }
}
