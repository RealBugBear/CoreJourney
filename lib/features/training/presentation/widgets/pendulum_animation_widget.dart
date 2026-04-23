import 'package:flutter/material.dart';

class PendulumAnimationWidget extends StatefulWidget {
  final Duration beatInterval;
  final bool isActive;

  const PendulumAnimationWidget({
    super.key,
    required this.beatInterval,
    this.isActive = true,
  });

  @override
  State<PendulumAnimationWidget> createState() =>
      _PendulumAnimationWidgetState();
}

class _PendulumAnimationWidgetState extends State<PendulumAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _angle; // radians, -0.45 to 0.45

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.beatInterval * 2, // full swing = 2 beats
    );
    _angle = Tween<double>(begin: -0.45, end: 0.45).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PendulumAnimationWidget old) {
    super.didUpdateWidget(old);
    if (old.beatInterval != widget.beatInterval) {
      _ctrl.duration = widget.beatInterval * 2;
    }
    if (widget.isActive && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive && _ctrl.isAnimating) {
      _ctrl.stop();
    }
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
          animation: _angle,
          builder: (context, _) => CustomPaint(
            painter: _PendulumPainter(angle: _angle.value),
          ),
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
      pivot.dx + armLength * angle,
      pivot.dy + armLength * (1 - angle.abs() * 0.05),
    );

    // Pivot dot
    canvas.drawCircle(pivot, 4,
        Paint()..color = const Color(0xFFa5b4fc).withOpacity(0.5));

    // Arm
    canvas.drawLine(
      pivot,
      bobCenter,
      Paint()
        ..color = const Color(0xFFa5b4fc).withOpacity(0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Bob glow
    canvas.drawCircle(
      bobCenter, 11,
      Paint()
        ..color = const Color(0xFFa5b4fc).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Bob
    canvas.drawCircle(bobCenter, 7, Paint()..color = const Color(0xFFa5b4fc));
  }

  @override
  bool shouldRepaint(_PendulumPainter old) => old.angle != angle;
}
