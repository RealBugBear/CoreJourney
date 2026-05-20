import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/in_app_music_settings.dart';

/// Each entry is (assetKey, displayName).
const List<(String, String)> kInAppTracks = [
  ('sounds/music/ambient_flow.mp3', 'Ambient Flow'),
  ('sounds/music/stille_natur.mp3', 'Stille Natur'),
  ('sounds/music/tiefe_toene.mp3', 'Tiefe Töne'),
];

class InAppMusicService {
  InAppMusicService._();

  static final InAppMusicService instance = InAppMusicService._();

  final _player = AudioPlayer();
  bool _initialized = false;
  String? _currentTrack;

  String? get currentTrack => _currentTrack;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final ctx = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await _player.setAudioContext(ctx);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.7);
    } catch (error) {
      debugPrint('[InAppMusicService] init error: $error');
    }
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final track = InAppMusicSettings.selectedTrack(prefs);
    final volume = InAppMusicSettings.volume(prefs);
    if (track == null) {
      await stop();
      return;
    }
    await play(track, volume: volume);
  }

  Future<void> play(String assetKey, {double volume = 0.7}) async {
    try {
      await init();
      _currentTrack = assetKey;
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.play(AssetSource(assetKey));
    } catch (error) {
      debugPrint('[InAppMusicService] play error: $error');
    }
  }

  Future<void> stop() async {
    _currentTrack = null;
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await init();
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Temporarily lowers music volume while an announcement plays.
  /// Full implementation added in Task 3.
  Future<void> duck() async {}

  /// Restores music volume after an announcement finishes.
  /// Full implementation added in Task 3.
  Future<void> unduck() async {}

  Future<void> dispose() async {
    _initialized = false;
    _currentTrack = null;
    await _player.dispose();
  }
}
