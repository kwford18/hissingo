import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/config/sim_config.dart';
import 'package:hissingo/environment/food_dish.dart';
import 'package:hissingo/environment/hide.dart';
import 'package:hissingo/environment/water_dish.dart';
import 'package:hissingo/roach/activity.dart';
import 'package:hissingo/roach/roach.dart';

void main() {
  test('coaxOut changes activity to exitingHide when roach is hiding', () {
    final roach = Roach(id: 'test_1', name: 'Test', position: Vector2.zero());

    final testHide = Hide(
      position: Vector2.zero(),
      size: Vector2(100, 100),
      shape: HideShape.log,
      onSelect: (_) {},
    );

    roach.targetHide = testHide;
    roach.isHidden = true;
    roach.currentActivity = Activity.hiding;

    roach.coaxOut();

    expect(roach.currentActivity, Activity.exitingHide);
    expect(roach.currentTarget, isNotNull);
    expect(roach.stateTimer, 10.0);
  });

  test('coaxOut does nothing if roach is not hidden', () {
    final roach = Roach(id: 'test_1', name: 'Test', position: Vector2.zero());

    roach.currentActivity = Activity.idle;
    roach.coaxOut();

    expect(roach.currentActivity, Activity.idle);
  });

  test('receiveTreat assigns excited activity and targets central dish', () {
    final roach = Roach(id: 'test_t1', name: 'Test', position: Vector2.zero());

    roach.currentActivity = Activity.idle;
    roach.isHidden = true;

    final foodDish = FoodDish(position: Vector2.zero());
    final waterDish = WaterDish(position: Vector2.zero());

    roach.receiveTreat(
      foodDish: foodDish,
      waterDish: waterDish,
      random: Random(),
    );

    expect(roach.currentActivity, Activity.excitedForTreat);
    expect(roach.isHidden, isFalse);
    expect(roach.currentTarget, isNotNull);
  });

  test('update passively increases needs over time', () {
    final roach = Roach(id: 'test_1', name: 'Test', position: Vector2.zero());

    // Set to wandering so fatigue is not immediately drained by the idle state reduction
    roach.currentActivity = Activity.wandering;

    roach.update(
      10.0,
      boundaries: const Rect.fromLTWH(0, 0, 1000, 1000),
      foodDish: FoodDish(position: Vector2.zero()),
      waterDish: WaterDish(position: Vector2.zero()),
      availableHides: [],
      availableEnrichments: [],
      otherRoaches: [],
      isDayTime: true,
    );

    expect(roach.needs.hunger, greaterThan(0.0));
    expect(roach.needs.thirst, greaterThan(0.0));
    expect(roach.needs.fatigue, greaterThan(0.0));
    expect(roach.needs.boredom, greaterThan(50.0));
  });

  test('eating decreases hunger using infinite food dish', () {
    final roach = Roach(id: 'test_2', name: 'Hungry', position: Vector2.zero());

    roach.needs.hunger = 50.0;
    roach.currentActivity = Activity.eating;
    roach.stateTimer = 10.0;

    final dish = FoodDish(position: Vector2.zero());
    roach.currentTarget = dish;

    roach.update(
      1.0,
      boundaries: const Rect.fromLTWH(0, 0, 1000, 1000),
      foodDish: dish,
      waterDish: WaterDish(position: Vector2.zero()),
      availableHides: [],
      availableEnrichments: [],
      otherRoaches: [],
      isDayTime: true,
    );

    expect(roach.needs.hunger, lessThan(50.0));
  });

  test('drinking decreases thirst using infinite water dish', () {
    final roach = Roach(
      id: 'test_3',
      name: 'Thirsty',
      position: Vector2.zero(),
    );

    roach.needs.thirst = 50.0;
    roach.currentActivity = Activity.drinking;
    roach.stateTimer = 10.0;

    final dish = WaterDish(position: Vector2.zero());
    roach.currentTarget = dish;

    roach.update(
      1.0,
      boundaries: const Rect.fromLTWH(0, 0, 1000, 1000),
      foodDish: FoodDish(position: Vector2.zero()),
      waterDish: dish,
      availableHides: [],
      availableEnrichments: [],
      otherRoaches: [],
      isDayTime: true,
    );

    expect(roach.needs.thirst, lessThan(50.0));
  });

  test('enrichment early exit triggers when boredom reaches zero', () {
    final roach = Roach(id: 'test_4', name: 'Bored', position: Vector2.zero());

    roach.needs.boredom = 1.0;
    roach.currentActivity = Activity.usingEnrichment;
    roach.stateTimer = 10.0;

    roach.update(
      1.0,
      boundaries: const Rect.fromLTWH(0, 0, 1000, 1000),
      foodDish: FoodDish(position: Vector2.zero()),
      waterDish: WaterDish(position: Vector2.zero()),
      availableHides: [],
      availableEnrichments: [],
      otherRoaches: [],
      isDayTime: true,
    );

    expect(roach.needs.boredom, 0.0);
    expect(roach.currentActivity, Activity.idle);
  });

  test('social interaction applies movement speed multiplier', () {
    final roach = Roach(id: 'test_5', name: 'Social', position: Vector2.zero());

    roach.currentActivity = Activity.seekingSocial;
    roach.stateTimer = 10.0;
    roach.currentTarget = Roach(
      id: 'test_6',
      name: 'Friend',
      position: Vector2(100, 100),
    );

    roach.update(
      1.0,
      boundaries: const Rect.fromLTWH(0, 0, 1000, 1000),
      foodDish: FoodDish(position: Vector2.zero()),
      waterDish: WaterDish(position: Vector2.zero()),
      availableHides: [],
      availableEnrichments: [],
      otherRoaches: [],
      isDayTime: true,
    );

    final expectedDistance = roach.speed * SimConfig.socialSpeedMultiplier;
    final actualDistance = roach.position.distanceTo(Vector2.zero());

    expect(actualDistance, closeTo(expectedDistance, 0.1));
  });
}
