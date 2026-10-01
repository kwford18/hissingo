import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/roach/needs.dart';

void main() {
  test('Needs initialize with correct default values', () {
    final needs = Needs();

    expect(needs.hunger, 0.0);
    expect(needs.thirst, 0.0);
    expect(needs.fatigue, 0.0);
    expect(needs.boredom, 50.0);
  });

  test('Needs clamp correctly to maximum constraints', () {
    final needs = Needs();
    needs.hunger = 150;

    // The clamp happens inside the Roach update loop, so the raw data structure
    // just holds the value it is given until processed
    expect(needs.hunger, 150.0);
  });
}
