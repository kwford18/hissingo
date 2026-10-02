import 'dart:math';
import 'dart:async';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/particles.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../config/sim_config.dart';
import '../environment/enrichment.dart';
import '../environment/food_dish.dart';
import '../environment/gift_item.dart';
import '../environment/hide.dart';
import '../environment/warm_spot.dart';
import '../environment/water_dish.dart';
import '../roach/activity.dart';
import '../roach/personality.dart';
import '../roach/roach.dart';
import '../roach/roach_component.dart';
import '../services/storage_service.dart';
import 'lighting_overlay.dart';
import 'offline_summary.dart';
import 'substrate.dart';
import 'terrarium_save_state.dart';

// Main game class for the terrarium simulation
class TerrariumGame extends FlameGame with ScaleDetector, ScrollDetector {
  // World Configuration
  final double worldWidth = 2000;
  final double worldHeight = 2000;

  late final Rect boundaries;

  // Camera Configuration
  final double minZoom = 0.5;
  final double maxZoom = 3.0;

  late double startZoom;

  // Game State
  late final World terrariumWorld;
  late final CameraComponent cam;

  final ValueNotifier<Roach?> selectedRoach = ValueNotifier(null);
  final ValueNotifier<Hide?> selectedHide = ValueNotifier(null);
  final ValueNotifier<int> collectedGifts = ValueNotifier(0);
  final ValueNotifier<OfflineSummary?> offlineSummary = ValueNotifier(null);

  final List<Roach> roaches = [];
  final List<Hide> hides = [];
  final List<EnrichmentObject> enrichments = [];

  late final FoodDish foodDish;
  late final WaterDish waterDish;

  final Random _random = Random();

  double dayCycleTimer = 0.0;
  bool get isDayTime => dayCycleTimer < (SimConfig.dayLengthSeconds / 2);

  double _giftCheckTimer = 60.0;

  StorageService? storageService;

  final List<String> _hissSounds = [
    'roach1.mp3',
    'roach2.mp3',
    'roach3.mp3',
    'roach4.mp3',
  ];

  TerrariumGame({this.storageService});

  // Methods
  @override
  Future<void> onLoad() async {
    terrariumWorld = World();
    add(terrariumWorld);

    // Pre-cache audio to prevent lag on first playback
    await FlameAudio.audioCache.loadAll(_hissSounds);

    boundaries = Rect.fromLTWH(0, 0, worldWidth, worldHeight);
    terrariumWorld.add(Substrate(width: worldWidth, height: worldHeight));

    _spawnEnvironment();

    // Check device persistence before falling back to default colony
    storageService ??= await StorageService.init();
    final savedState = storageService?.loadState();

    if (savedState != null) {
      restoreState(savedState);
    } else {
      createDefaultTerrarium();
    }

    terrariumWorld.add(LightingOverlay(game: this));

    cam = CameraComponent(world: terrariumWorld);
    final bounds = Rectangle.fromLTWH(0, 0, worldWidth, worldHeight);
    cam.setBounds(bounds);

    cam.viewfinder.zoom = 1.0;
    cam.viewfinder.position = Vector2(worldWidth / 2, worldHeight / 2);
    add(cam);
  }

  // Selection callbacks shared by every tappable component in the world
  void _selectRoach(Roach roach) {
    selectedRoach.value = roach;
    selectedHide.value = null;

    // ~20% chance to hiss when the user taps on the roach
    if (_random.nextDouble() < 0.20) {
      _playRandomHiss();
    }
  }

  void _selectHide(Hide hide) {
    selectedHide.value = hide;
    selectedRoach.value = null;
  }

  void _playRandomHiss() {
    final sound = _hissSounds[_random.nextInt(_hissSounds.length)];
    FlameAudio.play(sound, volume: 0.5);
  }

