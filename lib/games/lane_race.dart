/// Mini-jeu « Route des congés » : course sur trois voies, au coucher du soleil.
/// On esquive réunions, exams et mails du boss, on ramasse des jours de congé.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../theme.dart';
import '../ui/vice_hero.dart' show paintPalm;
import 'game_ui.dart';
import 'score_store.dart';

enum _Type { meeting, exam, boss, conge, rtt }

extension on _Type {
  bool get bad => this == _Type.meeting || this == _Type.exam || this == _Type.boss;
  String get label => switch (this) {
    _Type.meeting => 'RÉUNION',
    _Type.exam => 'EXAM',
    _Type.boss => 'MAIL DU BOSS',
    _Type.conge => 'CONGÉ',
    _Type.rtt => 'RTT',
  };
  Color get color => switch (this) {
    _Type.meeting => Palette.violet,
    _Type.exam => Palette.orange,
    _Type.boss => const Color(0xFFFF5A5F),
    _Type.conge => Palette.pink,
    _Type.rtt => Palette.cyan,
  };
}

class _Thing {
  _Thing(this.type, this.lane, this.y);

  final _Type type;
  final int lane;
  double y; // position du centre, en px depuis le haut de la route
  bool taken = false;
}

enum _Phase { intro, countdown, playing, over }

class LaneRaceGame extends StatefulWidget {
  const LaneRaceGame({super.key, required this.state});

  final AppState state;

  @override
  State<LaneRaceGame> createState() => _LaneRaceGameState();
}

class _LaneRaceGameState extends State<LaneRaceGame> with SingleTickerProviderStateMixin {
  static const _countdown = 3.0;

  late final Ticker _ticker = createTicker(_tick);
  final _random = Random();
  final _focus = FocusNode();

  _Phase _phase = _Phase.intro;
  Size _size = const Size(400, 700);
  Duration _last = Duration.zero;
  double _t = 0, _scroll = 0, _distance = 0, _sinceSpawn = 0, _speedBoost = 0;
  double _carLane = 1, _invincibleUntil = -1, _shakeUntil = -1, _flash = -1;
  int _lane = 1, _lives = 3, _conges = 0, _dodged = 0;
  bool _shield = false;
  final List<_Thing> _things = [];
  final List<({String text, Color color, double x, double y, double born})> _pops = [];

  double get _g => _t - _countdown;
  double get _unit => _size.height / 800; // échelle selon la hauteur de l'écran
  double get _speed => (300 + _speedBoost) * _unit;
  int get _score => (_distance / (10 * _unit)).floor() + _conges * 50;

