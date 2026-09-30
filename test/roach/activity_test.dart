import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/roach/activity.dart';
import 'package:hissingo/ui/activity_label.dart';

void main() {
  test('isMoving returns true for transitional activities', () {
    expect(Activity.wandering.isMoving, isTrue);
    expect(Activity.seekingFood.isMoving, isTrue);
    expect(Activity.seekingHide.isMoving, isTrue);
    expect(Activity.seekingWater.isMoving, isTrue);
    expect(Activity.seekingSocial.isMoving, isTrue);
    expect(Activity.seekingEnrichment.isMoving, isTrue);
    expect(Activity.enteringHide.isMoving, isTrue);
    expect(Activity.exitingHide.isMoving, isTrue);
  });

  test('isMoving returns false for stationary activities', () {
    expect(Activity.idle.isMoving, isFalse);
    expect(Activity.hiding.isMoving, isFalse);
    expect(Activity.eating.isMoving, isFalse);
    expect(Activity.drinking.isMoving, isFalse);
    expect(Activity.interacting.isMoving, isFalse);
    expect(Activity.usingEnrichment.isMoving, isFalse);
  });

  test('ActivityLabel extension returns correct presentation strings', () {
    expect(Activity.eating.label, 'Eating');
    expect(Activity.seekingSocial.label, 'Seeking Social Interaction');
    expect(Activity.interacting.label, 'Interacting with another roach');
    expect(Activity.idle.label, 'Idle');
  });
}
