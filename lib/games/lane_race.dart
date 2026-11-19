/// Mini-jeu « Route des congés » (pixel art) : course sur trois voies.
/// On esquive réunions, exams et mails du boss, on ramasse des jours de congé.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../theme.dart';
import 'game_ui.dart';
import 'lore.dart';
import 'pixel.dart';
import 'score_store.dart';

enum _Type { meeting, exam, boss, conge, rtt }

const _outline = Color(0xFF0B0516);
const _paper = Color(0xFFF4F1E8);
const _ink = Color(0xFF2A2440);
const _red = Color(0xFFFF4D4D);

final Map<_Type, Sprite> _sprites = {
  _Type.meeting: const Sprite([
    '..k..........k..',
    '.kVk........kVk.',
    'oVVVVVVVVVVVVVVo',
    'oVVVVVVVVVVVVVVo',
    'oWWWWWWWWWWWWWWo',
    'oWkkWkkWkkWkkWWo',
    'oWWWWWWWWWWWWWWo',
    'oWkkWkkWkkWkkWWo',
    'oWWWWWWWWWWWWWWo',
    'oWkkWkkWRRWkkWWo',
    'oWWWWWWWRRWWWWWo',
    'oWkkWkkWkkWkkWWo',
    'oWWWWWWWWWWWWWWo',
    'oooooooooooooooo',
  ], {'o': _outline, 'k': _ink, 'V': Palette.violet, 'W': _paper, 'R': _red}),
  _Type.exam: const Sprite([
    '..oooooooooo....',
    '..oWWWWWWWWoo...',
    '..oWkkkkWWWoWo..',
    '..oWWWWWWWWoooo.',
    '..oWkkkkkkkWWWo.',
    '..oWWWWWWWWWWWo.',
    '..oWkkkkkkWWWWo.',
    '..oWWWWWWRRRRWo.',
    '..oWkkkkkRWWWWo.',
    '..oWWWWWWRRRWWo.',
    '..oWkkkkkRWWWWo.',
    '..oWWWWWWRWWWWo.',
    '..oWWWWWWWWWWWo.',
    '..ooooooooooooo.',
  ], {'o': _outline, 'k': _ink, 'W': _paper, 'R': _red}),
  _Type.boss: const Sprite([
    '............ooo.',
    '...........oRRRo',
    'oooooooooooRWRRo',
    'oWWWWWWWWWWRWRRo',
    'okWWWWWWWWWoRRo.',
    'oWkWWWWWWWWkoo..',
    'oWWkWWWWWWkWWWo.',
    'oWWWkWWWWkWWWWo.',
    'oWWWWkkkkWWWWWo.',
    'oWWWWWWWWWWWWWo.',
    'oWWWWWWWWWWWWWo.',
    'ooooooooooooooo.',
  ], {'o': _outline, 'k': _ink, 'W': Color(0xFFFFD9D9), 'R': _red}),
  _Type.conge: const Sprite([
    '...oooooo...',
    '..oPPPPPPo..',
    '.oPPgPgPPPo.',
    'oPPgggggPPPo',
    'oPgPPbPPgPPo',
    'oPPPPbPPPPPo',
    'oPPPPbPPPPPo',
    'oPPPPbPPPPPo',
    'oPPPyyyyPPPo',
    '.oPPPPPPPPo.',
    '..oPPPPPPo..',
    '...oooooo...',
  ], {'o': _outline, 'P': Palette.pink, 'g': Color(0xFF2FB67C), 'b': Color(0xFF6B3A1C), 'y': Palette.yellow}),
  _Type.rtt: const Sprite([
    'oooooooooooo',
    'oCCCCCCCCCCo',
    'oCWWCCCCWWCo',
    'oCCCCCCCCCCo',
    'oCCCCWWCCCCo',
    'oCCCCWWCCCCo',
    '.oCCCCCCCCo.',
    '.oCCCCCCCCo.',
    '..oCCCCCCo..',
    '...oCCCCo...',
    '....oooo....',
  ], {'o': _outline, 'C': Palette.cyan, 'W': Colors.white}),
};

