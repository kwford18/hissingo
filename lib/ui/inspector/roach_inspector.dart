import 'package:flutter/material.dart';

import '../../game/terrarium_game.dart';
import '../../roach/roach.dart';
import '../activity_label.dart';
import '../dialogs/roach_dialogs.dart';
import 'inspector_panel.dart';
import 'need_row.dart';

class RoachInspector extends StatelessWidget {
  final TerrariumGame game;

  const RoachInspector({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Listens to the selectedRoach notifier and rebuilds the roach inspection UI panel
    return ValueListenableBuilder<Roach?>(
      valueListenable: game.selectedRoach,
      builder: (context, selected, child) {
        // Return an empty box that takes up no space if nothing is selected
        if (selected == null) return const SizedBox.shrink();

        return InspectorPanel(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => showRenameRoachDialog(
                        context,
                        game: game,
                        roach: selected,
                      ),
                      tooltip: 'Rename',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.home,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => showRehomeRoachDialog(
                        context,
                        game: game,
                        roach: selected,
                      ),
                      tooltip: 'Rehome',
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'State: ${selected.currentActivity.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Display the internal need states for the active roach
            NeedRow(label: 'Hunger', value: selected.needs.hunger),
            NeedRow(label: 'Thirst', value: selected.needs.thirst),
            NeedRow(label: 'Fatigue', value: selected.needs.fatigue),
            const SizedBox(height: 16),
            // Clears the notifier value to hide the inspection panel
            ElevatedButton(
              onPressed: () => game.selectedRoach.value = null,
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
