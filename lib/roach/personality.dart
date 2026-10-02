// Personality traits for a roach
class Personality {
  final double activity;
  final double appetite;
  final double friendliness;
  final double skittishness;

  const Personality({
    this.activity = 0.5,
    this.appetite = 0.5,
    this.friendliness = 0.5,
    this.skittishness = 0.5,
  });

  Map<String, dynamic> toJson() => {
    'activity': activity,
    'appetite': appetite,
    'friendliness': friendliness,
    'skittishness': skittishness,
  };

  factory Personality.fromJson(Map<String, dynamic> json) {
    return Personality(
      activity: (json['activity'] as num?)?.toDouble() ?? 0.5,
      appetite: (json['appetite'] as num?)?.toDouble() ?? 0.5,
      friendliness: (json['friendliness'] as num?)?.toDouble() ?? 0.5,
      skittishness: (json['skittishness'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
