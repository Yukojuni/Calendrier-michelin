/// Compte à rebours du départ de Quentin, avec confettis et memes.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../planning.dart';
import '../theme.dart';
import 'widgets.dart';

class QuentinInfo {
  QuentinInfo._(this.index, this.days, this.start, this.end);

  static QuentinInfo? compute() {
    final i = kPeople.indexWhere((p) => p.name == 'Quentin');
    if (i < 0) return null;
    final days = kDates.where((d) => baseCode(d, i) != '-').toList();
    if (days.isEmpty) return null;
    final s = parseIso(days.first), e = parseIso(days.last);
    return QuentinInfo._(i, days, DateTime(s.year, s.month, s.day, 9), DateTime(e.year, e.month, e.day, 18));
  }

  final int index;
  final List<String> days;
  final DateTime start, end;

  Duration get left => end.difference(DateTime.now());
  int get daysLeft => max(0, left.inDays);
  int get workDaysLeft => days.where((d) => d.compareTo(isoDate(DateTime.now())) >= 0 && baseCode(d, index) == 'E').length;
  int get percent {
    final total = end.difference(start).inSeconds;
    final done = DateTime.now().difference(start).inSeconds;
    return (done / total * 100).clamp(0, 100).round();
  }
}

class QuentinCard extends StatefulWidget {
  const QuentinCard({super.key, required this.state, required this.info});

  final AppState state;
  final QuentinInfo info;

  @override
  State<QuentinCard> createState() => _QuentinCardState();
}

class _QuentinCardState extends State<QuentinCard> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _motivate() {
    widget.state.confetti.value++;
    showDialog<void>(context: context, builder: (_) => MemeDialog(state: widget.state, info: widget.info));
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final left = info.left;
    final gone = left.isNegative;
    final dim = context.pal.muted;
    final last = DateFormat('EEEE d MMMM y').format(parseIso(info.days.last));

    Widget countdown;
    if (gone) {
      final since = (-left.inSeconds) ~/ 86400;
      countdown = Text(since > 0 ? 'Libres depuis $since jour${since > 1 ? 's' : ''}' : "C'est aujourd'hui !",
          style: display(30, color: Palette.yellow));
    } else {
      final s = left.inSeconds;
      countdown = Row(children: [
        Expanded(child: _Unit(s ~/ 86400, 'jours', hot: true)),
        const SizedBox(width: 8),
        Expanded(child: _Unit((s ~/ 3600) % 24, 'heures')),
        const SizedBox(width: 8),
        Expanded(child: _Unit((s ~/ 60) % 60, 'min')),
        const SizedBox(width: 8),
        Expanded(child: _Unit(s % 60, 'sec')),
      ]);
    }

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _motivate,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Palette.pink, Palette.orange]),
            boxShadow: [BoxShadow(color: Palette.pink.withValues(alpha: .45), blurRadius: 24)],
          ),
          child: Center(
            child: Text(gone ? 'RELANCER LA FÊTE' : 'BESOIN DE MOTIVATION ?', style: display(21, color: Palette.night)),
          ),
        ),
      ),
    );

    final track = Row(children: [
      Text('Stage', style: TextStyle(color: dim, fontSize: 12.5)),
      const SizedBox(width: 12),
      Expanded(child: _Progress(percent: info.percent)),
      const SizedBox(width: 12),
      Text('${info.percent} %', style: TextStyle(color: context.pal.ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
    ]);

    final details = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      const Eyebrow('Compte à rebours officiel', color: Palette.yellow),
      const SizedBox(height: 4),
      Text(gone ? "QUENTIN EST PARTI. C'EST LA FÊTE !" : 'DÉPART DE QUENTIN', style: display(30, color: context.pal.ink)),
      Text('Fin de stage le $last, 18 h', style: TextStyle(color: dim, fontSize: 13)),
      const SizedBox(height: 14),
      countdown,
      const SizedBox(height: 14),
      track,
      const SizedBox(height: 16),
      button,
      const SizedBox(height: 10),
      Center(child: Text("Courage, c'est bientôt fini", style: neon(24))),
    ]);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.pal.line),
        gradient: const RadialGradient(
          center: Alignment(0, -1.1),
          radius: 1.3,
          colors: [Color(0xFF3A1660), Palette.night],
        ),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final poster = _WantedPoster(info: info, last: last);
        if (c.maxWidth >= 600) {
          return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(padding: const EdgeInsets.fromLTRB(6, 6, 28, 6), child: poster),
            Expanded(child: details),
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: poster),
          const SizedBox(height: 22),
          details,
        ]);
      }),
    );
  }
}

