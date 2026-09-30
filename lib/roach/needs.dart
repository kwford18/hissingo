// Needs of a roach
class Needs {
  double hunger = 0;
  double thirst = 0;
  double fatigue = 0;
  double boredom = 50;

  double get averageNeed => (hunger + thirst + fatigue + boredom) / 4;
}
