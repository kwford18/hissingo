import 'package:flutter/material.dart';

import '../../game/terrarium_game.dart';
import '../../roach/roach.dart';

void showAdoptRoachDialog(BuildContext context, {required TerrariumGame game}) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Adopt Roach'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Enter name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              game.adoptRoach(name);
            } else {
              game.adoptRoach('New Roach');
            }
            Navigator.pop(ctx);
          },
          child: const Text('Adopt'),
        ),
      ],
    ),
  );
}

void showRenameRoachDialog(
  BuildContext context, {
  required TerrariumGame game,
  required Roach roach,
}) {
  final controller = TextEditingController(text: roach.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rename Roach'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Enter new name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              game.renameRoach(roach, name);
            }
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void showRehomeRoachDialog(
  BuildContext context, {
  required TerrariumGame game,
  required Roach roach,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rehome Roach'),
      content: Text(
        'Are you sure you want to rehome ${roach.name}? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            game.rehomeRoach(roach);
            Navigator.pop(ctx);
          },
          child: const Text(
            'Rehome',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}
