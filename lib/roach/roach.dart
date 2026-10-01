import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../config/sim_config.dart';
import '../environment/enrichment.dart';
import '../environment/food_dish.dart';
import '../environment/hide.dart';
import '../environment/water_dish.dart';
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

  // Prompts the roach to leave its current hide
  void coaxOut() {
    final h = targetHide;
    if (isHidden && h != null) {
      currentActivity = Activity.exitingHide;
      currentTarget = h.getEntrance();
      stateTimer = 10.0;
    }
  }

  // Forces the roach to immediately stop what it is doing and run to a dish
  void receiveTreat({
    required FoodDish foodDish,
    required WaterDish waterDish,
    required Random random,
  }) {
    currentActivity = Activity.excitedForTreat;
    isHidden = false;
    targetHide = null;
    stateTimer = 30.0;

    if (random.nextBool()) {
      currentTarget = foodDish;
    } else {
      currentTarget = waterDish;
    }
  }

  void update(
    double dt, {
    required Rect boundaries,
    required FoodDish foodDish,
    required WaterDish waterDish,
    required List<Hide> availableHides,
    required List<EnrichmentObject> availableEnrichments,
    required List<Roach> otherRoaches,
    required bool isDayTime,
  }) {
    if (favoriteHide == null && availableHides.isNotEmpty) {
      favoriteHide = availableHides[_random.nextInt(availableHides.length)];
    }

    // Passively increase needs over time slowly to ensure high baseline comfort
    needs.hunger += dt * 0.1 * personality.appetite;
    needs.thirst += dt * 0.15 * personality.appetite;
    needs.fatigue += dt * 0.1;
    needs.boredom += dt * 0.2;

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
        foodDish: foodDish,
        waterDish: waterDish,
        availableHides: availableHides,
        availableEnrichments: availableEnrichments,
        otherRoaches: otherRoaches,
        isDayTime: isDayTime,
      );
    }

    final target = currentTarget;

    // Verify the object is present in memory to safely permit movement
    if (currentActivity.isMoving && target != null) {
      _moveTowardsTarget(dt);
    }
  }

  void _handleActiveStates(double dt) {
    final target = currentTarget;

    if (currentActivity == Activity.eating) {
      if (target is FoodDish) {
        needs.hunger -= dt * 40.0;
        if (needs.hunger <= 0) {
          needs.hunger = 0;
          currentActivity = Activity.idle;
          currentTarget = null;
          stateTimer = 2.0;
        }
      } else {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
    } else if (currentActivity == Activity.drinking) {
      if (target is WaterDish) {
        needs.thirst -= dt * 40.0;
        if (needs.thirst <= 0) {
          needs.thirst = 0;
          currentActivity = Activity.idle;
          currentTarget = null;
          stateTimer = 2.0;
        }
      } else {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
    } else if (currentActivity == Activity.idle) {
      needs.fatigue -= dt * 2.0;
      if (needs.fatigue < 0) needs.fatigue = 0;
    } else if (currentActivity == Activity.hiding) {
      needs.fatigue -= dt * 10.0;
      if (needs.fatigue < 0) needs.fatigue = 0;
    } else if (currentActivity == Activity.usingEnrichment) {
      needs.boredom -= dt * 15.0;
      needs.fatigue += dt * 3.0;
      if (needs.fatigue > 100) needs.fatigue = 100;

      // Exit enrichment immediately when boredom is resolved
      // to prevent unnecessary fatigue generation
      if (needs.boredom <= 0) {
        needs.boredom = 0;
        currentActivity = Activity.idle;
        currentTarget = null;
        stateTimer = 0;
      }
    } else if (currentActivity == Activity.interacting) {
      // The interaction outcome is processed immediately when they meet
      // so this state just holds them still while the emotion timer counts down
      if (stateTimer <= 0.1) {
        currentActivity = Activity.idle;
        currentTarget = null;
      }
    }
  }

  // Translates need tiers into probability weights to make decision making organic
  double _getNeedWeight(double needValue) {
    if (needValue > 90) return 500.0; // Must seek
    if (needValue > 70) return 150.0; // Frequently seek
    if (needValue > 40) return 50.0; // Occasionally seek
    return 0.0; // Comfortable
  }

  // Decides next activity using a purely weighted probability system
  void _decideNextActivity({
    required Rect boundaries,
    required FoodDish foodDish,
    required WaterDish waterDish,
    required List<Hide> availableHides,
    required List<EnrichmentObject> availableEnrichments,
    required List<Roach> otherRoaches,
    required bool isDayTime,
  }) {
    final h = targetHide;

    if (isHidden && h != null) {
      // Small chance to wake up and leave if fully rested and comfortable
      if (needs.fatigue < 10 && needs.hunger < 50 && needs.thirst < 50) {
        if (_random.nextDouble() < 0.2) {
          currentActivity = Activity.exitingHide;
          currentTarget = h.getEntrance();
          stateTimer = 10.0;
          return;
        }
      }

      currentActivity = Activity.hiding;
      stateTimer = 10.0;
      return;
    }

    if (currentActivity == Activity.enteringHide ||
        currentActivity == Activity.exitingHide ||
        currentActivity == Activity.excitedForTreat) {
      return;
    }

    // Urgent needs force behavior to ensure survival routines are prioritized
    if (needs.thirst > 40) {
      currentActivity = Activity.seekingWater;
      currentTarget = waterDish;
      stateTimer = 30.0;
      return;
    }

    if (needs.hunger > 40) {
      currentActivity = Activity.seekingFood;
      currentTarget = foodDish;
      stateTimer = 30.0;
      return;
    }

    if (needs.fatigue > 60 && availableHides.isNotEmpty) {
      currentActivity = Activity.seekingHide;
      targetHide = _chooseHide(availableHides);
      currentTarget = targetHide?.getEntrance();
      stateTimer = 30.0;
      return;
    }

    if (needs.boredom > 60 && availableEnrichments.isNotEmpty) {
      currentActivity = Activity.seekingEnrichment;
      final enrichment =
          availableEnrichments[_random.nextInt(availableEnrichments.length)];
      currentTarget = enrichment.getInteractionSpot(_random);
      stateTimer = 30.0;
      return;
    }

    // Base behavioral weights
    double idleWeight = 40.0;
    double hideWeight = availableHides.isNotEmpty
        ? 25.0 * (1.0 + personality.skittishness)
        : 0.0;
    double wanderWeight =
        15.0 * personality.activity * SimConfig.activityMultiplier;
    double socialWeight = otherRoaches.isNotEmpty
        ? 10.0 * personality.friendliness
        : 0.0;

    // Need-driven weights
    double foodWeight = _getNeedWeight(needs.hunger);
    double waterWeight = _getNeedWeight(needs.thirst);
    double restWeight = availableHides.isNotEmpty
        ? _getNeedWeight(needs.fatigue)
        : 0.0;
    double boredomWeight = availableEnrichments.isNotEmpty
        ? _getNeedWeight(needs.boredom)
        : 0.0;

    // Time of day heavily influences the natural behaviors
    if (isDayTime) {
      hideWeight *= 2.5;
      idleWeight *= 1.5;
      wanderWeight *= 0.3;
      socialWeight *= 0.5;
    } else {
      wanderWeight *= 2.0;
      hideWeight *= 0.5;
      socialWeight *= 1.5;
    }

    double totalWeight =
        idleWeight +
        hideWeight +
        wanderWeight +
        socialWeight +
        foodWeight +
        waterWeight +
        restWeight +
        boredomWeight;

    double roll = _random.nextDouble() * totalWeight;

    // Weighted decision resolution
    if (roll < foodWeight) {
      currentActivity = Activity.seekingFood;
      currentTarget = foodDish;
      stateTimer = 30.0;
    } else if (roll < foodWeight + waterWeight) {
      currentActivity = Activity.seekingWater;
      currentTarget = waterDish;
      stateTimer = 30.0;
    } else if (roll < foodWeight + waterWeight + restWeight) {
      currentActivity = Activity.seekingHide;
      targetHide = _chooseHide(availableHides);
      currentTarget = targetHide?.getEntrance();
      stateTimer = 30.0;
    } else if (roll < foodWeight + waterWeight + restWeight + boredomWeight) {
      currentActivity = Activity.seekingEnrichment;
      final enrichment =
          availableEnrichments[_random.nextInt(availableEnrichments.length)];
      currentTarget = enrichment.getInteractionSpot(_random);
      stateTimer = 30.0;
    } else if (roll <
        foodWeight + waterWeight + restWeight + boredomWeight + socialWeight) {
      currentActivity = Activity.seekingSocial;
      targetRoach = otherRoaches[_random.nextInt(otherRoaches.length)];
      currentTarget = targetRoach;
      stateTimer = 30.0;
    } else if (roll <
        foodWeight +
            waterWeight +
            restWeight +
            boredomWeight +
            socialWeight +
            hideWeight) {
      currentActivity = Activity.seekingHide;
      targetHide = _chooseHide(availableHides);
      currentTarget = targetHide?.getEntrance();
      stateTimer = 30.0;
    } else if (roll <
        foodWeight +
            waterWeight +
            restWeight +
            boredomWeight +
            socialWeight +
            hideWeight +
            wanderWeight) {
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

  Hide _chooseHide(List<Hide> locations) {
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
    } else if (target is FoodDish) {
      targetPos = target.position;
    } else if (target is WaterDish) {
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
      } else if (currentActivity == Activity.excitedForTreat) {
        if (target is FoodDish) {
          currentActivity = Activity.eating;
          stateTimer = 4.0;
        } else if (target is WaterDish) {
          currentActivity = Activity.drinking;
          stateTimer = 4.0;
        } else {
          currentActivity = Activity.idle;
          currentTarget = null;
        }
      } else if (currentActivity == Activity.seekingHide) {
        currentActivity = Activity.enteringHide;
        final h = targetHide;
        if (h != null) {
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
    if (currentActivity == Activity.seekingSocial ||
        currentActivity == Activity.excitedForTreat) {
      currentSpeed *= SimConfig.socialSpeedMultiplier;
    }

    direction.normalize();
    position += direction * currentSpeed * dt;

    final targetAngle = atan2(direction.y, direction.x) + (pi / 2);
    final angleDiff = (targetAngle - orientation + pi) % (2 * pi) - pi;

    orientation += angleDiff * 5.0 * dt;
  }
}
