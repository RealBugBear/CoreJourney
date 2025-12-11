import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider für SharedPreferences Instanz
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Theme Provider - Verwaltet das aktuelle Theme der App
/// 
/// Speichert die Nutzer-Präferenz in SharedPreferences und
/// lädt sie beim App-Start automatisch.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Lädt gespeicherte Theme-Präferenz
  void _loadThemeMode() {
    final savedThemeIndex = _prefs.getInt(_themeModeKey);
    if (savedThemeIndex != null && savedThemeIndex < ThemeMode.values.length) {
      state = ThemeMode.values[savedThemeIndex];
    }
  }

  /// Setzt neues Theme und speichert die Präferenz
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setInt(_themeModeKey, mode.index);
  }

  /// Setzt Theme auf Light
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Setzt Theme auf Dark
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Setzt Theme auf System (folgt System-Einstellungen)
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
}

/// Provider für Theme Management
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  
  return prefs.when(
    data: (sharedPrefs) => ThemeNotifier(sharedPrefs),
    loading: () => ThemeNotifier(
      // Fallback während SharedPreferences lädt
      _SyncSharedPreferences(),
    ),
    error: (_, __) => ThemeNotifier(
      _SyncSharedPreferences(),
    ),
  );
});

/// Synchrone Fallback-Implementierung für SharedPreferences
/// Wird nur verwendet wenn die async-Initialisierung noch läuft
class _SyncSharedPreferences implements SharedPreferences {
  final Map<String, dynamic> _cache = {};

  @override
  Future<bool> clear() async {
    _cache.clear();
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  bool containsKey(String key) => _cache.containsKey(key);

  @override
  Object? get(String key) => _cache[key];

  @override
  bool? getBool(String key) => _cache[key] as bool?;

  @override
  double? getDouble(String key) => _cache[key] as double?;

  @override
  int? getInt(String key) => _cache[key] as int?;

  @override
  Set<String> getKeys() => _cache.keys.toSet();

  @override
  String? getString(String key) => _cache[key] as String?;

  @override
  List<String>? getStringList(String key) => _cache[key] as List<String>?;

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async {
    _cache.remove(key);
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _cache[key] = value;
    return true;
  }
}
