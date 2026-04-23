// lib/features/training/presentation/widgets/exercise_transition_widget.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/exercise.dart';

class ExerciseTransitionWidget extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;     // 0-based
  final int totalExercises;
  final bool isRoutineMode;
  final int transitionDurationSeconds; // countdown length for routine
  final String locale;         // 'de' or 'en'
  final VoidCallback onStart;

  const ExerciseTransitionWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.isRoutineMode,
    required this.transitionDurationSeconds,
    required this.locale,
    required this.onStart,
  });

  @override
  State<ExerciseTransitionWidget> createState() =>
      _ExerciseTransitionWidgetState();
}

class _ExerciseTransitionWidgetState extends State<ExerciseTransitionWidget> {
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isRoutineMode) {
      _countdown = widget.transitionDurationSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _countdown--);
        if (_countdown <= 0) {
          _timer?.cancel();
          widget.onStart();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNow() {
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final loc = widget.locale;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Exercise image
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            ex.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.white.withOpacity(0.05),
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined,
                  color: Colors.white38, size: 40),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Übung ${widget.exerciseIndex + 1} von ${widget.totalExercises}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 0.12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ex.title(loc),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip('${ex.repetitions}× Wdh.'),
                    _chip('${ex.holdSeconds} Sek / Rep'),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionLabel('Position'),
                ...ex.positionInstructions(loc).map(_bullet),
                const SizedBox(height: 10),
                _sectionLabel('Bewegung'),
                ...ex.movementInstructions(loc).map(_bullet),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF6366f1).withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '"${ex.executionGuide(loc)}"',
                    style: const TextStyle(
                      color: Color(0xFFa5b4fc),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: widget.isRoutineMode
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Startet in $_countdown s',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                    FilledButton(
                      onPressed: _startNow,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366f1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Jetzt starten'),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _startNow,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Übung starten',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
        ),
      ],
    );

    if (widget.isRoutineMode) {
      return GestureDetector(
        onTap: _startNow,
        child: Container(
          color: const Color(0xFF0a0a12),
          child: content,
        ),
      );
    }
    return Container(
      color: const Color(0xFF0f0f18),
      child: content,
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF6366f1).withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: const Color(0xFF6366f1).withOpacity(0.3), width: 1),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFFa5b4fc),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
                letterSpacing: 0.12,
                fontWeight: FontWeight.w700)),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF6366f1)),
            ),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 13)),
            ),
          ],
        ),
      );
}
