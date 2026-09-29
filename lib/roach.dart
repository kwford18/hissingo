import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'environment.dart';

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

  // Can store a Vector2 coordinate or a specific environmental object
  Object? currentTarget;
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
    List<Food> availableFoods,
    List<WaterPellet> availableWater,
  ) {
    // Passively increase needs over time
    needs.hunger += dt * 0.5 * personality.appetite;
    needs.thirst += dt * 0.7 * personality.appetite;
    needs.fatigue += dt * 0.2;

    if (needs.hunger > 100) needs.hunger = 100;
    if (needs.thirst > 100) needs.thirst = 100;
    if (needs.fatigue > 100) needs.fatigue = 100;

    _handleActiveStates(dt);

    stateTimer -= dt;
    if (stateTimer <= 0) {
      _decideNextActivity(boundaries, availableFoods, availableWater);
    }

    final target = currentTarget;
    final isMoving =
        currentActivity == Activity.wandering ||
        currentActivity == Activity.seekingFood ||
        currentActivity == Activity.seekingWater;

    // Verify the object is present in memory to safely permit movement
    if (isMoving && target is Object) {
      _moveTowardsTarget(dt);
    }
  }

  void _handleActiveStates(double dt) {
    final target = currentTarget;

    if (currentActivity == Activity.eating) {
      if (target is Food) {
        final consumeRate = dt * 15.0;
        target.amount -= consumeRate;
        needs.hunger -= consumeRate;

        if (needs.hunger < 0) needs.hunger = 0;
        if (target.amount <= 0) {
          currentActivity = Activity.idle;
          currentTarget = null;
        }
      } else {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
    } else if (currentActivity == Activity.drinking) {
      if (target is WaterPellet) {
        final consumeRate = dt * 15.0;
        target.amount -= consumeRate;
        needs.thirst -= consumeRate;

        if (needs.thirst < 0) needs.thirst = 0;
        if (target.amount <= 0) {
          currentActivity = Activity.idle;
          currentTarget = null;
        }
      } else {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
    } else if (currentActivity == Activity.idle) {
      needs.fatigue -= dt * 2.0;
      if (needs.fatigue < 0) needs.fatigue = 0;
    }
  }

  // Decide the next activity based on personality and random factors
  void _decideNextActivity(
    Rect boundaries,
    List<Food> availableFoods,
    List<WaterPellet> availableWater,
  ) {
    if (needs.thirst > 40 && availableWater.isNotEmpty) {
      currentActivity = Activity.seekingWater;
      currentTarget = _findNearestWater(availableWater);
      stateTimer = 30.0;
      return;
    }

    if (needs.hunger > 40 && availableFoods.isNotEmpty) {
      currentActivity = Activity.seekingFood;
      currentTarget = _findNearestFood(availableFoods);
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
      currentTarget = Vector2(targetX, targetY);
    } else {
      currentActivity = Activity.idle;
      stateTimer = 2.0 + _random.nextDouble() * 4.0;
      currentTarget = null;
    }
  }

  Food _findNearestFood(List<Food> locations) {
    Food nearest = locations.first;
    double minDistance = (nearest.position - position).length;

    for (final loc in locations) {
      final dist = (loc.position - position).length;
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }
    return nearest;
  }

  WaterPellet _findNearestWater(List<WaterPellet> locations) {
    WaterPellet nearest = locations.first;
    double minDistance = (nearest.position - position).length;

    for (final loc in locations) {
      final dist = (loc.position - position).length;
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }
    return nearest;
  }

  // Move the roach towards its target position
  void _moveTowardsTarget(double dt) {
    final target = currentTarget;
    if (target == null) return;

    Vector2 targetPos;
    if (target is Vector2) {
      targetPos = target;
    } else if (target is Food) {
      targetPos = target.position;
    } else if (target is WaterPellet) {
      targetPos = target.position;
    } else {
      return;
    }

    final direction = targetPos - position;
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
        currentTarget = null;
      }
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
class RoachComponent extends PositionComponent with TapCallbacks {
  final Roach roach;
  final void Function(Roach) onSelect;

  late final Paint bodyPaint;
  late final Paint outlinePaint;
  late final Paint legPaint;

  double _animationTime = 0;

  RoachComponent(this.roach, {required this.onSelect}) {
    size = Vector2(40, 70);
    anchor = Anchor.center;

    position = roach.position;
    angle = roach.orientation;

    bodyPaint = Paint()..color = const Color(0xFF8D6E63);
    outlinePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Thinner stroke width to make the legs less visually dominant
    legPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
  }

  @override
  void onTapDown(TapDownEvent event) {
    onSelect(roach);
  }

  @override
  void render(Canvas canvas) {
    final isMoving =
        roach.currentActivity == Activity.wandering ||
        roach.currentActivity == Activity.seekingFood ||
        roach.currentActivity == Activity.seekingWater;

    final swing = isMoving
        ? sin(_animationTime * 15) * 4
        : sin(_animationTime * 2) * 1;
    final antennaWiggle = sin(_animationTime * 8) * 3;

    // Adjusted horizontal reach so all six legs clearly peek out past the oval's widest point
    _drawLeg(canvas, const Offset(12, 30), const Offset(2, 28), swing);
    _drawLeg(canvas, const Offset(12, 45), const Offset(1, 45), -swing);
    _drawLeg(canvas, const Offset(12, 60), const Offset(2, 62), swing);

    _drawLeg(canvas, const Offset(28, 30), const Offset(38, 28), -swing);
    _drawLeg(canvas, const Offset(28, 45), const Offset(39, 45), swing);
    _drawLeg(canvas, const Offset(28, 60), const Offset(38, 62), -swing);

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
