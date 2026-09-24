import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// Configuration for the simulation, including time scale and activity multiplier
class SimConfig {
  static double timeScale = 1.0;
  static double activityMultiplier = 5.0;
}

enum Activity { idle, wandering }

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

  void update(double dt, Rect boundaries) {
    stateTimer -= dt;

    if (stateTimer <= 0) {
      _decideNextActivity(boundaries);
    }

    if (currentActivity == Activity.wandering && targetPosition != null) {
      _moveTowardsTarget(dt);
    }
  }

  // Decide the next activity based on personality and random factors
  void _decideNextActivity(Rect boundaries) {
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

  // Move the roach towards its target position
  void _moveTowardsTarget(double dt) {
    final direction = targetPosition! - position;
    final distance = direction.length;

    if (distance < 5.0) {
      currentActivity = Activity.idle;
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
  }

  @override
  void render(Canvas canvas) {
    final bodyRect = const Rect.fromLTWH(5, 20, 30, 50);
    canvas.drawOval(bodyRect, bodyPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    canvas.drawLine(const Offset(15, 20), const Offset(5, 5), outlinePaint);
    canvas.drawLine(const Offset(25, 20), const Offset(35, 5), outlinePaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = roach.position;
    angle = roach.orientation;
  }
}
