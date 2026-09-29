import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'environment.dart';

// Configuration for the simulation
class SimConfig {
  static double timeScale = 1.0;
  static double activityMultiplier = 5.0;
  static const double dayLengthSeconds = 1800.0;
}

enum Activity {
  idle,
  wandering,
  seekingFood,
  eating,
  seekingWater,
  drinking,
  seekingHide,
  enteringHide,
  hiding,
  exitingHide,
}

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

  Object? currentTarget;
  Hide? targetHide;
  Hide? favoriteHide;
  bool isHidden = false;

  double stateTimer = 0;
  final double speed = 30.0;
  final Random _random = Random();

  late final Color bodyColor;
  late final double scaleModifier;

  Roach({
    required this.id,
    required this.name,
    required this.position,
    this.orientation = 0,
    this.personality = const Personality(),
    Color? color,
    double? scale,
  }) {
    if (scale != null) {
      scaleModifier = scale;
    } else {
      // Generates a slight persistent variation in size
      scaleModifier = 0.85 + _random.nextDouble() * 0.3;
    }

    if (color != null) {
      bodyColor = color;
    } else {
      // Generates a persistent subtle color shift from the base hisser brown
      final rOff = _random.nextInt(40) - 20;
      final gOff = _random.nextInt(30) - 15;
      final bOff = _random.nextInt(30) - 15;

      final r = (141 + rOff).clamp(0, 255);
      final g = (110 + gOff).clamp(0, 255);
      final b = (99 + bOff).clamp(0, 255);

      bodyColor = Color.fromARGB(255, r, g, b);
    }
  }

  double get happiness => 100.0 - needs.averageNeed;

  // Prompts the roach to leave its current hide
  // Does not lower happiness
  void coaxOut() {
    final h = targetHide;
    if (isHidden && h is Hide) {
      currentActivity = Activity.exitingHide;
      currentTarget = h.getEntrance();
      stateTimer = 10.0;
    }
  }

  void update(
    double dt, {
    required Rect boundaries,
    required List<Food> availableFoods,
    required List<WaterPellet> availableWater,
    required List<Hide> availableHides,
    required bool isDayTime,
  }) {
    if (favoriteHide == null && availableHides.isNotEmpty) {
      favoriteHide = availableHides[_random.nextInt(availableHides.length)];
    }

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
      _decideNextActivity(
        boundaries: boundaries,
        availableFoods: availableFoods,
        availableWater: availableWater,
        availableHides: availableHides,
        isDayTime: isDayTime,
      );
    }

    final target = currentTarget;
    final isMoving =
        currentActivity == Activity.wandering ||
        currentActivity == Activity.seekingFood ||
        currentActivity == Activity.seekingWater ||
        currentActivity == Activity.seekingHide ||
        currentActivity == Activity.enteringHide ||
        currentActivity == Activity.exitingHide;

    // Verify the object is present in memory to safely permit movement
    if (isMoving && target is Object) {
      _moveTowardsTarget(dt);
    }
  }

  void _handleActiveStates(double dt) {
    final target = currentTarget;

    if (currentActivity == Activity.eating) {
      if (target is Food && target.isDepleted == false) {
        needs.hunger -= dt * 30.0;
        if (needs.hunger < 0) needs.hunger = 0;
        if (stateTimer <= 0.1) {
          target.isDepleted = true;
        }
      } else {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
    } else if (currentActivity == Activity.drinking) {
      if (target is WaterPellet && target.isDepleted == false) {
        needs.thirst -= dt * 30.0;
        if (needs.thirst < 0) needs.thirst = 0;
        if (stateTimer <= 0.1) {
          target.isDepleted = true;
        }
      } else {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
    } else if (currentActivity == Activity.idle) {
      needs.fatigue -= dt * 2.0;
      if (needs.fatigue < 0) needs.fatigue = 0;
    } else if (currentActivity == Activity.hiding) {
      needs.fatigue -= dt * 4.0;
      if (needs.fatigue < 0) needs.fatigue = 0;
    }
  }

  // Decides next activity based on needs, available resources, and personality traits
  void _decideNextActivity({
    required Rect boundaries,
    required List<Food> availableFoods,
    required List<WaterPellet> availableWater,
    required List<Hide> availableHides,
    required bool isDayTime,
  }) {
    final h = targetHide;

    if (isHidden && h is Hide) {
      if (needs.fatigue < 10 || needs.hunger > 60 || needs.thirst > 60) {
        currentActivity = Activity.exitingHide;
        currentTarget = h.getEntrance();
        stateTimer = 10.0;
      }
      return;
    }

    if (currentActivity == Activity.enteringHide ||
        currentActivity == Activity.exitingHide) {
      return;
    }

    if (needs.thirst > 40 && availableWater.isNotEmpty) {
      final waterTarget = _findNearestWater(availableWater);
      if (waterTarget is WaterPellet) {
        currentActivity = Activity.seekingWater;
        currentTarget = waterTarget;
        stateTimer = 30.0;
        return;
      }
    }

    if (needs.hunger > 40 && availableFoods.isNotEmpty) {
      final foodTarget = _findNearestFood(availableFoods);
      if (foodTarget is Food) {
        currentActivity = Activity.seekingFood;
        currentTarget = foodTarget;
        stateTimer = 30.0;
        return;
      }
    }

    double wanderWeight =
        15.0 * personality.activity * SimConfig.activityMultiplier;
    double hideWeight = 25.0 * (1.0 + personality.skittishness);
    double idleWeight = 40.0;

    // Time of day heavily influences the weights for more natural feeling behavior
    // Roaches are more likely to hide during the day and wander at night
    if (isDayTime) {
      hideWeight *= 2.5;
      idleWeight *= 1.5;
      wanderWeight *= 0.3;
    } else {
      wanderWeight *= 2.0;
      hideWeight *= 0.5;
    }

    double totalWeight = wanderWeight + hideWeight + idleWeight;
    double roll = _random.nextDouble() * totalWeight;

    if (roll < wanderWeight) {
      currentActivity = Activity.wandering;
      stateTimer = 5.0 + _random.nextDouble() * 5.0;

      final targetX = boundaries.left + _random.nextDouble() * boundaries.width;
      final targetY = boundaries.top + _random.nextDouble() * boundaries.height;
      currentTarget = Vector2(targetX, targetY);
    } else if (roll < wanderWeight + hideWeight && availableHides.isNotEmpty) {
      currentActivity = Activity.seekingHide;
      targetHide = _chooseHide(availableHides);
      final currentTargetHide = targetHide;
      if (currentTargetHide is Hide) {
        currentTarget = currentTargetHide.getEntrance();
      }
      stateTimer = 30.0;
    } else {
      currentActivity = Activity.idle;
      stateTimer = 2.0 + _random.nextDouble() * 4.0;
      currentTarget = null;
    }
  }

  Food? _findNearestFood(List<Food> locations) {
    final validFoods = locations.where((f) => f.isDepleted == false).toList();
    if (validFoods.isEmpty) return null;

    Food nearest = validFoods.first;
    double minDistance = (nearest.position - position).length;

    for (final loc in validFoods) {
      final dist = (loc.position - position).length;
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }
    return nearest;
  }

  WaterPellet? _findNearestWater(List<WaterPellet> locations) {
    final validWater = locations.where((w) => w.isDepleted == false).toList();
    if (validWater.isEmpty) return null;

    WaterPellet nearest = validWater.first;
    double minDistance = (nearest.position - position).length;

    for (final loc in validWater) {
      final dist = (loc.position - position).length;
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }
    return nearest;
  }

  Hide _chooseHide(List<Hide> locations) {
    final fav = favoriteHide;
    if (fav is Hide && locations.contains(fav)) {
      // Roaches strongly prefer to return to their personal favorite hide
      if (_random.nextDouble() < 0.8) {
        return fav;
      }
    }

    Hide nearest = locations.first;
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
    } else if (target is Hide) {
      // Targets the center of the hide when seeking it
      targetPos = target.position + (target.size / 2);
    } else {
      return;
    }

    final direction = targetPos - position;
    final distance = direction.length;

    bool reachedTarget = false;

    if (currentActivity == Activity.seekingHide && target is Hide) {
      final hideRect = Rect.fromLTWH(
        target.position.x,
        target.position.y,
        target.size.x,
        target.size.y,
      );
      if (hideRect.contains(Offset(position.x, position.y))) {
        reachedTarget = true;
      }
    } else {
      if (distance < 5.0) {
        reachedTarget = true;
      }
    }

    if (reachedTarget) {
      if (currentActivity == Activity.seekingFood) {
        currentActivity = Activity.eating;
        stateTimer = 4.0;
      } else if (currentActivity == Activity.seekingWater) {
        currentActivity = Activity.drinking;
        stateTimer = 4.0;
      } else if (currentActivity == Activity.seekingHide) {
        currentActivity = Activity.enteringHide;
        final h = targetHide;
        if (h is Hide) {
          currentTarget = h.getRandomInterior(_random);
        }
        isHidden = true;
      } else if (currentActivity == Activity.enteringHide) {
        currentActivity = Activity.hiding;
        currentTarget = null;
        stateTimer = 30.0;
      } else if (currentActivity == Activity.exitingHide) {
        currentActivity = Activity.idle;
        currentTarget = null;
        isHidden = false;
        targetHide = null;
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
    scale = Vector2(roach.scaleModifier, roach.scaleModifier);

    position = roach.position;
    angle = roach.orientation;

    bodyPaint = Paint()..color = roach.bodyColor;
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
        roach.currentActivity == Activity.seekingWater ||
        roach.currentActivity == Activity.seekingHide ||
        roach.currentActivity == Activity.enteringHide ||
        roach.currentActivity == Activity.exitingHide;

    final swing = isMoving
        ? sin(_animationTime * 15) * 4
        : sin(_animationTime * 2) * 1;
    final antennaWiggle = sin(_animationTime * 8) * 3;

    // Draws the legs
    // Each leg should barely peek out of the carrapace,
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
