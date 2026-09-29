import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// Configuration for the simulation, including time scale and activity multiplier
class SimConfig {
  static double timeScale = 1.0;
  static double activityMultiplier = 5.0;
}

enum Activity { idle, wandering, seekingFood, eating, seekingWater, drinking }

// Personality traits for a roach. Affects behavior
class Personality {
  final double activity;
  final double appetite;
  final double friendliness;
  final double skittishness;

  const Personality({
    this.activity = 0.5,
    this.appetite = 0.5,
    this.friendliness = 0.5,
    this.skittishness = 0.5,
  });
}

// Needs of a roach. Affects happiness. Higher values are worse
class Needs {
  double hunger = 0;
  double thirst = 0;
  double fatigue = 0;

  double get averageNeed => (hunger + thirst + fatigue) / 3;
}

// Main roach class containing position, orientation, activity, and state
class Roach {
  final String id;
  String name;
  final Personality personality;
  final Needs needs = Needs();

  Vector2 position;
  double orientation;

  Activity currentActivity = Activity.idle;
  Vector2? targetPosition;
  double stateTimer = 0;

  final double speed = 30.0;
  final Random _random = Random();

  Roach({
    required this.id,
    required this.name,
    required this.position,
    this.orientation = 0,
    this.personality = const Personality(),
  });

  double get happiness => 100.0 - needs.averageNeed;

  void update(
    double dt,
    Rect boundaries,
    List<Vector2> foodPositions,
    List<Vector2> waterPositions,
  ) {
    // Passively increase needs over time
    needs.hunger += dt * 0.5 * personality.appetite;
    needs.thirst += dt * 0.7 * personality.appetite;

    // Clamp needs to a maximum of 100
    if (needs.hunger > 100) needs.hunger = 100;
    if (needs.thirst > 100) needs.thirst = 100;

    _handleActiveStates(dt);

    stateTimer -= dt;
    if (stateTimer <= 0) {
      _decideNextActivity(boundaries, foodPositions, waterPositions);
    }

    final currentTarget = targetPosition;
    final isMoving =
        currentActivity == Activity.wandering ||
        currentActivity == Activity.seekingFood ||
        currentActivity == Activity.seekingWater;

    if (isMoving && currentTarget is Vector2) {
      _moveTowardsTarget(dt);
    }
  }

  // Handle logic for stationary activities like eating and drinking
  void _handleActiveStates(double dt) {
    if (currentActivity == Activity.eating) {
      needs.hunger -= dt * 15.0;
      if (needs.hunger < 0) needs.hunger = 0;
    } else if (currentActivity == Activity.drinking) {
      needs.thirst -= dt * 15.0;
      if (needs.thirst < 0) needs.thirst = 0;
    }
  }

  // Decide the next activity based on personality and random factors
  void _decideNextActivity(
    Rect boundaries,
    List<Vector2> foodPositions,
    List<Vector2> waterPositions,
  ) {
    // Urgent needs override random wandering
    if (needs.thirst > 40 && waterPositions.isNotEmpty) {
      currentActivity = Activity.seekingWater;
      targetPosition = _findNearest(waterPositions);
      stateTimer = 30.0;
      return;
    }

    if (needs.hunger > 40 && foodPositions.isNotEmpty) {
      currentActivity = Activity.seekingFood;
      targetPosition = _findNearest(foodPositions);
      stateTimer = 30.0;
      return;
    }

    final roll = _random.nextDouble();
    final wanderThreshold =
        0.3 * personality.activity * SimConfig.activityMultiplier;

    if (roll < wanderThreshold) {
      currentActivity = Activity.wandering;
      stateTimer = 5.0 + _random.nextDouble() * 5.0;

      final targetX = boundaries.left + _random.nextDouble() * boundaries.width;
      final targetY = boundaries.top + _random.nextDouble() * boundaries.height;
      targetPosition = Vector2(targetX, targetY);
    } else {
      currentActivity = Activity.idle;
      stateTimer = 2.0 + _random.nextDouble() * 4.0;
      targetPosition = null;
    }
  }

  Vector2 _findNearest(List<Vector2> locations) {
    Vector2 nearest = locations.first;
    double minDistance = (nearest - position).length;

    for (final loc in locations) {
      final dist = (loc - position).length;
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }
    return nearest;
  }

  // Move the roach towards its target position
  void _moveTowardsTarget(double dt) {
    final target = targetPosition;
    if (target == null) return;

    final direction = target - position;
    final distance = direction.length;

    if (distance < 5.0) {
      if (currentActivity == Activity.seekingFood) {
        currentActivity = Activity.eating;
        stateTimer = 5.0;
      } else if (currentActivity == Activity.seekingWater) {
        currentActivity = Activity.drinking;
        stateTimer = 5.0;
      } else {
        currentActivity = Activity.idle;
      }

      targetPosition = null;
      return;
    }

    direction.normalize();
    position += direction * speed * dt;

    final targetAngle = atan2(direction.y, direction.x) + (pi / 2);
    final angleDiff = (targetAngle - orientation + pi) % (2 * pi) - pi;

    orientation += angleDiff * 5.0 * dt;
  }
}

// Flame component representing a roach in the game world
class RoachComponent extends PositionComponent {
  final Roach roach;
  late final Paint bodyPaint;
  late final Paint outlinePaint;
  late final Paint legPaint;

  double _animationTime = 0;

  RoachComponent(this.roach) {
    size = Vector2(40, 70);
    anchor = Anchor.center;

    position = roach.position;
    angle = roach.orientation;

    bodyPaint = Paint()..color = const Color(0xFF8D6E63);
    outlinePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    legPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
  }

  @override
  void render(Canvas canvas) {
    final isMoving =
        roach.currentActivity == Activity.wandering ||
        roach.currentActivity == Activity.seekingFood ||
        roach.currentActivity == Activity.seekingWater;

    // Calculate leg swing based on movement or a slow twitch when idle
    final swing = isMoving
        ? sin(_animationTime * 15) * 5
        : sin(_animationTime * 2) * 1;

    // Draw 3 legs on each side before drawing the body so they render underneath
    _drawLeg(canvas, const Offset(10, 30), const Offset(-5, 25), swing);
    _drawLeg(canvas, const Offset(10, 45), const Offset(-5, 45), -swing);
    _drawLeg(canvas, const Offset(10, 60), const Offset(-5, 65), swing);

    _drawLeg(canvas, const Offset(30, 30), const Offset(45, 25), -swing);
    _drawLeg(canvas, const Offset(30, 45), const Offset(45, 45), swing);
    _drawLeg(canvas, const Offset(30, 60), const Offset(45, 65), -swing);

    final bodyRect = const Rect.fromLTWH(5, 20, 30, 50);
    canvas.drawOval(bodyRect, bodyPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    // Antennae twitch slightly along with the legs
    canvas.drawLine(const Offset(15, 20), Offset(5 + swing, 5), outlinePaint);
    canvas.drawLine(const Offset(25, 20), Offset(35 + swing, 5), outlinePaint);
  }

  void _drawLeg(Canvas canvas, Offset start, Offset end, double swing) {
    final modifiedEnd = Offset(end.dx, end.dy + swing);
    canvas.drawLine(start, modifiedEnd, legPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = roach.position;
    angle = roach.orientation;
    _animationTime += dt;
  }
}
