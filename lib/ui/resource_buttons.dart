import 'package:flutter/material.dart';

import '../game/terrarium_game.dart';

class ResourceButtons extends StatelessWidget {
  final TerrariumGame game;

  const ResourceButtons({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => game.dispenseFood(),
          icon: const Icon(Icons.restaurant),
          label: const Text('Food'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF689F38),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => game.dispenseWater(),
          icon: const Icon(Icons.water_drop),
          label: const Text('Water'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
