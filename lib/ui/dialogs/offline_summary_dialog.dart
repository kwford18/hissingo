import 'package:flutter/material.dart';

import '../../game/offline_summary.dart';

// Presents a cute summary of what happened while the terrarium was unattended
void showOfflineSummaryDialog(BuildContext context, OfflineSummary summary) {
  final hours = summary.timeAway.inHours;
  final minutes = summary.timeAway.inMinutes.remainder(60);

  String timeString = '';
  if (hours > 0) {
    timeString += '$hours hour${hours == 1 ? '' : 's'} ';
  }
  if (minutes > 0 || hours == 0) {
    timeString += '$minutes minute${minutes == 1 ? '' : 's'}';
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('While You Were Away...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You were gone for $timeString.'),
          const SizedBox(height: 12),
          const Text(
            'Your roaches took a long nap. They are well rested, but might be a bit hungry and thirsty!',
          ),
          const SizedBox(height: 12),
          if (summary.giftsFound > 0)
            Text(
              'They found ${summary.giftsFound} gift${summary.giftsFound == 1 ? '' : 's'} for you!',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            )
          else
            const Text('They didn\'t find any gifts this time.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Welcome back!'),
        ),
      ],
    ),
  );
}
