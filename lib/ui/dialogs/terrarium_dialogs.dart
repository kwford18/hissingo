import 'package:flutter/material.dart';

import '../../game/terrarium_game.dart';

// Two-step confirmation before replacing every roach with the default colony
void showResetTerrariumDialog(
  BuildContext context, {
  required TerrariumGame game,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reset Terrarium'),
      content: const Text(
        'This will remove all current roaches and replace them with the default colony. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            _showFinalConfirmationDialog(context, game: game);
          },
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}

void _showFinalConfirmationDialog(
  BuildContext context, {
  required TerrariumGame game,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Final Confirmation'),
      content: const Text(
        'Are you absolutely sure? All current roaches will be permanently removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            game.createDefaultTerrarium();
            Navigator.pop(ctx);
          },
          child: const Text(
            'Create Default',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}