/// Affiche « Avis de départ » façon western.
class _WantedPoster extends StatelessWidget {
  const _WantedPoster({required this.info, required this.last});

  final QuentinInfo info;
  final String last;

  static const _sepia = ColorFilter.matrix([
    0.54, 0.59, 0.15, 0, 10, //
    0.47, 0.55, 0.13, 0, 6,
    0.37, 0.43, 0.10, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final photo = kPeople[info.index].photo;
    return Transform.rotate(
      angle: -.045,
      child: Container(
        width: 250,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Palette.paper,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 36, offset: const Offset(0, 16)),
            BoxShadow(color: Palette.yellow.withValues(alpha: .12), spreadRadius: 6),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('AVIS DE DÉPART', style: display(32, color: Palette.paperInk)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Palette.paperInk, width: 4)),
            child: SizedBox(
              width: 184,
              height: 184,
              child: photo == null
                  ? const ColoredBox(color: Palette.paperInk)
                  : ColorFiltered(colorFilter: _sepia, child: Image.asset(photo, fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 8),
          Text('QUENTIN', style: display(28, color: Palette.paperInk)),
          const SizedBox(height: 2),
          Text('Stagiaire. Libération prévue le\n$last, 18 h',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Palette.paperInk, height: 1.35)),
          const SizedBox(height: 8),
          Semantics(
            label: "Niveau d'impatience de l'équipe : 4 sur 5",
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('IMPATIENCE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Palette.paperInk)),
              const SizedBox(width: 6),
              for (var k = 0; k < 5; k++)
                Icon(k < 4 ? Icons.star_rounded : Icons.star_outline_rounded, size: 17, color: const Color(0xFFC2410C)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Unit extends StatelessWidget {
  const _Unit(this.value, this.label, {this.hot = false});

  final int value;
  final String label;
  final bool hot;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: hot ? Palette.pink.withValues(alpha: .12) : Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hot ? Palette.pink : Colors.white.withValues(alpha: .18), width: 1.5),
          boxShadow: hot ? [BoxShadow(color: Palette.pink.withValues(alpha: .35), blurRadius: 16)] : null,
        ),
        child: Column(children: [
          Text(value.toString().padLeft(2, '0'),
              style: display(32, color: Colors.white).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: hot ? const Color(0xFFFFB3D6) : context.pal.muted)),
        ]),
      );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final x = c.maxWidth * percent / 100;
        return SizedBox(
          height: 26,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
            Container(height: 10, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(99))),
            Container(
              height: 10,
              width: x,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: const LinearGradient(colors: [Palette.violet, Palette.pink, Palette.yellow]),
              ),
            ),
            Positioned(left: x - 12, child: const _SpinningTire()),
          ]),
        );
      });
}

class _SpinningTire extends StatefulWidget {
  const _SpinningTire();

  @override
  State<_SpinningTire> createState() => _SpinningTireState();
}

class _SpinningTireState extends State<_SpinningTire> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _c,
        child: CustomPaint(size: const Size(24, 24), painter: TirePainter()),
      );
}

/// Petit pneu jaune et bleu nuit.
class TirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.shortestSide / 2;
    final p = Paint();
    canvas.drawCircle(c, r, p..color = const Color(0xFF0B1020));
    canvas.drawCircle(c, r * .9, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .1
      ..color = Palette.accent);
    canvas.drawCircle(c, r * .5, p..color = Palette.accent);
    final s = Paint()
      ..color = const Color(0xFF0B1020)
      ..strokeWidth = r * .16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(0, -r * .45), c.translate(0, r * .45), s);
    canvas.drawLine(c.translate(-r * .45, 0), c.translate(r * .45, 0), s);
  }

  @override
  bool shouldRepaint(TirePainter old) => false;
}

class _Meme {
  const _Meme.macro(this.top, this.bottom) : quote = null, source = null, image = null;
  const _Meme.quote(this.quote, this.source) : top = null, bottom = null, image = null;
  const _Meme.image(this.image) : top = null, bottom = null, quote = null, source = null;

