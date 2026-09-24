import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'terrarium_game.dart';

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
      body: GameWidget(game: game),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement UI interaction
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
