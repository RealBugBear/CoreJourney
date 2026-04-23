import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../models/exercise.dart';

class MetronomeService {
  double tempoSeconds;
  final Duration restDuration;
  final bool enableAudio;

  bool _cancelled = false;
  bool _paused = false;
  bool _isRunning = false;

  final _beatCtrl = StreamController<int>.broadcast(sync: true);
  final _repIdxCtrl = StreamController<int>.broadcast();
  final _repCompleteCtrl = StreamController<void>.broadcast();
  final _allRepsCompleteCtrl = StreamController<void>.broadcast();
  final _phaseTransitionCtrl = StreamController<void>.broadcast();

  AudioPlayer? _beatPlayer;
  AudioPlayer? _transitionPlayer;

  MetronomeService({
    this.tempoSeconds = 1.0,
    this.restDuration = const Duration(seconds: 3),
    this.enableAudio = true,
  });

  Stream<int> get beatStream => _beatCtrl.stream;
  Stream<int> get repIndexStream => _repIdxCtrl.stream;
  Stream<void> get repComplete => _repCompleteCtrl.stream;
  Stream<void> get allRepsComplete => _allRepsCompleteCtrl.stream;
  Stream<void> get phaseTransition => _phaseTransitionCtrl.stream;

  Future<void> _initAudio() async {
    if (!enableAudio) return;
    if (_beatPlayer != null) return;
    final ctx = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    _beatPlayer = AudioPlayer();
    _transitionPlayer = AudioPlayer();
    await _beatPlayer!.setAudioContext(ctx);
    await _transitionPlayer!.setAudioContext(ctx);
    await _beatPlayer!.setReleaseMode(ReleaseMode.stop);
    await _transitionPlayer!.setReleaseMode(ReleaseMode.stop);
    await _beatPlayer!.setPlayerMode(PlayerMode.lowLatency);
    await _transitionPlayer!.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> startExercise(Exercise ex) async {
    if (_isRunning) return;
    _isRunning = true;
    _cancelled = false;
    _paused = false;
    await _initAudio();
    final reps = ex.repetitions;

    for (int repIdx = 0; repIdx < reps; repIdx++) {
      if (_cancelled) {
        _isRunning = false;
        return;
      }
      _safeAdd(_repIdxCtrl, repIdx);

      if (ex.rhythmType == RhythmType.holdRest) {
        await _runHoldRestRep(ex);
      } else {
        await _runPhasedRep(ex);
      }
      if (_cancelled) {
        _isRunning = false;
        return;
      }

      _safeAdd(_repCompleteCtrl, null);
      _playTransition();

      if (repIdx < reps - 1) {
        await _sleep(restDuration);
      }
    }

    if (!_cancelled) {
      _safeAdd(_allRepsCompleteCtrl, null);
      // Yield to the event loop so broadcast listeners fire before this
      // Future completes (broadcast stream adds are asynchronous).
      await Future.delayed(Duration.zero);
    }
    _isRunning = false;
  }

  Future<void> _runHoldRestRep(Exercise ex) async {
    final beats = ex.holdSeconds;
    for (int beat = 1; beat <= beats; beat++) {
      if (_cancelled) return;
      _safeAdd(_beatCtrl, beat);
      _playBeat();
      await _sleep(Duration(milliseconds: (tempoSeconds * 1000).round()));
    }
  }

  Future<void> _runPhasedRep(Exercise ex) async {
    int beatInRep = 0;
    for (int pi = 0; pi < ex.phases.length; pi++) {
      if (_cancelled) return;
      final phase = ex.phases[pi];
      final beatsInPhase =
          (phase.durationSeconds / tempoSeconds).round().clamp(1, 99);
      for (int bi = 0; bi < beatsInPhase; bi++) {
        if (_cancelled) return;
        beatInRep++;
        _safeAdd(_beatCtrl, beatInRep);
        _playBeat();
        await _sleep(Duration(milliseconds: (tempoSeconds * 1000).round()));
      }
      // Fire event for visual/haptic feedback but no extra sound —
      // playing transition audio simultaneously with the next beat caused
      // an audible overlap (the "different sound at beat 4" issue).
      if (pi < ex.phases.length - 1 && !_cancelled) {
        _safeAdd(_phaseTransitionCtrl, null);
      }
    }
  }

  Future<void> _sleep(Duration d) async {
    if (d <= Duration.zero) return;
    final end = DateTime.now().add(d);
    while (!_cancelled) {
      while (_paused && !_cancelled) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_cancelled) return;
      final remaining = end.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      final chunk = remaining > const Duration(milliseconds: 50)
          ? const Duration(milliseconds: 50)
          : remaining;
      await Future.delayed(chunk);
    }
  }

  void _safeAdd<T>(StreamController<T> ctrl, T value) {
    if (!ctrl.isClosed) ctrl.add(value);
  }

  void _playBeat() {
    if (!enableAudio || _beatPlayer == null) return;
    _beatPlayer!
        .play(AssetSource('sounds/rhythm_arrive.wav'),
            mode: PlayerMode.lowLatency)
        .ignore();
  }

  void _playTransition() {
    if (!enableAudio || _transitionPlayer == null) return;
    _transitionPlayer!
        .play(AssetSource('sounds/rhythm_hold_end.wav'),
            mode: PlayerMode.lowLatency)
        .ignore();
  }

  Future<void> pause() async => _paused = true;
  Future<void> resume() async => _paused = false;

  Future<void> dispose() async {
    _cancelled = true;
    if (enableAudio) {
      await _beatPlayer?.dispose();
      _beatPlayer = null;
      await _transitionPlayer?.dispose();
      _transitionPlayer = null;
    }
    for (final c in [
      _beatCtrl,
      _repIdxCtrl,
      _repCompleteCtrl,
      _allRepsCompleteCtrl,
      _phaseTransitionCtrl,
    ]) {
      if (!c.isClosed) await c.close();
    }
  }
}