  final String? top, bottom, quote, source;

  /// Image seule, sans texte.
  final String? image;
}

/// Surprises cachées : l'une d'elles sort environ 1 fois sur 8.
const _hidden = [_Meme.image('assets/memes/sam.jpg'), _Meme.image('assets/memes/vice.jpg')];

List<_Meme> _memes(QuentinInfo q) {
  final n = q.daysLeft, w = q.workDaysLeft, pct = q.percent;
  return [
    _Meme.macro('Plus que $n jours', 'On ne compte pas. Enfin si.'),
    const _Meme.macro('One does not simply', 'partir avant le 29 janvier'),
    const _Meme.macro('Quand tu vois le compte à rebours', "et que c'est ton prénom dessus"),
    const _Meme.macro("J'ai pas dit qu'on était pressés", "j'ai juste mis un compteur à la seconde"),
    const _Meme.macro('Stage : 3 mois', "Patience de l'équipe : 2 semaines"),
    _Meme.macro('Il revient lundi ?', w > 0 ? 'Oui. Encore $w fois.' : 'Non. Plus jamais.'),
    const _Meme.quote("Courage, c'est bientôt fini.", "L'équipe, solidaire"),
    _Meme.quote('Plus que $w jour${w > 1 ? 's' : ''} au bureau avec lui. Respirez.', 'Conseil bien-être'),
    const _Meme.quote('Le pot de départ est déjà budgété.', 'Le service compta, très investi'),
    _Meme.quote('Stage de Quentin : chargement… $pct %', 'Merci de ne pas fermer la page'),
    const _Meme.quote("Rappel : on l'aime bien quand même. Un peu.", 'La direction'),
    const _Meme.quote('La salle est réservée pour le 29 au soir. Juste au cas où.', 'Logistique'),
    const _Meme.quote('Chaque seconde compte. Littéralement, regardez le compteur.', 'Le compteur'),
  ];
}

class MemeDialog extends StatefulWidget {
  const MemeDialog({super.key, required this.state, required this.info});

  final AppState state;
  final QuentinInfo info;

  @override
  State<MemeDialog> createState() => _MemeDialogState();
}

class _MemeDialogState extends State<MemeDialog> {
  static int _last = -1;
  final _random = Random();
  late _Meme _meme = _pick();

  _Meme _pick() {
    if (_random.nextInt(8) == 0 && _last > -2) {
      final k = _random.nextInt(_hidden.length);
      _last = -2 - k;
      return _hidden[k];
    }
    final list = _memes(widget.info);
    int k;
    do {
      k = _random.nextInt(list.length);
    } while (k == _last && list.length > 1);
    _last = k;
    return list[k];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final photo = kPeople[widget.info.index].photo;
    final m = _meme;
    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (m.image != null)
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(m.image!, fit: BoxFit.cover))
            else if (m.quote != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(color: Palette.accent, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text(m.quote!, textAlign: TextAlign.center, style: display(26, weight: FontWeight.w800, color: Palette.accentInk)),
                  const SizedBox(height: 10),
                  Text(m.source!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Palette.accentInk.withValues(alpha: .7))),
                ]),
              )
            else
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(fit: StackFit.expand, children: [
                    if (photo != null) Image.asset(photo, fit: BoxFit.cover) else Container(color: Colors.black87),
                    Positioned(left: 8, right: 8, top: 10, child: _MemeText(m.top!)),
                    Positioned(left: 8, right: 8, bottom: 10, child: _MemeText(m.bottom!)),
                  ]),
                ),
              ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
              const SizedBox(width: 8),
              FilledButton(
                autofocus: true,
                onPressed: () {
                  widget.state.confetti.value++;
                  setState(() => _meme = _pick());
                },
                child: const Text('Encore !'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Texte de meme : capitales blanches cerclées de noir.
class _MemeText extends StatelessWidget {
  const _MemeText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.anton(fontSize: 28, height: 1.05);
    final t = text.toUpperCase();
    return Stack(children: [
      Text(t,
          textAlign: TextAlign.center,
          style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 5
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.black)),
      Text(t, textAlign: TextAlign.center, style: style.copyWith(color: Colors.white)),
    ]);
  }
}
