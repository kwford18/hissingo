import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'terrarium_game.dart';
import 'roach.dart';
import 'environment.dart';

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
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF3E2723)),
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
                _showDefaultTerrariumConfirmDialog1(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Adopt Roach'),
              onTap: () {
                Navigator.pop(context);
                _showAdoptDialog(context);
              },
            ),
          ],
        ),
      ),
      // Bridges Flutter UI and Flame
      body: Stack(
        children: [
          // The Flame game layer runs underneath the Flutter UI
          GameWidget(game: game),

          // Menu button
          Positioned(
            top: 16,
            left: 16,
            child: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, size: 32),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),

          // Resource dispensing buttons
          Positioned(
            top: 16,
            right: 16,
            child: Column(
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
            ),
          ),

          // Listens to the selectedRoach notifier and rebuilds the roach inspection UI panel
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
                  width: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xDD000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                                onPressed: () =>
                                    _showRenameDialog(context, selected),
                                tooltip: 'Rename',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.home,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    _showRehomeConfirmDialog(context, selected),
                                tooltip: 'Rehome',
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'State: ${_formatActivity(selected.currentActivity)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
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

          // Listens to the selectedHide notifier and rebuilds the hide inspection UI panel
          ValueListenableBuilder<Hide?>(
            valueListenable: game.selectedHide,
            builder: (context, selected, child) {
              if (selected == null) return const SizedBox.shrink();

              final occupants = game.roaches
                  .where((r) => r.isHidden && r.targetHide == selected)
                  .toList();

              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  padding: const EdgeInsets.all(16.0),
                  width: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xDD000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Hide Inspection',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Occupants: ${occupants.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (occupants.isEmpty)
                        const Text(
                          'Empty',
                          style: TextStyle(color: Colors.white70),
                        )
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
                                onPressed: () {
                                  r.coaxOut();
                                  // Force UI refresh to update the occupant count
                                  final currentHide = game.selectedHide.value;
                                  game.selectedHide.value = null;
                                  game.selectedHide.value = currentHide;
                                },
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
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Translates enum values into a clean readable format for the UI
  String _formatActivity(Activity a) {
    switch (a) {
      case Activity.idle:
        return 'Idle';
      case Activity.wandering:
        return 'Wandering';
      case Activity.seekingFood:
        return 'Seeking Food';
      case Activity.eating:
        return 'Eating';
      case Activity.seekingWater:
        return 'Seeking Water';
      case Activity.drinking:
        return 'Drinking';
      case Activity.seekingHide:
        return 'Seeking Hide';
      case Activity.enteringHide:
        return 'Entering Hide';
      case Activity.hiding:
        return 'Hiding';
      case Activity.exitingHide:
        return 'Exiting Hide';
    }
  }

  void _showAdoptDialog(BuildContext context) {
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

  void _showRenameDialog(BuildContext context, Roach roach) {
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
                roach.name = name;

                // Force a rebuild of the inspection panel by resetting the listener
                final current = game.selectedRoach.value;
                game.selectedRoach.value = null;
                game.selectedRoach.value = current;
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRehomeConfirmDialog(BuildContext context, Roach roach) {
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

  void _showDefaultTerrariumConfirmDialog1(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx1) => AlertDialog(
        title: const Text('Reset Terrarium'),
        content: const Text(
          'This will remove all current roaches and replace them with the default colony. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx1),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx1);
              _showDefaultTerrariumConfirmDialog2(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showDefaultTerrariumConfirmDialog2(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx2) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Are you absolutely sure? All current roaches will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              game.createDefaultTerrarium();
              Navigator.pop(ctx2);
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
