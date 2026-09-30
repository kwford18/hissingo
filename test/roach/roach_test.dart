import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/environment/food.dart';
import 'package:hissingo/environment/hide.dart';
import 'package:hissingo/environment/water_pellet.dart';
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

  test('update passively increases needs over time', () {
    final roach = Roach(id: 'test_1', name: 'Test', position: Vector2.zero());

    // Set to wandering so fatigue is not immediately drained by the idle state reduction
    roach.currentActivity = Activity.wandering;

    final initialHunger = roach.needs.hunger;
    final initialThirst = roach.needs.thirst;
    final initialFatigue = roach.needs.fatigue;
    final initialBoredom = roach.needs.boredom;

    roach.update(
      1.0,
      boundaries: const Rect.fromLTWH(0, 0, 1000, 1000),
      availableFoods: [],
      availableWater: [],
      availableHides: [],
      availableBranches: [],
      otherRoaches: [],
      isDayTime: true,
    );

    expect(roach.needs.hunger, greaterThan(initialHunger));
    expect(roach.needs.thirst, greaterThan(initialThirst));
    expect(roach.needs.fatigue, greaterThan(initialFatigue));
    expect(roach.needs.boredom, greaterThan(initialBoredom));
  });

  test('eating decreases hunger and depletes food', () {
    final roach = Roach(id: 'test_2', name: 'Hungry', position: Vector2.zero());

    roach.needs.hunger = 50.0;
    roach.currentActivity = Activity.eating;

    final food = Food(position: Vector2.zero());
    roach.currentTarget = food;

    roach.update(
      1.0,
      boundaries: const Rect.fromLTWH(0, 0, 1000, 1000),
      availableFoods: [food],
      availableWater: [],
      availableHides: [],
      availableBranches: [],
      otherRoaches: [],
      isDayTime: true,
    );

    expect(roach.needs.hunger, lessThan(50.0));
  });

  test('drinking decreases thirst and depletes water', () {
    final roach = Roach(
      id: 'test_3',
      name: 'Thirsty',
      position: Vector2.zero(),
    );

    roach.needs.thirst = 50.0;
    roach.currentActivity = Activity.drinking;

    final water = WaterPellet(position: Vector2.zero());
    roach.currentTarget = water;

    roach.update(
      1.0,
      boundaries: const Rect.fromLTWH(0, 0, 1000, 1000),
      availableFoods: [],
      availableWater: [water],
      availableHides: [],
      availableBranches: [],
      otherRoaches: [],
      isDayTime: true,
    );

    expect(roach.needs.thirst, lessThan(50.0));
  });
}
