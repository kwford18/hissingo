import 'package:flutter/material.dart';
import 'package:flame/game.dart';

void main() {
  runApp(const HisserApp());
}

// Flutter UI
class HisserApp extends StatelessWidget {
  const HisserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hisser',
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
      // Flutter UI and Flame
      body: GameWidget(game: game),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add future functionality
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Flame
class TerrariumGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // TODO: Create fixed-size world, responsive camera, and substrate
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Simulation state logic (Needs, Time, Environment) will run here
  }
}
