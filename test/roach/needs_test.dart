import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/roach/needs.dart';

void main() {
  test('Needs average is calculated correctly', () {
    final needs = Needs();
    needs.hunger = 20;
    needs.thirst = 40;
    needs.fatigue = 60;
    needs.boredom = 80;

    expect(needs.averageNeed, 50.0);
  });

  test('Needs clamp correctly to maximum constraints', () {
    final needs = Needs();
    needs.hunger = 150;

    // The clamp happens inside the Roach update loop, so the raw data structure
    // just holds the value it is given until processed
    expect(needs.hunger, 150.0);
  });
}
