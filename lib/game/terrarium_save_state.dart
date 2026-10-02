import '../roach/roach.dart';

// Root state object for saving and loading the entire terrarium snapshot
class TerrariumSaveState {
  final List<Roach> roaches;
  final int collectedGifts;
  final int lastSavedTimestamp;

  TerrariumSaveState({
    required this.roaches,
    required this.collectedGifts,
    required this.lastSavedTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'roaches': roaches.map((r) => r.toJson()).toList(),
    'collectedGifts': collectedGifts,
    'lastSavedTimestamp': lastSavedTimestamp,
  };

  factory TerrariumSaveState.fromJson(Map<String, dynamic> json) {
    final roachesList = json['roaches'] as List<dynamic>? ?? [];
    return TerrariumSaveState(
      roaches: roachesList
          .map((r) => Roach.fromJson(r as Map<String, dynamic>))
          .toList(),
      collectedGifts: json['collectedGifts'] as int? ?? 0,
      lastSavedTimestamp:
          json['lastSavedTimestamp'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}
