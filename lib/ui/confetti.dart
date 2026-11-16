/// Pluie de confettis (avec quelques pneus), déclenchée par un compteur.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({super.key, required this.trigger});

  final ValueNotifier<int> trigger;

  @override
  State<ConfettiLayer> createState() => _ConfettiLayerState();
}

class _Particle {
  _Particle(Random r, Size s)
      : x = s.width / 2 + (r.nextDouble() - .5) * 120,
        y = s.height * .45,
        vx = (r.nextDouble() - .5) * 16,
        vy = -r.nextDouble() * 16 - 6,
        rot = r.nextDouble() * pi,
        vr = (r.nextDouble() - .5) * .4,
        w = 6 + r.nextDouble() * 6,
        h = 8 + r.nextDouble() * 8,
        color = _colors[r.nextInt(_colors.length)],
        tire = r.nextDouble() < .08;

  static const _colors = [
    Color(0xFFFCE500), Color(0xFF2FB67C), Color(0xFFA996F2), Color(0xFFF29BB8), Color(0xFFC9D8F2), Color(0xFFF7C66B),
  ];
  double x, y, vx, vy, rot, vr;
  final double w, h;
  final Color color;
  final bool tire;

  void step() {
    vy += .45;
    vx *= .99;
    x += vx;
    y += vy;
    rot += vr;
  }
}

class _ConfettiLayerState extends State<ConfettiLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  List<_Particle> _parts = [];
  Duration _start = Duration.zero;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_burst);
  }

  void _burst() {
    if (MediaQuery.of(context).disableAnimations) return;
    final size = MediaQuery.of(context).size;
    setState(() => _parts = [..._parts, for (var i = 0; i < 160; i++) _Particle(_random, size)]);
    _start = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    if (_start == Duration.zero) _start = elapsed;
    for (final p in _parts) {
      p.step();
    }
    if (elapsed - _start > const Duration(milliseconds: 3200)) {
      _ticker.stop();
      _parts = [];
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_burst);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _parts.isEmpty ? const SizedBox.shrink() : CustomPaint(painter: _ConfettiPainter(_parts), size: Size.infinite);
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.parts);

  final List<_Particle> parts;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in parts) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      if (p.tire) {
        canvas.drawCircle(Offset.zero, 9, paint..color = const Color(0xFF101A33));
        canvas.drawCircle(Offset.zero, 4.5, paint..color = const Color(0xFFFCE500));
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h), paint..color = p.color);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
