import 'dart:math' as math;

import 'package:flutter/material.dart';

class PendulumAnimationWidget extends StatefulWidget {
  final Duration beatInterval;
  final int beat;
  final bool isActive;

  const PendulumAnimationWidget({
    super.key,
    required this.beatInterval,
    required this.beat,
    this.isActive = true,
  });

  @override
  State<PendulumAnimationWidget> createState() =>
      _PendulumAnimationWidgetState();
}

class _PendulumAnimationWidgetState extends State<PendulumAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _fromAngle = -_maxAngle;
  double _toAngle = _maxAngle;

  static const double _maxAngle = 0.52;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.beatInterval,
    );
    _ctrl.value = 0;
  }

  @override
  void didUpdateWidget(PendulumAnimationWidget old) {
    super.didUpdateWidget(old);
    if (old.beatInterval != widget.beatInterval) {
      _ctrl.duration = widget.beatInterval;
    }
    if (!widget.isActive) {
      _ctrl.stop();
      return;
    }
    if (old.beat != widget.beat && widget.beat > 0) {
      _syncToBeat(widget.beat);
    }
  }

  void _syncToBeat(int beat) {
    // The sound fires at the endpoint. The bob then swings smoothly through the
    // center to the opposite endpoint for the next beat.
    _fromAngle = beat.isOdd ? -_maxAngle : _maxAngle;
    _toAngle = -_fromAngle;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isActive ? 1.0 : 0.35,
      child: SizedBox(
        width: 80,
        height: 100,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final eased = Curves.easeInOutSine.transform(_ctrl.value);
            final angle = _fromAngle + (_toAngle - _fromAngle) * eased;
            return CustomPaint(
              painter: _PendulumPainter(angle: angle),
            );
          },
        ),
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final double angle;
  const _PendulumPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, 0);
    final armLength = size.height * 0.72;
    final bobCenter = Offset(
      pivot.dx + armLength * math.sin(angle),
      pivot.dy + armLength * math.cos(angle),
    );

    // Pivot dot
    canvas.drawCircle(pivot, 4,
        Paint()..color = const Color(0xFFa5b4fc).withValues(alpha: 0.5));

    // Arm
    canvas.drawLine(
      pivot,
      bobCenter,
      Paint()
        ..color = const Color(0xFFa5b4fc).withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Bob glow
    canvas.drawCircle(
      bobCenter,
      11,
      Paint()
        ..color = const Color(0xFFa5b4fc).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Bob
    canvas.drawCircle(bobCenter, 7, Paint()..color = const Color(0xFFa5b4fc));
  }

  @override
  bool shouldRepaint(_PendulumPainter old) => old.angle != angle;
}
