// Data model capturing the events that occurred while the app was closed
class OfflineSummary {
  final Duration timeAway;
  final int giftsFound;

  OfflineSummary({required this.timeAway, required this.giftsFound});
}
