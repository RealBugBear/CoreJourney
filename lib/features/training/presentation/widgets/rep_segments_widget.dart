import 'package:flutter/material.dart';

class RepSegmentsWidget extends StatelessWidget {
  final int totalReps;
  final int completedReps; // fully done reps
  final double beatProgress; // 0.0..1.0 fill of the active rep

  const RepSegmentsWidget({
    super.key,
    required this.totalReps,
    required this.completedReps,
    this.beatProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalReps, (i) {
        final isDone = i < completedReps;
        final isActive = i == completedReps;
        return Container(
          width: (totalReps > 4) ? 20 : 28,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isDone
                ? const Color(0xFF6366f1)
                : Colors.white.withOpacity(0.1),
          ),
          child: isActive
              ? FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: beatProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: const Color(0xFF6366f1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x996366f1),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      }),
    );
  }
}
