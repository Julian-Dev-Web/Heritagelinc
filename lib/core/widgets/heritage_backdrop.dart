import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painted backdrop for HeritageLinc's auth-flow screens.
/// Layers: gradient -> lattice -> transit routes -> heritage arches -> glow.
class HeritageBackdrop extends StatelessWidget {
  const HeritageBackdrop({
    super.key,
    required this.child,
    this.accent = const Color(0xFFE3B75E),
  });

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14625A),
            Color(0xFF0C4A46),
            Color(0xFF073431),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _HeritagePainter(accent: accent)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _HeritagePainter extends CustomPainter {
  const _HeritagePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawGlow(canvas, w, h);
    _drawLattice(canvas, w, h);
    _drawArches(canvas, w, h);
    _drawRoutes(canvas, w, h);
    _drawDust(canvas, w, h);
    _drawVignette(canvas, w, h);
  }

  // Soft halo behind the logo so it doesn't float on flat colour.
  void _drawGlow(Canvas canvas, double w, double h) {
    final rect = Rect.fromCircle(center: Offset(w * 0.5, h * 0.13), radius: w * 0.85);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.13),
            Colors.white.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  // Capiz-window diamond lattice, fading out before it reaches the buttons.
  void _drawLattice(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.075),
          Colors.white.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.62],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    const step = 34.0;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h * 0.62));

    for (double x = -h; x < w + h; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), paint);
      canvas.drawLine(Offset(x, h), Offset(x + h, 0), paint);
    }
    canvas.restore();
  }

  // Concentric arches rising from the bottom — echoes the logo's heritage arch.
  void _drawArches(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, h * 0.55, w, h * 0.45);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          accent.withValues(alpha: 0.30),
          accent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    final center = Offset(w * 0.5, h * 1.06);
    for (final r in [w * 0.34, w * 0.52, w * 0.70, w * 0.88]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  // Dashed curves with stop-nodes — the transit motif, sitting in the mid gap.
  void _drawRoutes(Canvas canvas, double w, double h) {
    final routes = <Path>[
      Path()
        ..moveTo(-w * 0.12, h * 0.575)
        ..quadraticBezierTo(w * 0.22, h * 0.635, w * 0.52, h * 0.545)
        ..quadraticBezierTo(w * 0.82, h * 0.455, w * 1.12, h * 0.520),
      Path()
        ..moveTo(-w * 0.10, h * 0.705)
        ..quadraticBezierTo(w * 0.30, h * 0.625, w * 0.60, h * 0.690)
        ..quadraticBezierTo(w * 0.88, h * 0.745, w * 1.10, h * 0.665),
    ];

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.16);

    final node = Paint()..color = accent.withValues(alpha: 0.55);
    final halo = Paint()..color = accent.withValues(alpha: 0.14);

    for (var i = 0; i < routes.length; i++) {
      canvas.drawPath(_dash(routes[i], dash: 7, gap: 8), line);

      for (final metric in routes[i].computeMetrics()) {
        for (final t in const [0.22, 0.55, 0.84]) {
          final tan = metric.getTangentForOffset(metric.length * t);
          if (tan == null) continue;
          canvas.drawCircle(tan.position, 6.5, halo);
          canvas.drawCircle(tan.position, 2.6, node);
        }
      }
    }
  }

  // Sparse specks so large flat areas aren't perfectly uniform.
  void _drawDust(Canvas canvas, double w, double h) {
    final rng = math.Random(1898); // Malolos Congress, why not
    final paint = Paint();

    for (var i = 0; i < 46; i++) {
      final dx = rng.nextDouble() * w;
      final dy = rng.nextDouble() * h * 0.78;
      paint.color = Colors.white.withValues(alpha: 0.04 + rng.nextDouble() * 0.07);
      canvas.drawCircle(Offset(dx, dy), 0.7 + rng.nextDouble() * 1.3, paint);
    }
  }

  // Darkens the base so the white Log In button reads cleanly.
  void _drawVignette(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, h * 0.62, w, h * 0.38);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF04211F).withValues(alpha: 0.35),
          ],
        ).createShader(rect),
    );
  }

  Path _dash(Path source, {required double dash, required double gap}) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      double pos = 0;
      while (pos < metric.length) {
        final end = math.min(pos + dash, metric.length);
        out.addPath(metric.extractPath(pos, end), Offset.zero);
        pos = end + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _HeritagePainter oldDelegate) =>
      oldDelegate.accent != accent;
}