import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../presentation/services/in_app_music_service.dart';

class AudioAnnouncementService {
  AudioAnnouncementService._();

  static final AudioAnnouncementService instance =
      AudioAnnouncementService._();

  AudioPlayer? _player;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    _player = AudioPlayer();
    final ctx = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    await _player!.setAudioContext(ctx);
    await _player!.setReleaseMode(ReleaseMode.stop);
  }

  /// Plays a single asset key (relative to assets/, e.g.
  /// 'sounds/announcements/de/wechsel.mp3').
  /// Ducks music while playing, then restores it.
  Future<void> play(String assetKey) async {
    try {
      await _init();
      await InAppMusicService.instance.duck();
      await _player!.play(AssetSource(assetKey));
      await _player!.onPlayerComplete.first;
    } catch (e) {
      debugPrint('[AudioAnnouncementService] play error: $e');
    } finally {
      await InAppMusicService.instance.unduck();
    }
  }

  /// Plays a sequence of asset keys one after another.
  Future<void> queue(List<String> assetKeys) async {
    for (final key in assetKeys) {
      await play(key);
    }
  }

  void stop() {
    _player?.stop();
    InAppMusicService.instance.unduck();
  }

  Future<void> dispose() async {
    _initialized = false;
    await _player?.dispose();
    _player = null;
  }
}
