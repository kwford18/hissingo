import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Substrate extends PositionComponent {
  @override
  final double width;

  @override
  final double height;

  late final Paint bgPaint;
  late final Paint borderPaint;

  Substrate({required this.width, required this.height}) {
    size = Vector2(width, height);
    priority = 0;

    // bgPaint = Paint()..color = const Color(0xFF5D4037);
    bgPaint = Paint()..color = const Color.fromARGB(255, 93, 64, 55);
    borderPaint = Paint()
      ..color = const Color.fromARGB(255, 39, 21, 12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect, borderPaint);
  }
}
