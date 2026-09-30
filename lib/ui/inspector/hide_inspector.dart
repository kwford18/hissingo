import 'package:flutter/material.dart';

import '../../environment/hide.dart';
import '../../game/terrarium_game.dart';
import 'inspector_panel.dart';

class HideInspector extends StatelessWidget {
  final TerrariumGame game;

  const HideInspector({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Listens to the selectedHide notifier and rebuilds the hide inspection UI panel
    return ValueListenableBuilder<Hide?>(
      valueListenable: game.selectedHide,
      builder: (context, selected, child) {
        if (selected == null) return const SizedBox.shrink();

        final occupants = game.roaches
            .where((r) => r.isHidden && r.targetHide == selected)
            .toList();

        return InspectorPanel(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hide Inspection',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Occupants: ${occupants.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (occupants.isEmpty)
              const Text('Empty', style: TextStyle(color: Colors.white70))
            else
              ...occupants.map(
                (r) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        game.selectedHide.value = null;
                        game.selectedRoach.value = r;
                      },
                      child: Text(
                        r.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => game.coaxRoachOut(r),
                      icon: const Icon(Icons.output, size: 18),
                      label: const Text('Coax out'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => game.selectedHide.value = null,
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
