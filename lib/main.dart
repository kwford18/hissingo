import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'terrarium_game.dart';
import 'roach.dart';

void main() {
  runApp(const HissingoApp());
}

// Flutter UI
class HissingoApp extends StatelessWidget {
  const HissingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hissingo',
      theme: ThemeData.dark(),
      home: const TerrariumScreen(),
    );
  }
}

class TerrariumScreen extends StatefulWidget {
  const TerrariumScreen({super.key});

  @override
  State<TerrariumScreen> createState() => _TerrariumScreenState();
}

class _TerrariumScreenState extends State<TerrariumScreen> {
  late final TerrariumGame game;

  @override
  void initState() {
    super.initState();
    game = TerrariumGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bridges Flutter UI and Flame
      body: Stack(
        children: [
          // The Flame game layer runs underneath the Flutter UI
          GameWidget(game: game),

          // Listens to the selectedRoach notifier and rebuilds only this UI panel
          // when a roach is tapped rather than forcing the entire screen to rebuild
          ValueListenableBuilder<Roach?>(
            valueListenable: game.selectedRoach,
            builder: (context, selected, child) {
              // Return an empty box that takes up no space if nothing is selected
              if (selected == null) return const SizedBox.shrink();

              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  padding: const EdgeInsets.all(16.0),
                  width: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xDD000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selected.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Display the 0-100 scale metrics for the active roach
                      _buildNeedRow('Happiness', selected.happiness),
                      _buildNeedRow('Hunger', selected.needs.hunger),
                      _buildNeedRow('Thirst', selected.needs.thirst),
                      _buildNeedRow('Fatigue', selected.needs.fatigue),

                      const SizedBox(height: 16),

                      // Clears the notifier value to hide the inspection panel
                      ElevatedButton(
                        onPressed: () => game.selectedRoach.value = null,
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper widget to enforce consistent spacing and typography
  // for the various data points in the inspection panel
  Widget _buildNeedRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            // Formats the raw double into a clean one-decimal string
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
