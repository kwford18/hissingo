import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/terrarium_save_state.dart';

/// Handles reading and writing terrarium state to local device storage.
class StorageService {
  static const String _saveKey = 'hissingo_terrarium_save';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Initializes SharedPreferences and returns a ready instance.
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  /// Serializes and writes the state to local storage.
  Future<bool> saveState(TerrariumSaveState state) async {
    final jsonStr = jsonEncode(state.toJson());
    return _prefs.setString(_saveKey, jsonStr);
  }

  // Loads and deserializes the state from local storage.
  // Returns null if no save data exists or if decoding fails.
  TerrariumSaveState? loadState() {
    final jsonStr = _prefs.getString(_saveKey);
    if (jsonStr == null) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      return TerrariumSaveState.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Clears the saved snapshot from storage.
  Future<bool> clearSave() async {
    return _prefs.remove(_saveKey);
  }
}