  void _spawnEnvironment() {
    final heatZone = WarmSpot(position: Vector2(1000, 1000), radius: 800);
    terrariumWorld.add(heatZone);

    final skull = PirateSkull(position: Vector2(1000, 850));
    enrichments.add(skull);
    terrariumWorld.add(skull);

    foodDish = FoodDish(position: Vector2(950, 950));
    terrariumWorld.add(foodDish);

    waterDish = WaterDish(position: Vector2(1050, 950));
    terrariumWorld.add(waterDish);

    final mainHide = Hide(
      position: Vector2(600, 600),
      size: Vector2(400, 150),
      shape: HideShape.log,
      onSelect: _selectHide,
    );
    hides.add(mainHide);
    terrariumWorld.add(mainHide);

    final stoneHide = Hide(
      position: Vector2(200, 1200),
      size: Vector2(250, 200),
      shape: HideShape.stone,
      onSelect: _selectHide,
    );
    hides.add(stoneHide);
    terrariumWorld.add(stoneHide);

    final leafHide = Hide(
      position: Vector2(1400, 400),
      size: Vector2(300, 150),
      shape: HideShape.leaf,
      onSelect: _selectHide,
    );
    hides.add(leafHide);
    terrariumWorld.add(leafHide);

    final branch = ClimbingBranch(
      position: Vector2(1300, 800),
      size: Vector2(500, 80),
    );
    enrichments.add(branch);
    terrariumWorld.add(branch);

    final slots = SlotMachine(position: Vector2(400, 300));
    enrichments.add(slots);
    terrariumWorld.add(slots);

    final gym = WorkoutArea(position: Vector2(800, 1100));
    enrichments.add(gym);
    terrariumWorld.add(gym);

    final book = Book(position: Vector2(1200, 1100));
    enrichments.add(book);
    terrariumWorld.add(book);
  }

  // Replaces the terrarium occupants with the predefined default squad
  void createDefaultTerrarium() {
    roaches.clear();
    final oldRoaches = terrariumWorld.children
        .whereType<RoachComponent>()
        .toList();
    for (final c in oldRoaches) {
      c.removeFromParent();
    }
    selectedRoach.value = null;
    selectedHide.value = null;

    _addPredefinedRoach(
      name: 'Ringo',
      personality: const Personality(
        activity: 0.8,
        appetite: 0.7,
        friendliness: 1.0,
        skittishness: 0.2,
      ),
      position: Vector2(1000, 900),
      color: const Color.fromARGB(255, 85, 36, 25),
      scale: 0.7,
    );
    _addPredefinedRoach(
      name: 'Bingo',
      personality: const Personality(
        activity: 0.5,
        appetite: 0.4,
        friendliness: 0.5,
        skittishness: 0.5,
      ),
      position: Vector2(1100, 900),
      color: const Color.fromARGB(255, 141, 110, 99),
      scale: 0.5,
    );
    _addPredefinedRoach(
      name: 'Singo',
      personality: const Personality(
        activity: 0.5,
        appetite: 0.8,
        friendliness: 0.8,
        skittishness: 0.2,
      ),
      position: Vector2(1200, 1200),
      color: const Color.fromARGB(255, 82, 14, 26),
      scale: 1.05,
    );
    _addPredefinedRoach(
      name: 'Lingo',
      personality: const Personality(
        activity: 0.3,
        appetite: 0.5,
        friendliness: 0.1,
        skittishness: 0.8,
      ),
      position: Vector2(1100, 1100),
      color: const Color.fromARGB(255, 27, 10, 5),
      scale: 0.65,
    );
  }

  void _addPredefinedRoach({
    required String name,
    required Personality personality,
    required Vector2 position,
    required Color color,
    required double scale,
  }) {
    _addRoach(
      Roach(
        id: 'roach_${DateTime.now().millisecondsSinceEpoch}_$name',
        name: name,
        position: position,
        personality: personality,
        color: color,
        scale: scale,
      ),
    );
  }

