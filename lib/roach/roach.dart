import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../config/sim_config.dart';
import '../environment/climbing_branch.dart';
import '../environment/food.dart';
import '../environment/hide.dart';
import '../environment/water_pellet.dart';
import 'activity.dart';
import 'needs.dart';
import 'personality.dart';

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
  Roach? targetRoach;
  bool isHidden = false;

  String? currentEmotion;
  double emotionTimer = 0;

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
    required List<ClimbingBranch> availableBranches,
    required List<Roach> otherRoaches,
    required bool isDayTime,
  }) {
    if (favoriteHide == null && availableHides.isNotEmpty) {
      favoriteHide = availableHides[_random.nextInt(availableHides.length)];
    }

    // Passively increase needs over time
    needs.hunger += dt * 0.5 * personality.appetite;
    needs.thirst += dt * 0.7 * personality.appetite;
    needs.fatigue += dt * 0.2;
    needs.boredom += dt * 0.4;

    if (needs.hunger > 100) needs.hunger = 100;
    if (needs.thirst > 100) needs.thirst = 100;
    if (needs.fatigue > 100) needs.fatigue = 100;
    if (needs.boredom > 100) needs.boredom = 100;

    _handleActiveStates(dt);

    if (emotionTimer > 0) {
      emotionTimer -= dt;
      if (emotionTimer <= 0) {
        currentEmotion = null;
      }
    }

    stateTimer -= dt;
    if (stateTimer <= 0) {
      _decideNextActivity(
        boundaries: boundaries,
        availableFoods: availableFoods,
        availableWater: availableWater,
        availableHides: availableHides,
        availableBranches: availableBranches,
        otherRoaches: otherRoaches,
        isDayTime: isDayTime,
      );
    }

    final target = currentTarget;

    // Verify the object is present in memory to safely permit movement
    if (currentActivity.isMoving && target is Object) {
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
    } else if (currentActivity == Activity.usingEnrichment) {
      needs.boredom -= dt * 8.0;
      needs.fatigue += dt * 3.0;
      if (needs.boredom < 0) needs.boredom = 0;
      if (needs.fatigue > 100) needs.fatigue = 100;
    } else if (currentActivity == Activity.interacting) {
      // The interaction outcome is processed immediately when they meet
      // so this state just holds them still while the emotion timer counts down
      if (stateTimer <= 0.1) {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
    }
  }

  // Decides next activity based on needs, available resources, and personality traits
  void _decideNextActivity({
    required Rect boundaries,
    required List<Food> availableFoods,
    required List<WaterPellet> availableWater,
    required List<Hide> availableHides,
    required List<ClimbingBranch> availableBranches,
    required List<Roach> otherRoaches,
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
    double enrichmentWeight = needs.boredom * 0.5 * personality.activity;
    double socialWeight = 15.0 * personality.friendliness;

    // Time of day heavily influences the weights for more natural feeling behavior
    // Roaches are more likely to hide during the day and wander at night
    if (isDayTime) {
      hideWeight *= 2.5;
      idleWeight *= 1.5;
      wanderWeight *= 0.3;
      enrichmentWeight *= 0.5;
      socialWeight *= 0.5;
    } else {
      wanderWeight *= 2.0;
      hideWeight *= 0.5;
      enrichmentWeight *= 1.5;
      socialWeight *= 1.5;
    }

    double totalWeight =
        wanderWeight +
        hideWeight +
        idleWeight +
        enrichmentWeight +
        socialWeight;

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
    } else if (roll < wanderWeight + hideWeight + enrichmentWeight &&
        availableBranches.isNotEmpty) {
      currentActivity = Activity.seekingEnrichment;
      final branch =
          availableBranches[_random.nextInt(availableBranches.length)];
      currentTarget = branch.getRandomClimbSpot(_random);
      stateTimer = 30.0;
    } else if (roll <
            wanderWeight + hideWeight + enrichmentWeight + socialWeight &&
        otherRoaches.isNotEmpty) {
      currentActivity = Activity.seekingSocial;
      targetRoach = otherRoaches[_random.nextInt(otherRoaches.length)];
      currentTarget = targetRoach;
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
    } else if (target is Roach) {
      targetPos = target.position;
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
    } else if (currentActivity == Activity.seekingSocial && target is Roach) {
      // Interact when they get reasonably close to each other
      if (distance < 40.0) {
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
      } else if (currentActivity == Activity.seekingEnrichment) {
        currentActivity = Activity.usingEnrichment;
        currentTarget = null;
        stateTimer = 15.0 + _random.nextDouble() * 15.0;
      } else if (currentActivity == Activity.seekingSocial) {
        currentActivity = Activity.interacting;
        stateTimer = 3.0;

        // Determine the outcome of the social interaction based on friendliness
        if (_random.nextDouble() < personality.friendliness) {
          currentEmotion = ':)';
          needs.boredom -= 20;
          if (needs.boredom < 0) needs.boredom = 0;
        } else {
          currentEmotion = 'Hiss.';
          needs.fatigue += 15;
          if (needs.fatigue > 100) needs.fatigue = 100;
        }
        emotionTimer = 3.0;
        currentTarget = null;
        targetRoach = null;
      } else {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
      return;
    }

    double currentSpeed = speed;
    if (currentActivity == Activity.seekingSocial) {
      currentSpeed *= SimConfig.socialSpeedMultiplier;
    }

    direction.normalize();
    position += direction * currentSpeed * dt;

    final targetAngle = atan2(direction.y, direction.x) + (pi / 2);
    final angleDiff = (targetAngle - orientation + pi) % (2 * pi) - pi;

    orientation += angleDiff * 5.0 * dt;
  }
}
