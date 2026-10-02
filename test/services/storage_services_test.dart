import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissingo/game/terrarium_save_state.dart';
import 'package:hissingo/roach/roach.dart';
import 'package:hissingo/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('StorageService saves, loads, and clears terrarium state', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await StorageService.init();

    expect(service.loadState(), isNull);

    final save = TerrariumSaveState(
      roaches: [
        Roach(id: 'test_r1', name: 'Pebble', position: Vector2(50, 100)),
      ],
      collectedGifts: 4,
      lastSavedTimestamp: 1700000000000,
    );

    final didSave = await service.saveState(save);
    expect(didSave, isTrue);

    final loaded = service.loadState();
    expect(loaded, isNotNull);
    expect(loaded!.collectedGifts, 4);
    expect(loaded.lastSavedTimestamp, 1700000000000);
    expect(loaded.roaches.length, 1);
    expect(loaded.roaches.first.id, 'test_r1');
    expect(loaded.roaches.first.name, 'Pebble');

    final didClear = await service.clearSave();
    expect(didClear, isTrue);
    expect(service.loadState(), isNull);
  });
}
