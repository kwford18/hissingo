import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/terrarium_game.dart';
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
      drawer: TerrariumDrawer(
        onCreateDefaultTerrarium: () =>
            showResetTerrariumDialog(context, game: game),
        onAdoptRoach: () => showAdoptRoachDialog(context, game: game),
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
