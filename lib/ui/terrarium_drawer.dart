import 'package:flutter/material.dart';

class TerrariumDrawer extends StatelessWidget {
  final VoidCallback onCreateDefaultTerrarium;
  final VoidCallback onAdoptRoach;

  const TerrariumDrawer({
    super.key,
    required this.onCreateDefaultTerrarium,
    required this.onAdoptRoach,
  });

  // The drawer closes itself before running an action, so the actions are
  // callbacks owned by the screen. Its context outlives the drawer and can
  // safely be used to open dialogs
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromARGB(255, 62, 39, 35)),
            child: Text(
              'Terrarium Menu',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('Create Default Terrarium'),
            onTap: () {
              Navigator.pop(context);
              onCreateDefaultTerrarium();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Adopt Roach'),
            onTap: () {
              Navigator.pop(context);
              onAdoptRoach();
            },
          ),
        ],
      ),
    );
  }
}
