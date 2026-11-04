import 'dart:math';

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Black ground, very dim grid, and an iridescent shimmer that drifts along
/// the grid lines. Kept faint so content reads first. Stops animating when
/// the OS asks for reduced motion.
class GridBackground extends StatefulWidget {
  const GridBackground({super.key, required this.child});

  final Widget child;

  @override
  State<GridBackground> createState() => _GridBackgroundState();
}

class _GridBackgroundState extends State<GridBackground> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PPColors.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(painter: _GridPainter(_ctrl.value)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.t);

  final double t;
  static const cell = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final offset = t * cell;
    final lines = Path();
    for (var x = -cell + offset; x < size.width; x += cell) {
      lines.addRect(Rect.fromLTWH(x, 0, 1, size.height));
    }
    for (var y = -cell + offset; y < size.height; y += cell) {
      lines.addRect(Rect.fromLTWH(0, y, size.width, 1));
    }
    canvas.drawPath(lines, Paint()..color = PPColors.grid);

    // Shimmer: a slow gradient sweep painted only on the grid lines.
    final phase = t * 2 * pi;
    final shimmer = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + sin(phase), -1),
        end: Alignment(1 + sin(phase), 1),
        colors: [for (final c in PPColors.iridescent) c.withValues(alpha: 0.07)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(lines, shimmer);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.t != t;
}