const _palm = Sprite([
  '...g...g....',
  '..ggg.ggg...',
  '.gggggggggg.',
  'gggg.gg.gggg',
  'gg...gg...gg',
  'g....bb....g',
  '.....bb.....',
  '....bb......',
  '....bb......',
  '....bb......',
  '.....bb.....',
  '.....bb.....',
  '......bb....',
  '......bb....',
  '.....bbbb...',
], {'g': Color(0xFF3A1E66), 'b': Color(0xFF2A1450)});

const _heart = Sprite([
  '.rr.rr.',
  'rrrrrrr',
  'rrrrrrr',
  '.rrrrr.',
  '..rrr..',
  '...r...',
], {'r': _red});

/// Cabriolet vu de dessus, avec le conducteur (cheveux H, peau S).
Sprite carSprite(Look? look) => Sprite(const [
      '...oooooooooo...',
      '..oYPPPPPPPPYo..',
      '..oPPPPPPPPPPo..',
      '..oPPPPPPPPPPo..',
      '..oPGGGGGGGGPo..',
      '.woPGGGGGGGGPow.',
      '.woPPPPPPPPPPow.',
      '.woPPHHHHHHPPow.',
      '..oPPHHHHHHPPo..',
      '..oPPHSSSSHPPo..',
      '..oPPPSSSSPPPo..',
      '..oPPppppppPPo..',
      '..oPPPPPPPPPPo..',
      '.woPOOOOOOOOPow.',
      '.woPPPPPPPPPPow.',
      '.woPPPPPPPPPPow.',
      '..oRPPPPPPPPRo..',
      '...oooooooooo...',
    ], {
      'o': _outline,
      'P': Palette.pink,
      'p': const Color(0xFFB8306E),
      'O': Palette.orange,
      'G': const Color(0xFF39E5FF),
      'Y': Palette.yellow,
      'R': _red,
      'w': const Color(0xFF111111),
      'H': look?.hairColor ?? const Color(0xFF2B1D14),
      'S': look?.skin ?? const Color(0xFFF2C9A8),
    });

extension on _Type {
  bool get bad => this == _Type.meeting || this == _Type.exam || this == _Type.boss;
  String get label => switch (this) {
        _Type.meeting => 'RÉUNION',
        _Type.exam => 'EXAM',
        _Type.boss => 'MAIL BOSS',
        _Type.conge => 'CONGÉ',
        _Type.rtt => 'RTT',
      };
  Color get color => switch (this) {
        _Type.meeting => Palette.violet,
        _Type.exam => Palette.orange,
        _Type.boss => _red,
        _Type.conge => Palette.pink,
        _Type.rtt => Palette.cyan,
      };
}

class _Thing {
  _Thing(this.type, this.lane, this.y);

  final _Type type;
  final int lane;
  double y; // position du haut, en px depuis le haut de la route
  bool taken = false;
}