  @override
  void dispose() {
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.countdown;
      _t = _scroll = _distance = _sinceSpawn = _speedBoost = 0;
      _carLane = 1;
      _lane = 1;
      _lives = 3;
      _conges = _dodged = 0;
      _shield = false;
      _invincibleUntil = _shakeUntil = _flash = -1;
      _things.clear();
      _pops.clear();
      _last = Duration.zero;
    });
    _ticker
      ..stop()
      ..start();
    _focus.requestFocus();
  }

  void _steer(int dir) {
    if (_phase != _Phase.playing && _phase != _Phase.countdown) return;
    setState(() => _lane = (_lane + dir).clamp(0, 2));
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, .05);
    _last = elapsed;
    _t = elapsed.inMicroseconds / 1e6;
    _carLane += (_lane - _carLane) * min(1, dt * 14);
    if (_phase == _Phase.countdown && _t >= _countdown) _phase = _Phase.playing;
    if (_phase == _Phase.playing) _update(dt);
    _pops.removeWhere((p) => _t - p.born > .8);
    setState(() {});
  }

  void _update(double dt) {
    _speedBoost = min(420, _speedBoost + 11 * dt);
    final move = _speed * dt;
    _scroll += move;
    _distance += move;
    _sinceSpawn += move;
    if (_sinceSpawn > (260 - min(80, _speedBoost / 6)) * _unit) {
      _sinceSpawn = 0;
      _spawnRow();
    }
    final road = _roadRect;
    final laneW = road.width / 3;
    final carRect = _carRect(road);
    for (final o in _things) {
      o.y += move;
      if (o.taken) continue;
      final r = _thingRect(o, road, laneW);
      if (r.overlaps(carRect.deflate(4))) {
        o.taken = true;
        _hit(o, r.center);
      }
    }
    _things.removeWhere((o) {
      final gone = o.y > _size.height + 80;
      if (gone && o.type.bad && !o.taken) _dodged++;
      return gone || (o.taken && !o.type.bad);
    });
  }

  void _spawnRow() {
    final lanes = [0, 1, 2]..shuffle(_random);
    final hard = _speedBoost > 150 && _random.nextDouble() < .45;
    final blocked = lanes.take(hard ? 2 : 1).toList();
    const bad = [_Type.meeting, _Type.exam, _Type.boss];
    for (final l in blocked) {
      _things.add(_Thing(bad[_random.nextInt(bad.length)], l, -60 * _unit));
    }
    final free = lanes.where((l) => !blocked.contains(l)).toList();
    if (free.isNotEmpty && _random.nextDouble() < .5) {
      final type = _random.nextDouble() < .1 ? _Type.rtt : _Type.conge;
      _things.add(_Thing(type, free[_random.nextInt(free.length)], -60 * _unit - (_random.nextBool() ? 120 * _unit : 0)));
    }
  }

  void _hit(_Thing o, Offset at) {
    switch (o.type) {
      case _Type.conge:
        _conges++;
        _pops.add((text: '+1 CONGÉ', color: Palette.pink, x: at.dx, y: at.dy, born: _t));
      case _Type.rtt:
        _shield = true;
        _pops.add((text: 'BOUCLIER RTT', color: Palette.cyan, x: at.dx, y: at.dy, born: _t));
      default:
        if (_g < _invincibleUntil) return;
        if (_shield) {
          _shield = false;
          _invincibleUntil = _g + .8;
          _pops.add((text: 'ESQUIVÉ !', color: Palette.cyan, x: at.dx, y: at.dy, born: _t));
          return;
        }
        _lives--;
        _invincibleUntil = _g + 1.3;
        _shakeUntil = _g + .35;
        _flash = _g;
        _pops.add((text: o.type.label, color: o.type.color, x: at.dx, y: at.dy, born: _t));
        if (_lives <= 0) {
          _phase = _Phase.over;
          _ticker.stop();
        }
    }
  }

  Rect get _roadRect {
    final w = min(_size.width - 24, 420.0);
    return Rect.fromLTWH((_size.width - w) / 2, 0, w, _size.height);
  }

  Rect _carRect(Rect road) {
    final laneW = road.width / 3;
    final w = laneW * .5, h = w * 1.8;
    final cx = road.left + laneW * (_carLane + .5);
    return Rect.fromCenter(center: Offset(cx, _size.height - h * .9), width: w, height: h);
  }

  Rect _thingRect(_Thing o, Rect road, double laneW) {
    final cx = road.left + laneW * (o.lane + .5);
    if (o.type.bad) return Rect.fromCenter(center: Offset(cx, o.y), width: laneW * .78, height: 56 * _unit + 10);
    final r = laneW * .2;
    return Rect.fromCircle(center: Offset(cx, o.y), radius: r);
  }

  String get _rank {
    final s = _score;
    if (s >= 3000) return 'Roi des RTT';
    if (s >= 1500) return 'Pro du pont de mai';
    if (s >= 500) return 'En route vers la plage';
    return 'Toujours coincé au bureau';
  }

  @override
  Widget build(BuildContext context) {
    final hud = Row(
      children: [
        Expanded(
          child: HudChip(label: 'Score', value: '$_score', color: Palette.yellow),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HudChip(label: 'Congés', value: '$_conges', color: Palette.pink),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            decoration: BoxDecoration(
              color: Palette.cyan.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.cyan.withValues(alpha: .6), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VIES',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF9FF2FF)),
                ),
                const SizedBox(height: 4),
                Semantics(
                  label: '$_lives vies restantes',
                  child: Row(
                    children: [
                      for (var k = 0; k < 3; k++)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Opacity(
                            opacity: k < _lives ? 1 : .2,
                            child: const Icon(Icons.trip_origin_rounded, size: 20, color: Palette.yellow),
                          ),
                        ),
                      if (_shield) const Icon(Icons.shield_rounded, size: 18, color: Palette.cyan),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final shake = _g < _shakeUntil ? sin(_t * 80) * 7 : 0.0;

    return GameScaffold(
      title: 'ROUTE DES CONGÉS',
      hud: hud,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if ((_phase == _Phase.intro || _phase == _Phase.over) && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.space)) {
            _start();
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowLeft || e.logicalKey == LogicalKeyboardKey.keyA || e.logicalKey == LogicalKeyboardKey.keyQ) {
            _steer(-1);
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowRight || e.logicalKey == LogicalKeyboardKey.keyD) {
            _steer(1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(
          builder: (context, c) {
            _size = Size(c.maxWidth, c.maxHeight);
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _steer(d.localPosition.dx < c.maxWidth / 2 ? -1 : 1),
                    onHorizontalDragEnd: (d) {
                      final v = d.primaryVelocity ?? 0;
                      if (v.abs() > 80) _steer(v < 0 ? -1 : 1);
                    },
                    child: ClipRect(
                      child: Transform.translate(
                        offset: Offset(shake, 0),
                        child: CustomPaint(
                          painter: _RacePainter(
                            scroll: _scroll,
                            road: _roadRect,
                            car: _carRect(_roadRect),
                            things: _things,
                            rect: (o) => _thingRect(o, _roadRect, _roadRect.width / 3),
                            blink: _g < _invincibleUntil && (_t * 10).floor().isEven,
                            shield: _shield,
                            flash: _flash >= 0 ? (1 - (_g - _flash) / .3).clamp(0.0, 1.0) : 0,
                            unit: _unit,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final p in _pops)
                  Positioned(
                    left: p.x - 100,
                    width: 200,
                    top: p.y - 40 - (_t - p.born) * 70,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 - (_t - p.born) / .8).clamp(0.0, 1.0),
                        child: Text(
                          p.text,
                          textAlign: TextAlign.center,
                          style: display(22, color: p.color).copyWith(shadows: const [Shadow(color: Colors.black, blurRadius: 8)]),
                        ),
                      ),
                    ),
                  ),
                if (_phase == _Phase.countdown || (_phase == _Phase.playing && _g < .6)) CountdownText(remaining: _countdown - _t),
                if (_phase == _Phase.intro) _intro(),
                if (_phase == _Phase.over)
                  Positioned.fill(
                    child: GameOverPanel(
                      state: widget.state,
                      game: Games.race,
                      score: _score,
                      rank: _rank,
                      detail:
                          '$_conges jour${_conges > 1 ? 's' : ''} de congé ramassé${_conges > 1 ? 's' : ''}, '
                          '$_dodged obstacle${_dodged > 1 ? 's' : ''} esquivé${_dodged > 1 ? 's' : ''}.',
                      onReplay: _start,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _intro() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: .7),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: Palette.night,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Palette.pink, width: 2),
            boxShadow: [BoxShadow(color: Palette.pink.withValues(alpha: .35), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Direction la plage', style: neon(28)),
              Text(
                'ROUTE DES CONGÉS',
                textAlign: TextAlign.center,
                style: display(32, color: Colors.white),
              ),
              const SizedBox(height: 14),
              for (final (type, text) in [
                (_Type.conge, 'Ramasse les jours de congé : +50 points chacun.'),
                (_Type.rtt, 'Un RTT te protège du prochain obstacle.'),
                (_Type.meeting, 'Esquive réunions, exams et mails du boss : 3 vies.'),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: type.color, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          type.label,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Palette.night),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Téléphone : touche à gauche ou à droite de l\'écran, ou glisse.\nOrdinateur : flèches ← →.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFC9B8E6), fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  autofocus: true,
                  onPressed: _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.pink,
                    foregroundColor: Palette.night,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('DÉMARRER', style: display(20, color: Palette.night)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RacePainter extends CustomPainter {
  _RacePainter({
    required this.scroll,
    required this.road,
    required this.car,
    required this.things,
    required this.rect,
    required this.blink,
    required this.shield,
    required this.flash,
    required this.unit,
  });

  final double scroll, flash, unit;
  final Rect road, car;
  final List<_Thing> things;
  final Rect Function(_Thing) rect;
  final bool blink, shield;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    // Ciel et soleil.
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A1660), Palette.night, Palette.nightDeep],
          stops: [0, .35, 1],
        ).createShader(all),
    );
    final sunR = size.width * .22;
    final sunC = Offset(size.width / 2, sunR * .55);
    canvas.drawCircle(
      sunC,
      sunR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.yellow, Palette.orange, Palette.pink],
        ).createShader(Rect.fromCircle(center: sunC, radius: sunR)),
    );
    for (var y = sunC.dy; y < sunC.dy + sunR; y += 10) {
      canvas.drawRect(Rect.fromLTWH(sunC.dx - sunR, y, sunR * 2, 3), Paint()..color = const Color(0xFF2A1250));
    }

    // Palmiers des bas-côtés, qui défilent.
    const spacing = 230.0;
    final off = scroll % (spacing * unit);
    for (var y = -spacing * unit + off; y < size.height + spacing * unit; y += spacing * unit) {
      paintPalm(canvas, Offset(road.left - 6, y + 120 * unit), 150 * unit, color: const Color(0xFF2A1450));
      paintPalm(canvas, Offset(road.right + 6, y + 120 * unit + 110 * unit), 150 * unit, mirror: true, color: const Color(0xFF2A1450));
    }

    // Route.
    canvas.drawRect(road, Paint()..color = const Color(0xFF1A0E2E));
    final edge = Paint()
      ..color = Palette.pink
      ..strokeWidth = 4;
    final edgeGlow = Paint()
      ..color = Palette.pink.withValues(alpha: .45)
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (final x in [road.left, road.right]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), edgeGlow);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), edge);
    }
    final dash = Paint()
      ..color = Palette.cyan.withValues(alpha: .8)
      ..strokeWidth = 3;
    final laneW = road.width / 3;
    final dashLen = 34 * unit, gap = 30 * unit;
    final dashOff = scroll % (dashLen + gap);
    for (var k = 1; k < 3; k++) {
      final x = road.left + laneW * k;
      for (var y = -dashLen + dashOff; y < size.height; y += dashLen + gap) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dashLen), dash);
      }
    }

    // Obstacles et bonus.
    for (final o in things) {
      if (o.taken && !o.type.bad) continue;
      final r = rect(o);
      if (o.type.bad) {
        final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
        canvas.drawRRect(rr.shift(const Offset(0, 5)), Paint()..color = Colors.black.withValues(alpha: .35));
        canvas.drawRRect(rr, Paint()..color = o.taken ? o.type.color.withValues(alpha: .4) : o.type.color);
        _label(canvas, o.type.label, r.center, r.width - 8, Palette.night, 13 * unit + 4);
      } else {
        canvas.drawCircle(
          r.center,
          r.width * .75,
          Paint()
            ..color = o.type.color.withValues(alpha: .35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        canvas.drawCircle(r.center, r.width / 2, Paint()..color = o.type.color);
        _label(canvas, o.type == _Type.conge ? 'C' : 'RTT', r.center, r.width, Palette.night, o.type == _Type.conge ? r.width * .5 : r.width * .3);
      }
    }

    // Voiture.
    if (!blink) _car(canvas);

    if (flash > 0) canvas.drawRect(all, Paint()..color = const Color(0xFFFF5A5F).withValues(alpha: .3 * flash));
  }

  void _car(Canvas canvas) {
    final r = car;
    // Phares.
    final beam = Path()
      ..moveTo(r.left + r.width * .2, r.top)
      ..lineTo(r.left - r.width * .2, r.top - r.height * 1.1)
      ..lineTo(r.right + r.width * .2, r.top - r.height * 1.1)
      ..lineTo(r.right - r.width * .2, r.top)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Palette.yellow.withValues(alpha: .35), Palette.yellow.withValues(alpha: 0)],
        ).createShader(Rect.fromLTRB(r.left, r.top - r.height * 1.1, r.right, r.top)),
    );
    if (shield) {
      canvas.drawOval(
        r.inflate(10),
        Paint()
          ..color = Palette.cyan.withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawOval(
        r.inflate(10),
        Paint()
          ..color = Palette.cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // Roues.
    final wheel = Paint()..color = Palette.nightDeep;
    for (final dy in [.22, .78]) {
      for (final left in [true, false]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(left ? r.left + 2 : r.right - 2, r.top + r.height * dy), width: r.width * .22, height: r.height * .2),
            const Radius.circular(3),
          ),
          wheel,
        );
      }
    }
    // Carrosserie.
    final body = RRect.fromRectAndRadius(r, Radius.circular(r.width * .3));
    canvas.drawRRect(
      body,
      Paint()
        ..color = Palette.pink.withValues(alpha: .5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      body,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Palette.pink, Palette.orange]).createShader(r),
    );
    // Pare-brise et lunette.
    final glass = Paint()..color = const Color(0xFF1A0B30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left + r.width * .16, r.top + r.height * .2, r.width * .68, r.height * .2), const Radius.circular(5)),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left + r.width * .2, r.top + r.height * .68, r.width * .6, r.height * .12), const Radius.circular(4)),
      glass,
    );
    // Feux.
    final head = Paint()..color = Palette.yellow;
    canvas.drawCircle(Offset(r.left + r.width * .22, r.top + 4), 3.5, head);
    canvas.drawCircle(Offset(r.right - r.width * .22, r.top + 4), 3.5, head);
    final tail = Paint()..color = const Color(0xFFFF2E4D);
    canvas.drawRect(Rect.fromLTWH(r.left + r.width * .12, r.bottom - 5, r.width * .2, 3), tail);
    canvas.drawRect(Rect.fromLTWH(r.right - r.width * .32, r.bottom - 5, r.width * .2, 3), tail);
  }

  void _label(Canvas canvas, String text, Offset center, double maxWidth, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: display(size, color: color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: max(10, maxWidth));
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_RacePainter old) => true;
}
