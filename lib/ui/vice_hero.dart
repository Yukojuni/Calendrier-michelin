/// Bandeau d'accueil « Vice » : coucher de soleil, palmiers, qui est où aujourd'hui.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../planning.dart';
import '../theme.dart';
import 'overview.dart' show capitalize;
import 'widgets.dart';

class TodayHero extends StatelessWidget {
  const TodayHero({super.key, required this.state, required this.onMission});

  final AppState state;
  final VoidCallback onMission;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final day = referenceDay(state.today);
    final isToday = day == state.today;
    final work = <int>[], school = <int>[], away = <int>[];
    var ferie = false, n = 0;
    for (var i = 0; i < kPeople.length; i++) {
      final c = effectiveCode(day, i, state.overrides);
      if (c == '-') continue;
      n++;
      if (c == 'F') ferie = true;
      if (kAtWork.contains(c)) {
        work.add(i);
      } else if (kAtSchool.contains(c)) {
        school.add(i);
      } else if (kAway.contains(c)) {
        away.add(i);
      }
    }
    final date = capitalize(DateFormat('EEEE d MMMM').format(parseIso(day)));

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 760;
      final title = Column(
        crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isToday ? "Aujourd'hui" : 'Prochain jour ouvré', style: neon(wide ? 42 : 32)),
          Text(
            date.toUpperCase(),
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: display(wide ? 64 : 40, color: p.ink).copyWith(
              shadows: const [Shadow(color: Palette.nightDeep, offset: Offset(0, 3))],
            ),
          ),
        ],
      );

      final stats = Row(children: [
        Expanded(child: _Stat(value: work.length, label: 'Au bureau', color: Palette.cyan)),
        const SizedBox(width: 8),
        Expanded(child: _Stat(value: school.length, label: "À l'école", color: Palette.orange)),
        const SizedBox(width: 8),
        Expanded(child: _Stat(value: away.length, label: 'Congé · TT', color: Palette.pink)),
      ]);

      final who = Row(children: [
        SizedBox(
          height: 34,
          width: work.isEmpty ? 34 : 34 + (work.length - 1) * 24,
          child: Stack(children: [
            if (work.isEmpty) const Avatar(null, size: 34, placeholder: '–'),
            for (var k = 0; k < work.length; k++)
              Positioned(left: k * 24.0, child: Avatar(kPeople[work[k]], size: 34, ring: p.bg)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            ferie ? 'Jour férié : tout le monde se repose.' : _sentence(work, school, away, n),
            style: TextStyle(fontSize: 12.5, color: p.muted, height: 1.3),
          ),
        ),
      ]);

      final mission = _MissionButton(onTap: onMission);

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: wide ? 300 : 250,
            child: Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: SunsetPainter(sunX: wide ? .42 : .5)),
              Positioned(
                left: wide ? 32 : 12,
                right: wide ? null : 12,
                bottom: wide ? 28 : 18,
                child: title,
              ),
              if (wide)
                Positioned(
                  right: 28,
                  bottom: 28,
                  width: 380,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    stats,
                    const SizedBox(height: 12),
                    mission,
                  ]),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        if (!wide) ...[stats, const SizedBox(height: 14), who, const SizedBox(height: 14), mission] else who,
      ]);
    });
  }

  static String _sentence(List<int> work, List<int> school, List<int> away, int n) {
    String names(List<int> l) {
      final s = l.map((i) => kPeople[i].name).toList();
      if (s.length <= 1) return s.join();
      return '${s.sublist(0, s.length - 1).join(', ')} et ${s.last}';
    }

    if (work.length == n && n > 0) return "Toute l'équipe roule au bureau.";
    final parts = <String>[];
    if (school.isNotEmpty) parts.add('${names(school)} ${school.length > 1 ? 'sont' : 'est'} à l\'école');
    if (away.isNotEmpty) parts.add('${names(away)} ${away.length > 1 ? 'sont' : 'est'} en congé ou en télétravail');
    return '${parts.join(', ')}. ${work.length} au bureau.';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: .12), Palette.night),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .6), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color.lerp(color, Colors.white, .55))),
          const SizedBox(height: 2),
          Text('$value', style: display(36, color: color)),
        ]),
      );
}

class _MissionButton extends StatelessWidget {
  const _MissionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Palette.pink, Palette.orange]),
              boxShadow: [BoxShadow(color: Palette.pink.withValues(alpha: .45), blurRadius: 24)],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NOUVELLE MISSION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Palette.night.withValues(alpha: .75))),
                  Text('POSER DES CONGÉS', style: display(24, color: Palette.night)),
                ]),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Palette.night, size: 28),
            ]),
          ),
        ),
      );
}

/// Soleil rayé, palmiers en silhouette et fondu vers la nuit.
class SunsetPainter extends CustomPainter {
  SunsetPainter({this.sunX = .5});

  final double sunX;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A1660), Palette.night],
        ).createShader(Offset.zero & size),
    );
    final r = (h * .48).clamp(90.0, 170.0);
    final center = Offset(w * sunX, h * .52);
    final sunRect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.yellow, Palette.orange, Palette.pink],
          stops: [0, .45, 1],
        ).createShader(sunRect),
    );
    // Rayures du bas du soleil.
    final stripe = Paint()..color = Palette.night;
    var y = center.dy + r * .05;
    var gap = 4.0;
    while (y < h) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, gap), stripe);
      y += 12 + gap;
      gap += 1;
    }
    _palm(canvas, Offset(-10, h + 6), h * .95, false);
    _palm(canvas, Offset(w + 10, h + 6), h * .82, true);
    canvas.drawRect(
      Rect.fromLTWH(0, h * .6, w, h * .4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.night.withValues(alpha: 0), Palette.night],
        ).createShader(Rect.fromLTWH(0, h * .6, w, h * .4)),
    );
  }

  /// Palmier dessiné dans une boîte de 120×230, posé par le pied.
  void _palm(Canvas canvas, Offset foot, double height, bool mirror) {
    final s = height / 230;
    canvas.save();
    canvas.translate(foot.dx, foot.dy);
    canvas.scale(mirror ? -s : s, s);
    canvas.translate(-62, -230);
    final ink = Paint()..color = Palette.nightDeep;
    final trunk = Path()
      ..moveTo(62, 230)
      ..cubicTo(58, 170, 54, 120, 66, 70);
    canvas.drawPath(trunk, Paint()
      ..color = Palette.nightDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round);
    final fronds = Path()
      ..moveTo(66, 70)
      ..cubicTo(40, 52, 18, 58, 2, 76)
      ..cubicTo(24, 66, 44, 66, 66, 72)
      ..close()
      ..moveTo(66, 70)
      ..cubicTo(58, 40, 40, 26, 18, 24)
      ..cubicTo(40, 36, 54, 50, 64, 72)
      ..close()
      ..moveTo(66, 70)
      ..cubicTo(80, 40, 100, 30, 118, 34)
      ..cubicTo(96, 42, 80, 54, 68, 72)
      ..close()
      ..moveTo(66, 70)
      ..cubicTo(92, 62, 110, 72, 120, 92)
      ..cubicTo(100, 80, 84, 76, 68, 74)
      ..close()
      ..moveTo(66, 70)
      ..cubicTo(64, 46, 72, 22, 88, 8)
      ..cubicTo(78, 30, 72, 50, 68, 72)
      ..close();
    canvas.drawPath(fronds, ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SunsetPainter old) => old.sunX != sunX;
}