enum _Phase { story, intro, countdown, playing, over }

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
  late final Sprite _car = carSprite(kLooks[widget.state.me]);

  _Phase _phase = _Phase.story;
  ({String text, double born})? _sign;
  int _signIdx = 0;
  Size _size = const Size(400, 700);
  Duration _last = Duration.zero;
  double _t = 0, _scroll = 0, _distance = 0, _sinceSpawn = 0, _speedBoost = 0;
  double _carLane = 1, _invincibleUntil = -1, _shakeUntil = -1, _flash = -1;
  int _lane = 1, _lives = 3, _conges = 0, _dodged = 0;
  bool _shield = false;
  final List<_Thing> _things = [];
  final List<({String text, Color color, double x, double y, double born})> _pops = [];

  double get _g => _t - _countdown;
  Rect get _road {
    final w = min(_size.width - 24, 420.0);
    return Rect.fromLTWH(((_size.width - w) / 2).roundToDouble(), 0, w, _size.height);
  }

  /// Taille d'un pixel du jeu, en px écran.
  double get _u => max(3.0, (_road.width / 3 * .55 / 16).floorToDouble());
  double get _speed => (75 + _speedBoost / 4) * _u;
  int get _score => (_distance / (2.5 * _u)).floor() + _conges * 50;

  @override
  void initState() {
    super.initState();
    // L'histoire ne s'affiche d'elle-même que la première fois.
    storySeen(Games.race).then((seen) {
      if (seen && mounted && _phase == _Phase.story) setState(() => _phase = _Phase.intro);
    });
  }

  void _storyDone() {
    markStorySeen(Games.race);
    setState(() => _phase = _Phase.intro);
    _focus.requestFocus();
  }

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
      _sign = null;
      _signIdx = 0;
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
    _carLane += (_lane - _carLane) * min(1, dt * 16);
    if (_phase == _Phase.countdown && _t >= _countdown) _phase = _Phase.playing;
    if (_phase == _Phase.playing) _update(dt);
    _pops.removeWhere((p) => _t - p.born > .8);
    setState(() {});
  }

  void _update(double dt) {
    if (_signIdx < kRaceSigns.length && _score >= kRaceSigns[_signIdx].$1) {
      _sign = (text: kRaceSigns[_signIdx++].$2, born: _t);
    }
    _speedBoost = min(420, _speedBoost + 11 * dt);
    final move = _speed * dt;
    _scroll += move;
    _distance += move;
    _sinceSpawn += move;
    if (_sinceSpawn > (65 - min(20, _speedBoost / 24)) * _u) {
      _sinceSpawn = 0;
      _spawnRow();
    }
    final car = _carRect.deflate(_u);
    for (final o in _things) {
      o.y += move;
      if (o.taken) continue;
      final r = _thingRect(o);
      if (r.overlaps(car)) {
        o.taken = true;
        _hit(o, r.center);
      }
    }
    _things.removeWhere((o) {
      final gone = o.y > _size.height + 20;
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
      _things.add(_Thing(bad[_random.nextInt(bad.length)], l, -20 * _u));
    }
    final free = lanes.where((l) => !blocked.contains(l)).toList();
    if (free.isNotEmpty && _random.nextDouble() < .5) {
      final type = _random.nextDouble() < .1 ? _Type.rtt : _Type.conge;
      _things.add(_Thing(type, free[_random.nextInt(free.length)], -20 * _u - (_random.nextBool() ? 30 * _u : 0)));
    }
  }

  void _hit(_Thing o, Offset at) {
    switch (o.type) {
      case _Type.conge:
        _conges++;
        _pops.add((text: '+1 CONGÉ', color: Palette.pink, x: at.dx, y: at.dy, born: _t));
      case _Type.rtt:
        _shield = true;
        _pops.add((text: 'BOUCLIER', color: Palette.cyan, x: at.dx, y: at.dy, born: _t));
      default:
        if (_g < _invincibleUntil) return;
        if (_shield) {
          _shield = false;
          _invincibleUntil = _g + .8;
          _pops.add((text: 'ESQUIVÉ!', color: Palette.cyan, x: at.dx, y: at.dy, born: _t));
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

  double _laneX(double lane) => _road.left + _road.width / 3 * (lane + .5);

  Rect get _carRect {
    final u = _u;
    final w = _car.width * u, h = _car.height * u;
    final x = ((_laneX(_carLane) - w / 2) / u).round() * u;
    return Rect.fromLTWH(x, _size.height - h - 6 * u, w, h);
  }

  Rect _thingRect(_Thing o) {
    final s = _sprites[o.type]!;
    final u = _u;
    final w = s.width * u, h = s.height * u;
    return Rect.fromLTWH(((_laneX(o.lane.toDouble()) - w / 2) / u).round() * u, o.y, w, h);
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
    final hud = Row(children: [
      Expanded(child: HudChip(label: 'Score', value: '$_score', color: Palette.yellow)),
      const SizedBox(width: 8),
      Expanded(child: HudChip(label: 'Congés', value: '$_conges', color: Palette.pink)),
      const SizedBox(width: 8),
      Expanded(
        child: HudChip(
          label: 'Vies',
          color: Palette.cyan,
          child: Semantics(
            label: '$_lives vies restantes${_shield ? ', bouclier actif' : ''}',
            child: CustomPaint(painter: _LivesPainter(_lives, _shield)),
          ),
        ),
      ),
    ]);

    final shake = _g < _shakeUntil ? ((_t * 30).floor().isEven ? 4.0 : -4.0) : 0.0;

    return GameScaffold(
      title: 'ROUTE DES CONGÉS',
      hud: hud,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          if ((_phase == _Phase.intro || _phase == _Phase.over) && (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space)) {
            _start();
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA || k == LogicalKeyboardKey.keyQ) {
            _steer(-1);
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
            _steer(1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(builder: (context, c) {
          _size = Size(c.maxWidth, c.maxHeight);
          return Stack(children: [
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
                        road: _road,
                        u: _u,
                        car: _car,
                        carRect: _carRect,
                        things: [for (final o in _things) (o, _thingRect(o))],
                        blink: _g < _invincibleUntil && (_t * 10).floor().isEven,
                        shield: _shield,
                        flash: _flash >= 0 && _g - _flash < .3,
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
                top: p.y - 30 - ((_t - p.born) * 10).floor() * 6,
                child: IgnorePointer(child: Text(px(p.text), textAlign: TextAlign.center, style: pixelTitle(12, color: p.color))),
              ),
            if (_phase == _Phase.countdown || (_phase == _Phase.playing && _g < .6)) CountdownText(remaining: _countdown - _t),
            if (_phase == _Phase.playing && _sign != null && _t - _sign!.born < 2.6) LoreBanner(text: _sign!.text, sign: true),
            if (_phase == _Phase.story) StoryOverlay(title: 'ROUTE DES CONGÉS', lines: kStories[Games.race]!, onDone: _storyDone),
            if (_phase == _Phase.intro) _intro(),
            if (_phase == _Phase.over)
              Positioned.fill(
                child: GameOverPanel(
                  state: widget.state,
                  game: Games.race,
                  score: _score,
                  rank: _rank,
                  detail: '$_conges jour${_conges > 1 ? 's' : ''} de congé ramassé${_conges > 1 ? 's' : ''}, '
                      '$_dodged obstacle${_dodged > 1 ? 's' : ''} esquivé${_dodged > 1 ? 's' : ''}.',
                  epilogue: raceEpilogue(_score),
                  onReplay: _start,
                ),
              ),
          ]);
        }),
      ),
    );
  }

  Widget _intro() => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: .75),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: PixelBox(
              border: Palette.pink,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('DIRECTION LA PLAGE', textAlign: TextAlign.center, style: pixelTitle(10, color: Palette.cyan)),
                const SizedBox(height: 8),
                Text('ROUTE DES\nCONGES', textAlign: TextAlign.center, style: pixelTitle(18)),
                const SizedBox(height: 14),
                SizedBox(width: 64, height: 72, child: CustomPaint(painter: _SpriteBox(_car))),
                const SizedBox(height: 12),
                for (final (type, text) in [
                  (_Type.conge, 'Ramasse les jours de congé : +50 chacun.'),
                  (_Type.rtt, 'Un RTT te protège du prochain obstacle.'),
                  (_Type.meeting, 'Esquive réunions, exams et mails du boss.'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      SizedBox(width: 32, height: 32, child: CustomPaint(painter: _SpriteBox(_sprites[type]!))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(text, style: pixelBody(21))),
                    ]),
                  ),
                const SizedBox(height: 6),
                Text("Téléphone : touche à gauche ou à droite.\nOrdinateur : flèches gauche / droite.",
                    textAlign: TextAlign.center, style: pixelBody(19, color: const Color(0xFFC9B8E6))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: PixelButton(label: 'HISTOIRE', color: const Color(0xFF9A8CB8), onPressed: () => setState(() => _phase = _Phase.story))),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: PixelButton(label: 'DÉMARRER', autofocus: true, onPressed: _start)),
                ]),
              ]),
            ),
          ),
        ),
      );
}

