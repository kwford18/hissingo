import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// A central feeding dish that provides an infinite source of food
class FoodDish extends PositionComponent {
  late final Paint dishPaint;
  late final Paint foodPaint;

  FoodDish({required Vector2 position}) {
    this.position = position;
    size = Vector2(60, 60);
    anchor = Anchor.center;
    priority = 15;

    dishPaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.fill;

    foodPaint = Paint()..color = const Color(0xFF8BC34A);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawOval(rect, dishPaint);
    canvas.drawOval(rect.deflate(8), foodPaint);
  }
}
