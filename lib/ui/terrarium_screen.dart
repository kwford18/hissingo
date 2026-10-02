import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/terrarium_game.dart';
import 'dialogs/offline_summary_dialog.dart';
import 'dialogs/roach_dialogs.dart';
import 'dialogs/terrarium_dialogs.dart';
import 'inspector/hide_inspector.dart';
import 'inspector/roach_inspector.dart';
import 'resource_buttons.dart';
import 'terrarium_drawer.dart';
import 'terrarium_status_bar.dart';

class TerrariumScreen extends StatefulWidget {
  const TerrariumScreen({super.key});

  @override
  State<TerrariumScreen> createState() => _TerrariumScreenState();
}

// Listen to app lifecycle events
class _TerrariumScreenState extends State<TerrariumScreen>
    with WidgetsBindingObserver {
  late final TerrariumGame game;

  @override
  void initState() {
    super.initState();
    game = TerrariumGame();
    // Register the observer when the screen is created
    WidgetsBinding.instance.addObserver(this);

    // Listen for the game to complete its offline calculation
    game.offlineSummary.addListener(_onOfflineSummary);
  }

  void _onOfflineSummary() {
    final summary = game.offlineSummary.value;
    if (summary != null && mounted) {
      showOfflineSummaryDialog(context, summary);
      // Clear value to prevent retriggering
      game.offlineSummary.value = null;
    }
  }

  @override
  void dispose() {
    game.offlineSummary.removeListener(_onOfflineSummary);
    // Unregister the observer to prevent memory leaks if the screen is destroyed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatically save the terrarium state whenever the app is minimized,
    // tabbed away, or hidden
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      game.saveTerrarium();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: TerrariumDrawer(
        onCreateDefaultTerrarium: () =>
            showResetTerrariumDialog(context, game: game),
        onAdoptRoach: () => showAdoptRoachDialog(context, game: game),
        onSaveTerrarium: () {
          game.saveTerrarium();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terrarium saved locally!')),
          );
        },
        onLoadTerrarium: () {
          game.loadTerrarium();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Terrarium loaded!')));
        },
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
          Positioned(top: 16, right: 16, child: ResourceButtons(game: game)),

          TerrariumStatusBar(game: game),

          RoachInspector(game: game),
          HideInspector(game: game),
        ],
      ),
    );
  }
}