/// Dessine un sprite centré dans sa boîte, au plus grand pixel entier possible.
class _SpriteBox extends CustomPainter {
  _SpriteBox(this.sprite);

  final Sprite sprite;

  @override
  void paint(Canvas canvas, Size size) {
    final u = max(1.0, min(size.width / sprite.width, size.height / sprite.height).floorToDouble());
    sprite.paint(canvas, Offset(((size.width - sprite.width * u) / 2).roundToDouble(), ((size.height - sprite.height * u) / 2).roundToDouble()), u);
  }

  @override
  bool shouldRepaint(_SpriteBox old) => old.sprite != sprite;
}

class _LivesPainter extends CustomPainter {
  _LivesPainter(this.lives, this.shield);

  final int lives;
  final bool shield;

  @override
  void paint(Canvas canvas, Size size) {
    for (var k = 0; k < 3; k++) {
      _heart.paint(canvas, Offset(k * 18.0, 2), 2.4, opacity: k < lives ? 1 : .2);
    }
    if (shield) _sprites[_Type.rtt]!.paint(canvas, const Offset(56, 0), 1.7);
  }

  @override
  bool shouldRepaint(_LivesPainter old) => old.lives != lives || old.shield != shield;
}

class _RacePainter extends CustomPainter {
  _RacePainter({
    required this.scroll,
    required this.road,
    required this.u,
    required this.car,
    required this.carRect,
    required this.things,
    required this.blink,
    required this.shield,
    required this.flash,
  });

