import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// 會閃爍的星空、月亮和飛過的蝙蝠，用在首頁頂端。
class NightSky extends StatefulWidget {
  const NightSky({super.key, required this.child});

  final Widget child;

  @override
  State<NightSky> createState() => _NightSkyState();
}

class _NightSkyState extends State<NightSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          CustomPaint(painter: _SkyPainter(_controller.value), child: child),
      child: widget.child,
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.t);

  final double t;
  static final _stars = List.generate(40, (i) {
    final r = Random(i * 7919);
    return (
      r.nextDouble(),
      r.nextDouble(),
      r.nextDouble() * 1.6 + 0.6,
      r.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A0F4A), Spooky.night],
        ).createShader(rect),
    );

    for (final (x, y, radius, phase) in _stars) {
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin((t + phase) * 2 * pi * 3));
      canvas.drawCircle(
        Offset(x * size.width, y * size.height * 0.85),
        radius,
        Paint()..color = Colors.white.withValues(alpha: twinkle * 0.8),
      );
    }

    final moonCenter = Offset(size.width * 0.66, size.height * 0.3);
    final moonRadius = size.shortestSide * 0.16;
    canvas.drawCircle(
      moonCenter,
      moonRadius * 1.9,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Spooky.moon.withValues(alpha: 0.35),
                Spooky.moon.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: moonCenter, radius: moonRadius * 1.9),
            ),
    );
    canvas.drawCircle(moonCenter, moonRadius, Paint()..color = Spooky.moon);
    final crater = Paint()..color = const Color(0xFFEBD9A6);
    canvas.drawCircle(
      moonCenter + Offset(-moonRadius * 0.3, -moonRadius * 0.2),
      moonRadius * 0.18,
      crater,
    );
    canvas.drawCircle(
      moonCenter + Offset(moonRadius * 0.35, moonRadius * 0.3),
      moonRadius * 0.24,
      crater,
    );

    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final x = -40 + (size.width + 80) * p;
      final y = size.height * (0.18 + 0.12 * i) + sin(p * 2 * pi * 2 + i) * 14;
      _drawBat(canvas, Offset(x, y), 10.0 + i * 3, sin(p * 2 * pi * 10));
    }
  }

  void _drawBat(Canvas canvas, Offset c, double s, double flap) {
    final lift = flap * s * 0.45;
    final path = Path()
      ..moveTo(c.dx, c.dy + s * 0.2)
      ..quadraticBezierTo(
        c.dx - s * 0.6,
        c.dy - s * 0.4 - lift,
        c.dx - s * 1.4,
        c.dy - lift,
      )
      ..quadraticBezierTo(
        c.dx - s * 0.8,
        c.dy + s * 0.05,
        c.dx - s * 0.5,
        c.dy + s * 0.35,
      )
      ..quadraticBezierTo(
        c.dx - s * 0.25,
        c.dy + s * 0.1,
        c.dx,
        c.dy + s * 0.45,
      )
      ..quadraticBezierTo(
        c.dx + s * 0.25,
        c.dy + s * 0.1,
        c.dx + s * 0.5,
        c.dy + s * 0.35,
      )
      ..quadraticBezierTo(
        c.dx + s * 0.8,
        c.dy + s * 0.05,
        c.dx + s * 1.4,
        c.dy - lift,
      )
      ..quadraticBezierTo(
        c.dx + s * 0.6,
        c.dy - s * 0.4 - lift,
        c.dx,
        c.dy + s * 0.2,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF07020F));
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) => oldDelegate.t != t;
}
