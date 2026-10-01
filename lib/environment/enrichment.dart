import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// Base class for all terrarium enrichment items
abstract class EnrichmentObject extends PositionComponent {
  Vector2 getInteractionSpot(Random random);
}

// A natural branch with leaves for climbing
class ClimbingBranch extends EnrichmentObject {
  late final Paint woodPaint;
  late final Paint shadowPaint;
  late final Paint leafPaint;

  ClimbingBranch({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
    priority = 20;

    woodPaint = Paint()..color = const Color.fromARGB(255, 109, 76, 65);
    shadowPaint = Paint()..color = const Color.fromARGB(102, 0, 0, 0);
    leafPaint = Paint()..color = const Color.fromARGB(255, 51, 105, 30);
  }

  @override
  Vector2 getInteractionSpot(Random random) {
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

    canvas.drawOval(Rect.fromLTWH(-10, size.y * 0.2, 40, 60), leafPaint);
    canvas.drawOval(
      Rect.fromLTWH(size.x - 30, size.y * 0.6, 40, 60),
      leafPaint,
    );
  }
}

// A colorful slot machine for roach gambling
class SlotMachine extends EnrichmentObject {
  late final Paint bodyPaint;
  late final Paint screenPaint;
  late final Paint handlePaint;

  SlotMachine({required Vector2 position}) {
    this.position = position;
    size = Vector2(100, 120);
    priority = 20;

    bodyPaint = Paint()..color = const Color.fromARGB(255, 211, 47, 47);
    screenPaint = Paint()..color = const Color.fromARGB(255, 224, 224, 224);
    handlePaint = Paint()
      ..color = const Color.fromARGB(255, 66, 66, 66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
  }

  @override
  Vector2 getInteractionSpot(Random random) {
    return Vector2(position.x + size.x / 2, position.y + size.y);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRect(rect, bodyPaint);
    canvas.drawRect(Rect.fromLTWH(10, 20, 80, 50), screenPaint);

    final slotPaint = Paint()..color = const Color.fromARGB(255, 158, 158, 158);
    canvas.drawRect(Rect.fromLTWH(20, 30, 15, 30), slotPaint);
    canvas.drawRect(Rect.fromLTWH(42, 30, 15, 30), slotPaint);
    canvas.drawRect(Rect.fromLTWH(64, 30, 15, 30), slotPaint);

    canvas.drawLine(
      Offset(size.x, size.y / 2),
      Offset(size.x + 20, size.y / 4),
      handlePaint,
    );
    canvas.drawCircle(
      Offset(size.x + 20, size.y / 4),
      10,
      Paint()..color = const Color.fromARGB(255, 183, 28, 28),
    );
  }
}

// A tiny barbell for roach fitness
class WorkoutArea extends EnrichmentObject {
  late final Paint barPaint;
  late final Paint weightPaint;

  WorkoutArea({required Vector2 position}) {
    this.position = position;
    size = Vector2(120, 60);
    priority = 20;

    barPaint = Paint()
      ..color = const Color.fromARGB(255, 158, 158, 158)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    weightPaint = Paint()..color = const Color.fromARGB(255, 33, 33, 33);
  }

  @override
  Vector2 getInteractionSpot(Random random) {
    return Vector2(position.x + size.x / 2, position.y + size.y / 2);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      Offset(20, size.y / 2),
      Offset(size.x - 20, size.y / 2),
      barPaint,
    );
    canvas.drawRect(Rect.fromLTWH(10, 10, 20, 40), weightPaint);
    canvas.drawRect(Rect.fromLTWH(size.x - 30, 10, 20, 40), weightPaint);
  }
}

// An open book for intellectual roaches
class Book extends EnrichmentObject {
  late final Paint coverPaint;
  late final Paint pagePaint;
  late final Paint textPaint;

  Book({required Vector2 position}) {
    this.position = position;
    size = Vector2(100, 70);
    priority = 15;

    coverPaint = Paint()..color = const Color.fromARGB(255, 93, 64, 55);
    pagePaint = Paint()..color = const Color.fromARGB(255, 255, 245, 157);
    textPaint = Paint()
      ..color = const Color.fromARGB(255, 188, 170, 164)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  }

  @override
  Vector2 getInteractionSpot(Random random) {
    return Vector2(position.x + size.x / 2, position.y + size.y / 2);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), coverPaint);

    canvas.drawRect(Rect.fromLTWH(5, 5, 43, 60), pagePaint);
    canvas.drawRect(Rect.fromLTWH(52, 5, 43, 60), pagePaint);

    for (int i = 0; i < 5; i++) {
      final y = 15.0 + (i * 10);
      canvas.drawLine(Offset(10, y), Offset(40, y), textPaint);
      canvas.drawLine(Offset(60, y), Offset(90, y), textPaint);
    }
  }
}

// A spooky skull for roaches to explore
class PirateSkull extends EnrichmentObject {
  late final Paint bonePaint;
  late final Paint hollowPaint;

  PirateSkull({required Vector2 position}) {
    this.position = position;
    size = Vector2(60, 60);
    priority = 18;

    bonePaint = Paint()..color = const Color.fromARGB(255, 245, 245, 245);
    hollowPaint = Paint()..color = const Color.fromARGB(255, 33, 33, 33);
  }

  @override
  Vector2 getInteractionSpot(Random random) {
    return Vector2(position.x + size.x / 2, position.y + size.y / 2);
  }

  @override
  void render(Canvas canvas) {
    // Skull dome
    canvas.drawCircle(Offset(size.x / 2, size.y / 2 - 5), 20, bonePaint);
    // Jaw
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 10, size.y / 2 + 5, 20, 15),
      bonePaint,
    );
    // Eye sockets
    canvas.drawCircle(Offset(size.x / 2 - 8, size.y / 2 - 5), 6, hollowPaint);
    canvas.drawCircle(Offset(size.x / 2 + 8, size.y / 2 - 5), 6, hollowPaint);
    // Nose cavity
    canvas.drawCircle(Offset(size.x / 2, size.y / 2 + 5), 3, hollowPaint);
  }
}