  final double scroll, u;
  final Rect road, carRect;
  final Sprite car;
  final List<(_Thing, Rect)> things;
  final bool blink, shield, flash;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    // Bas-côtés et palmiers.
    p.color = const Color(0xFF12081F);
    canvas.drawRect(Offset.zero & size, p);
    final spacing = 60 * u;
    final off = (scroll % spacing / u).floor() * u;
    for (var y = -spacing + off; y < size.height + spacing; y += spacing) {
      _palm.paint(canvas, Offset(road.left - _palm.width * u - u, y), u);
      _palm.paint(canvas, Offset(road.right + u, y + spacing / 2), u);
    }

    // Route.
    p.color = const Color(0xFF221436);
    canvas.drawRect(road, p);
    p.color = Palette.pink;
    canvas.drawRect(Rect.fromLTWH(road.left, 0, u, size.height), p);
    canvas.drawRect(Rect.fromLTWH(road.right - u, 0, u, size.height), p);
    p.color = Palette.cyan;
    final dash = 8 * u, gap = 8 * u;
    final dashOff = (scroll % (dash + gap) / u).floor() * u;
    for (var k = 1; k < 3; k++) {
      final x = ((road.left + road.width / 3 * k) / u).round() * u - u / 2;
      for (var y = -dash + dashOff; y < size.height; y += dash + gap) {
        canvas.drawRect(Rect.fromLTWH(x, y, u, dash), p);
      }
    }

    // Obstacles et bonus.
    for (final (o, r) in things) {
      if (o.taken && !o.type.bad) continue;
      final y = (r.top / u).round() * u;
      _sprites[o.type]!.paint(canvas, Offset(r.left, y), u, opacity: o.taken ? .35 : 1);
    }

    // Voiture.
    if (!blink) {
      if (shield) {
        p.color = Palette.cyan.withValues(alpha: .35);
        canvas.drawRect(carRect.inflate(2 * u), p);
      }
      car.paint(canvas, carRect.topLeft, u);
    }

    if (flash) {
      p.color = _red.withValues(alpha: .3);
      canvas.drawRect(Offset.zero & size, p);
    }
  }

  @override
  bool shouldRepaint(_RacePainter old) => true;
}
