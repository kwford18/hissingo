import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'roach.dart';

// Flame component representing a roach in the game world
class RoachComponent extends PositionComponent with TapCallbacks {
  final Roach roach;
  final void Function(Roach) onSelect;

  late final Paint bodyPaint;
  late final Paint outlinePaint;
  late final Paint legPaint;
  late final TextPaint emotionPaint;

  double _animationTime = 0;

  RoachComponent(this.roach, {required this.onSelect}) {
    size = Vector2(40, 70);
    anchor = Anchor.center;
    scale = Vector2(roach.scaleModifier, roach.scaleModifier);

    position = roach.position;
    angle = roach.orientation;

    bodyPaint = Paint()..color = roach.bodyColor;
    outlinePaint = Paint()
      ..color = const Color.fromARGB(255, 62, 39, 35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Thinner stroke width to make the legs less visually dominant
    legPaint = Paint()
      ..color = const Color.fromARGB(255, 62, 39, 35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    emotionPaint = TextPaint(
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            blurRadius: 4.0,
            color: Colors.black87,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onSelect(roach);
  }

  @override
  void render(Canvas canvas) {
    final swing = roach.currentActivity.isMoving
        ? sin(_animationTime * 15) * 4
        : sin(_animationTime * 2) * 1;
    final antennaWiggle = sin(_animationTime * 8) * 3;

    // Draws the legs
    // Each leg should barely peek out of the carrapace
    // with a slight swing to simulate movement
    _drawLeg(
      canvas,
      start: const Offset(12, 30),
      end: const Offset(2, 28),
      swing: swing,
    );
    _drawLeg(
      canvas,
      start: const Offset(12, 45),
      end: const Offset(1, 45),
      swing: -swing,
    );
    _drawLeg(
      canvas,
      start: const Offset(12, 60),
      end: const Offset(2, 62),
      swing: swing,
    );

    _drawLeg(
      canvas,
      start: const Offset(28, 30),
      end: const Offset(38, 28),
      swing: -swing,
    );
    _drawLeg(
      canvas,
      start: const Offset(28, 45),
      end: const Offset(39, 45),
      swing: swing,
    );
    _drawLeg(
      canvas,
      start: const Offset(28, 60),
      end: const Offset(38, 62),
      swing: -swing,
    );

    final bodyRect = const Rect.fromLTWH(5, 20, 30, 50);
    canvas.drawOval(bodyRect, bodyPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    canvas.drawLine(
      const Offset(15, 20),
      Offset(5 + antennaWiggle, 5),
      outlinePaint,
    );
    canvas.drawLine(
      const Offset(25, 20),
      Offset(35 + antennaWiggle, 5),
      outlinePaint,
    );

    // Render the emotion indicator above the roach if active
    final currentEmotionText = roach.currentEmotion;
    if (roach.emotionTimer > 0 && currentEmotionText != null) {
      // Rotates the canvas in reverse to ensure the text stays perfectly upright
      // regardless of the direction the roach is facing
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(-angle);
      emotionPaint.render(canvas, currentEmotionText, Vector2(-15, -60));
      canvas.restore();
    }
  }

  void _drawLeg(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required double swing,
  }) {
    final modifiedEnd = Offset(end.dx, end.dy + swing);
    canvas.drawLine(start, modifiedEnd, legPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = roach.position;
    angle = roach.orientation;
    _animationTime += dt;

    // Updates priority so roaches visually disappear underneath hides when sheltering
    priority = roach.isHidden ? 10 : 100;
  }
}
