import 'package:flutter/material.dart';

import '../game/terrarium_game.dart';

class TerrariumStatusBar extends StatelessWidget {
  final TerrariumGame game;

  const TerrariumStatusBar({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: const Color.fromARGB(221, 0, 0, 0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.card_giftcard,
                  size: 16,
                  color: const Color.fromARGB(255, 251, 192, 45),
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder<int>(
                  valueListenable: game.collectedGifts,
                  builder: (context, gifts, child) {
                    return Text(
                      gifts.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