  // Spawns a roach with a randomly generated personality and appearance
  void adoptRoach(String name) {
    _addRoach(
      Roach(
        id: 'roach_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        position: Vector2(worldWidth / 2, worldHeight / 2),
        personality: Personality(
          activity: 0.3 + _random.nextDouble() * 0.4,
          appetite: 0.3 + _random.nextDouble() * 0.4,
          friendliness: 0.3 + _random.nextDouble() * 0.4,
          skittishness: 0.3 + _random.nextDouble() * 0.4,
        ),
      ),
    );
  }

  // Adds a roach to the domain layer and the game world
  void _addRoach(Roach roach) {
    roach.onHiss = _playRandomHiss;

    roaches.add(roach);
    terrariumWorld.add(RoachComponent(roach, onSelect: _selectRoach));
  }

  // Removes a roach from the domain layer and the game world
  void rehomeRoach(Roach roach) {
    roaches.remove(roach);
    final components = terrariumWorld.children
        .whereType<RoachComponent>()
        .toList();
    for (final comp in components) {
      if (comp.roach == roach) {
        comp.removeFromParent();
      }
    }
    if (selectedRoach.value == roach) {
      selectedRoach.value = null;
    }
  }

  // Renames a roach and refreshes the inspection panel to show the new name
  void renameRoach(Roach roach, String name) {
    roach.name = name;
    // Force a rebuild of the inspection panel by resetting the listener
    final current = selectedRoach.value;
    selectedRoach.value = null;
    selectedRoach.value = current;
  }

  // Coaxes a roach out of its hide and refreshes the hide inspection panel
  void coaxRoachOut(Roach roach) {
    roach.coaxOut();
    // Force UI refresh to update the occupant count
    final currentHide = selectedHide.value;
    selectedHide.value = null;
    selectedHide.value = currentHide;
  }

  // Summons roaches out of hides and towards the center dishes
  void dispenseTreat() {
    for (final roach in roaches) {
      roach.receiveTreat(
        foodDish: foodDish,
        waterDish: waterDish,
        random: _random,
      );
    }

    _spawnParticleBurst(
      Vector2(worldWidth / 2, worldHeight / 2),
      const Color.fromARGB(255, 255, 64, 129),
    );
  }

  // Scatters a gift object when a happy roach produces one
  void spawnGift({required Vector2 position}) {
    final gift = GiftItem(
      position: position,
      onCollect: (g) {
        g.removeFromParent();
        collectedGifts.value++;
      },
    );
    terrariumWorld.add(gift);

    _spawnParticleBurst(position, const Color.fromARGB(255, 255, 193, 7));
  }

