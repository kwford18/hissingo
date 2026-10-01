import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/sim_config.dart';
import 'terrarium_game.dart';

// Handles the visual changes associated with the day/night cycle
class LightingOverlay extends PositionComponent {
  final TerrariumGame game;
  late final Paint nightPaint;

  LightingOverlay({required this.game}) {
    priority = 200;
    nightPaint = Paint()..color = const Color(0x00000000);
  }

  @override
  void update(double dt) {
    final cycleProgress = game.dayCycleTimer / SimConfig.dayLengthSeconds;

    // Sine wave for smooth darkness transition
    final darkness = (0.5 - 0.5 * sin((cycleProgress + 0.25) * 2 * pi));
    final alpha = (darkness * 160).toInt().clamp(0, 255);

    nightPaint.color = Color.fromARGB(alpha, 0, 0, 15);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(game.boundaries, nightPaint);
  }
}
