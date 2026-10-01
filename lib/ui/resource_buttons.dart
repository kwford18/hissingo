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
          onPressed: () => game.dispenseTreat(),
          icon: const Icon(Icons.favorite),
          label: const Text('Treat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
