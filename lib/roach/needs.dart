// Needs of a roach
class Needs {
  double hunger = 0;
  double thirst = 0;
  double fatigue = 0;
  double boredom = 50;

  // Default constructor
  Needs();

  Map<String, dynamic> toJson() => {
    'hunger': hunger,
    'thirst': thirst,
    'fatigue': fatigue,
    'boredom': boredom,
  };

  factory Needs.fromJson(Map<String, dynamic> json) {
    final needs = Needs();
    needs.hunger = (json['hunger'] as num?)?.toDouble() ?? 0.0;
    needs.thirst = (json['thirst'] as num?)?.toDouble() ?? 0.0;
    needs.fatigue = (json['fatigue'] as num?)?.toDouble() ?? 0.0;
    needs.boredom = (json['boredom'] as num?)?.toDouble() ?? 50.0;
    return needs;
  }
}
