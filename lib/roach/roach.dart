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
      final rOff = _random.nextInt(81) - 40;
      final gOff = _random.nextInt(61) - 30;
      final bOff = _random.nextInt(61) - 30;

      final r = (141 + rOff).clamp(0, 255);
      final g = (110 + gOff).clamp(0, 255);
      final b = (99 + bOff).clamp(0, 255);

      bodyColor = Color.fromARGB(255, r, g, b);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': {'x': position.x, 'y': position.y},
    'orientation': orientation,
    'personality': personality.toJson(),
    'needs': needs.toJson(),
    'bodyColor': bodyColor.toARGB32(),
    'scaleModifier': scaleModifier,
  };

  factory Roach.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>? ?? {};
    final roach = Roach(
      id:
          json['id'] as String? ??
          'roach_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown',
      position: Vector2(
        (pos['x'] as num?)?.toDouble() ?? 1000.0,
        (pos['y'] as num?)?.toDouble() ?? 1000.0,
      ),
      orientation: (json['orientation'] as num?)?.toDouble() ?? 0.0,
      personality: json['personality'] != null
          ? Personality.fromJson(json['personality'] as Map<String, dynamic>)
          : const Personality(),
      color: json['bodyColor'] != null ? Color(json['bodyColor'] as int) : null,
      scale: (json['scaleModifier'] as num?)?.toDouble(),
    );

    if (json['needs'] != null) {
      final savedNeeds = Needs.fromJson(json['needs'] as Map<String, dynamic>);
      roach.needs.hunger = savedNeeds.hunger;
      roach.needs.thirst = savedNeeds.thirst;
      roach.needs.fatigue = savedNeeds.fatigue;
      roach.needs.boredom = savedNeeds.boredom;
    }

    return roach;
  }

  // Prompts the roach to leave its current hide
  void coaxOut() {
    final h = targetHide;
    if (isHidden && h != null) {
      _startExitingHide(h);
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
    currentTarget = random.nextBool() ? foodDish : waterDish;
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

  // Helper function to reset roach's activity and target
  void _endActivity({double? timer}) {
    currentActivity = Activity.idle;
    currentTarget = null;

    if (timer != null) {
      stateTimer = timer;
    }
  }

  void _startSeekingFood(FoodDish foodDish) {
    currentActivity = Activity.seekingFood;
    currentTarget = foodDish;
    stateTimer = 30.0;
  }

  void _startSeekingWater(WaterDish waterDish) {
    currentActivity = Activity.seekingWater;
    currentTarget = waterDish;
    stateTimer = 30.0;
  }

  void _startSeekingHide(List<Hide> hides) {
    currentActivity = Activity.seekingHide;
    targetHide = _chooseHide(hides);
    currentTarget = targetHide?.getEntrance();
    stateTimer = 30.0;
  }

  void _startSeekingEnrichment(List<EnrichmentObject> enrichments) {
    currentActivity = Activity.seekingEnrichment;
    final enrichment = enrichments[_random.nextInt(enrichments.length)];
    currentTarget = enrichment.getInteractionSpot(_random);
    stateTimer = 30.0;
  }

  void _startSeekingSocial(List<Roach> others) {
    currentActivity = Activity.seekingSocial;
    targetRoach = others[_random.nextInt(others.length)];
    currentTarget = targetRoach;
    stateTimer = 30.0;
  }

  void _startWandering(Rect boundaries) {
    currentActivity = Activity.wandering;
    stateTimer = 5.0 + _random.nextDouble() * 5.0;
    currentTarget = Vector2(
      boundaries.left + _random.nextDouble() * boundaries.width,
      boundaries.top + _random.nextDouble() * boundaries.height,
    );
  }

  void _startIdling() {
    currentActivity = Activity.idle;
    stateTimer = 2.0 + _random.nextDouble() * 4.0;
    currentTarget = null;
  }

  void _startExitingHide(Hide hide) {
    currentActivity = Activity.exitingHide;
    currentTarget = hide.getEntrance();
    stateTimer = 10.0;
  }

  void _startEating() {
    currentActivity = Activity.eating;
    stateTimer = 4.0;
  }

  void _startDrinking() {
    currentActivity = Activity.drinking;
    stateTimer = 4.0;
  }

  // Per-frame effects of the current activity

  void _handleActiveStates(double dt) {
    final target = currentTarget;

    switch (currentActivity) {
      case Activity.eating:
        if (target is FoodDish) {
          needs.hunger -= dt * 40.0;
          if (needs.hunger <= 0) {
            needs.hunger = 0;
            _endActivity(timer: 2.0);
          }
        } else {
          _endActivity();
        }

      case Activity.drinking:
        if (target is WaterDish) {
          needs.thirst -= dt * 40.0;
          if (needs.thirst <= 0) {
            needs.thirst = 0;
            _endActivity(timer: 2.0);
          }
        } else {
          _endActivity();
        }

      case Activity.idle:
        needs.fatigue -= dt * 2.0;
        if (needs.fatigue < 0) needs.fatigue = 0;

      case Activity.hiding:
        needs.fatigue -= dt * 10.0;
        if (needs.fatigue < 0) needs.fatigue = 0;

      case Activity.usingEnrichment:
        needs.boredom -= dt * 15.0;
        needs.fatigue += dt * 3.0;
        if (needs.fatigue > 100) needs.fatigue = 100;

        // Exit enrichment immediately when boredom is resolved
        // to prevent unnecessary fatigue generation
        if (needs.boredom <= 0) {
          needs.boredom = 0;
          _endActivity(timer: 2.0);
        }

      case Activity.interacting:
        // The interaction outcome is processed immediately when they meet
        // so this state just holds them still while the emotion timer counts down
        if (stateTimer <= 0.1) {
          _endActivity();
        }

      // Travelling activities have no per-frame need effects
      case Activity.wandering ||
          Activity.seekingFood ||
          Activity.seekingWater ||
          Activity.seekingHide ||
          Activity.enteringHide ||
          Activity.exitingHide ||
          Activity.seekingEnrichment ||
          Activity.seekingSocial ||
          Activity.excitedForTreat:
        break;
    }
  }

  // Decision making

  // Translates need tiers into probability weights for decision making
  double _getNeedWeight(double needValue) => switch (needValue) {
    > 90 => 500.0, // Must seek
    > 70 => 150.0, // Frequently seek
    > 40 => 50.0, // Occasionally seek
    _ => 0.0, // Comfortable
  };

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
      final isComfortable =
          needs.fatigue < 10 && needs.hunger < 50 && needs.thirst < 50;
      if (isComfortable && _random.nextDouble() < 0.2) {
        _startExitingHide(h);
        return;
      }

      currentActivity = Activity.hiding;
      stateTimer = 10.0;
      return;
    }

    // Transitional activities must finish before anything new is chosen
    if (currentActivity.isTransitional) return;

    // Urgent needs force behavior to ensure survival routines are prioritized
    if (needs.thirst > 40) {
      _startSeekingWater(waterDish);
      return;
    }

    if (needs.hunger > 40) {
      _startSeekingFood(foodDish);
      return;
    }

    if (needs.fatigue > 60 && availableHides.isNotEmpty) {
      _startSeekingHide(availableHides);
      return;
    }

    if (needs.boredom > 60 && availableEnrichments.isNotEmpty) {
      _startSeekingEnrichment(availableEnrichments);
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
    final foodWeight = _getNeedWeight(needs.hunger);
    final waterWeight = _getNeedWeight(needs.thirst);
    final restWeight = availableHides.isNotEmpty
        ? _getNeedWeight(needs.fatigue)
        : 0.0;
    final boredomWeight = availableEnrichments.isNotEmpty
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

    // Each choice pairs its weight with what happens if it wins the roll.
    // Order matters only for tie-breaking at the boundaries; idle is the fallback.
    final choices = <({double weight, void Function() action})>[
      (weight: foodWeight, action: () => _startSeekingFood(foodDish)),
      (weight: waterWeight, action: () => _startSeekingWater(waterDish)),
      (weight: restWeight, action: () => _startSeekingHide(availableHides)),
      (
        weight: boredomWeight,
        action: () => _startSeekingEnrichment(availableEnrichments),
      ),
      (weight: socialWeight, action: () => _startSeekingSocial(otherRoaches)),
      (weight: hideWeight, action: () => _startSeekingHide(availableHides)),
      (weight: wanderWeight, action: () => _startWandering(boundaries)),
    ];

    final totalWeight = choices.fold<double>(
      idleWeight,
      (sum, c) => sum + c.weight,
    );

    // Weighted decision resolution:
    // walk the choices, subtracting weights
    // until the roll lands inside one of them
    var roll = _random.nextDouble() * totalWeight;
    for (final choice in choices) {
      if (roll < choice.weight) {
        choice.action();
        return;
      }
      roll -= choice.weight;
    }

    _startIdling();
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

  // Movement

  // Move the roach towards its target position
  void _moveTowardsTarget(double dt) {
    final target = currentTarget;
    if (target == null) return;

    final Vector2? targetPos = switch (target) {
      Vector2 v => v,
      FoodDish d => d.position,
      WaterDish d => d.position,
      // Targets the center of the hide when seeking it
      Hide h => h.position + (h.size / 2),
      Roach r => r.position,
      _ => null,
    };
    if (targetPos == null) return;

    final direction = targetPos - position;
    final distance = direction.length;

    if (_hasReachedTarget(target, distance)) {
      _onReachedTarget(target);
      return;
    }

    final currentSpeed = switch (currentActivity) {
      Activity.seekingSocial ||
      Activity.excitedForTreat => speed * SimConfig.socialSpeedMultiplier,
      _ => speed,
    };

    direction.normalize();
    position += direction * currentSpeed * dt;

    final targetAngle = atan2(direction.y, direction.x) + (pi / 2);
    final angleDiff = (targetAngle - orientation + pi) % (2 * pi) - pi;

    orientation += angleDiff * 5.0 * dt;
  }

  // Each activity has its own idea of what "arrived" means
  bool _hasReachedTarget(Object target, double distance) {
    return switch ((currentActivity, target)) {
      (Activity.seekingHide, Hide h) => Rect.fromLTWH(
        h.position.x,
        h.position.y,
        h.size.x,
        h.size.y,
      ).contains(Offset(position.x, position.y)),
      // Interact when they get reasonably close to each other
      (Activity.seekingSocial, Roach _) => distance < 40.0,
      _ => distance < 5.0,
    };
  }

  // What happens when the roach arrives, depending on why it was moving
  void _onReachedTarget(Object target) {
    switch (currentActivity) {
      case Activity.seekingFood:
        _startEating();

      case Activity.seekingWater:
        _startDrinking();

      case Activity.excitedForTreat:
        switch (target) {
          case FoodDish():
            _startEating();
          case WaterDish():
            _startDrinking();
          default:
            _endActivity();
        }

      case Activity.seekingHide:
        currentActivity = Activity.enteringHide;
        final h = targetHide;
        if (h != null) {
          currentTarget = h.getRandomInterior(_random);
        }
        isHidden = true;

      case Activity.enteringHide:
        currentActivity = Activity.hiding;
        currentTarget = null;
        stateTimer = 30.0;

      case Activity.exitingHide:
        _endActivity();
        isHidden = false;
        targetHide = null;

      case Activity.seekingEnrichment:
        currentActivity = Activity.usingEnrichment;
        currentTarget = null;
        stateTimer = 15.0 + _random.nextDouble() * 15.0;

      case Activity.seekingSocial:
        _startInteracting();

      // Not travelling toward anything, so arriving just resets to idle
      case Activity.idle ||
          Activity.wandering ||
          Activity.eating ||
          Activity.drinking ||
          Activity.hiding ||
          Activity.usingEnrichment ||
          Activity.interacting:
        _endActivity();
    }
  }

  void _startInteracting() {
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
  }
}
