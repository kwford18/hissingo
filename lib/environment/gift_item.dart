import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

// A collectible gift dropped by happy roaches
class GiftItem extends PositionComponent with TapCallbacks {
  final void Function(GiftItem) onCollect;
  late final Paint boxPaint;
  late final Paint ribbonPaint;

  GiftItem({required Vector2 position, required this.onCollect}) {
    this.position = position;
    size = Vector2(24, 24);
    anchor = Anchor.center;
    priority = 30;

    boxPaint = Paint()..color = const Color(0xFFFBC02D);
    ribbonPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
  }

  @override
  void onTapDown(TapDownEvent event) {
    onCollect(this);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    // Draw the main box
    canvas.drawRect(rect, boxPaint);

    // Draw cross ribbons
    canvas.drawLine(
      Offset(size.x / 2, 0),
      Offset(size.x / 2, size.y),
      ribbonPaint,
    );
    canvas.drawLine(
      Offset(0, size.y / 2),
      Offset(size.x, size.y / 2),
      ribbonPaint,
    );
  }
}