  // Generates particle burst
  void _spawnParticleBurst(Vector2 position, Color color) {
    final particleComponent = ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 20,
        lifespan: 1.0,
        generator: (i) {
          return AcceleratedParticle(
            acceleration: Vector2(
              _random.nextDouble() * 200 - 100,
              _random.nextDouble() * 200 - 100,
            ),
            speed: Vector2(
              _random.nextDouble() * 100 - 50,
              _random.nextDouble() * 100 - 50,
            ),
            position: Vector2.zero(),
            child: CircleParticle(radius: 3.0, paint: Paint()..color = color),
          );
        },
      ),
    );
    terrariumWorld.add(particleComponent);
  }

  // Captures the current terrarium state and commits it to device storage
  void saveTerrarium() {
    final state = TerrariumSaveState(
      roaches: roaches,
      collectedGifts: collectedGifts.value,
      lastSavedTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
    storageService?.saveState(state);
  }

  // Restores the last captured state from storage
  void loadTerrarium() {
    final state = storageService?.loadState();
    if (state != null) {
      restoreState(state);
    }
  }

  // Wipes active simulation entities before reconstructing from saved state
  // and processes offline progression.
  void restoreState(TerrariumSaveState state) {
    roaches.clear();
    final oldRoaches = terrariumWorld.children
        .whereType<RoachComponent>()
        .toList();
    for (final c in oldRoaches) {
      c.removeFromParent();
    }

    selectedRoach.value = null;
    selectedHide.value = null;

    collectedGifts.value = state.collectedGifts;

    for (final r in state.roaches) {
      _addRoach(r);
    }

    // Offline catch up calculation
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - state.lastSavedTimestamp;

    // Only trigger if away for more than 1 minute to avoid spamming the dialog
    if (elapsedMs > 60000) {
      final elapsedSeconds = elapsedMs / 1000.0;
      int giftsFound = 0;

      for (final r in roaches) {
        // Passive need generation using simplified offline math
        r.needs.hunger =
            (r.needs.hunger + (elapsedSeconds * 0.02 * r.personality.appetite))
                .clamp(0.0, 100.0);
        r.needs.thirst =
            (r.needs.thirst + (elapsedSeconds * 0.03 * r.personality.appetite))
                .clamp(0.0, 100.0);
        r.needs.boredom = (r.needs.boredom + (elapsedSeconds * 0.05)).clamp(
          0.0,
          100.0,
        );
        r.needs.fatigue = 0; // They rested while unattended

        // Roaches only produce gifts if their needs were relatively met when they went to sleep
        bool isComfortable = r.needs.hunger < 50 && r.needs.thirst < 50;
        if (isComfortable) {
          final minutesOffline = elapsedSeconds / 60.0;
          final chance = (minutesOffline * 0.05).clamp(0.0, 1.0);
          if (_random.nextDouble() < chance) {
            giftsFound++;
          }
        }
      }

      collectedGifts.value += giftsFound;

      offlineSummary.value = OfflineSummary(
        timeAway: Duration(milliseconds: elapsedMs),
        giftsFound: giftsFound,
      );
    }
  }

  // Simulation
  @override
  void update(double dt) {
    super.update(dt);

    final scaledDt = dt * SimConfig.timeScale;

    dayCycleTimer += scaledDt;
    if (dayCycleTimer >= SimConfig.dayLengthSeconds) {
      dayCycleTimer = 0.0;
    }

    for (final roach in roaches) {
      // Create a list of all other roaches to pass to the interaction logic
      final otherRoaches = roaches.where((r) => r != roach).toList();
      roach.update(
        scaledDt,
        boundaries: boundaries,
        foodDish: foodDish,
        waterDish: waterDish,
        availableHides: hides,
        availableEnrichments: enrichments,
        otherRoaches: otherRoaches,
        isDayTime: isDayTime,
      );
    }

    _giftCheckTimer -= scaledDt;
    if (_giftCheckTimer <= 0) {
      _giftCheckTimer = 60.0;
      _evaluateGiftDrops();
    }
  }

  // Evaluates all roaches to see if they produce a gift
  void _evaluateGiftDrops() {
    for (final roach in roaches) {
      // Roaches are more likely to leave a gift if their core needs are met
      // and they are engaged in positive downtime (idle, hiding, playing, socializing)
      bool isComfortable = roach.needs.hunger < 50 && roach.needs.thirst < 50;
      bool isDowntime =
          roach.currentActivity == Activity.idle ||
          roach.currentActivity == Activity.hiding ||
          roach.currentActivity == Activity.usingEnrichment ||
          roach.currentActivity == Activity.interacting;

      if (isComfortable && isDowntime) {
        // Flat, gentle 10% chance per minute to drop a gift if they are chilling
        if (_random.nextDouble() < 0.10) {
          spawnGift(position: roach.position.clone());
        }
      }
    }
  }

  // Camera Input Handling
  @override
  void onScaleStart(ScaleStartInfo info) {
    startZoom = cam.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // Handle two-finger zooming
    final currentZoom = startZoom * info.scale.global.x;
    cam.viewfinder.zoom = currentZoom.clamp(minZoom, maxZoom);

    // Handle single-finger panning via the scale focal point delta
    cam.viewfinder.position -= info.delta.global / cam.viewfinder.zoom;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    final zoomDelta = info.scrollDelta.global.y * -0.001;
    cam.viewfinder.zoom = (cam.viewfinder.zoom + zoomDelta).clamp(
      minZoom,
      maxZoom,
    );
  }
}
