/// Mini-jeu « Attrape Quentin » (pixel art) : Quentin surgit aux fenêtres de l'open space,
/// il faut le toucher pour le raccompagner à la sortie, sans toucher les collègues.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_state.dart';
import '../planning.dart';
import '../theme.dart';
import 'game_ui.dart';
import 'lore.dart';
import 'pixel.dart';
import 'score_store.dart';

enum _Kind { quentin, golden, decoy }

class _Slot {
  _Slot(this.kind, this.person, this.born, this.life);

  final _Kind kind;
  final int person;
  final double born, life;
  double? hitAt;
}

class _Floater {
  _Floater(this.slot, this.text, this.color, this.born);

  final int slot;
  final String text;
  final Color color;
  final double born;
}

enum _Phase { story, intro, countdown, playing, over }

const _red = Color(0xFFFF4D4D);

class CatchQuentinGame extends StatefulWidget {
  const CatchQuentinGame({super.key, required this.state});

  final AppState state;

  @override
  State<CatchQuentinGame> createState() => _CatchQuentinGameState();
}

class _CatchQuentinGameState extends State<CatchQuentinGame> with SingleTickerProviderStateMixin {
  static const _countdown = 3.0, _duration = 30.0, _windows = 9;

  late final Ticker _ticker = createTicker(_tick);
  final _random = Random();
  late final int _quentin = kPeople.indexWhere((p) => p.name == 'Quentin');
  late final List<int> _others = [
    for (var i = 0; i < kPeople.length; i++)
      if (i != _quentin) i,
  ];
  late final Map<int, Sprite> _sprites = {for (var i = 0; i < kPeople.length; i++) i: personSprite(kPeople[i].name)};

  _Phase _phase = _Phase.story;
  ({String speaker, String text, double born})? _radio;
  int _radioIdx = 0;
  double _t = 0; // secondes depuis le début du décompte
  List<_Slot?> _slots = List.filled(_windows, null);
  final List<_Floater> _floaters = [];
  double _nextSpawn = 0, _shakeUntil = -1, _lastGolden = -10;
  int _score = 0, _combo = 0, _caught = 0, _wrong = 0, _escaped = 0;

  double get _g => _t - _countdown; // temps de jeu

  @override
  void initState() {
    super.initState();
    // L'histoire ne s'affiche d'elle-même que la première fois.
    storySeen(Games.catchQuentin).then((seen) {
      if (seen && mounted && _phase == _Phase.story) setState(() => _phase = _Phase.intro);
    });
  }

  void _storyDone() {
    markStorySeen(Games.catchQuentin);
    setState(() => _phase = _Phase.intro);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.countdown;
      _t = 0;
      _slots = List.filled(_windows, null);
      _floaters.clear();
      _nextSpawn = .3;
      _shakeUntil = -1;
      _lastGolden = -10;
      _score = _combo = _caught = _wrong = _escaped = 0;
      _radio = null;
      _radioIdx = 0;
    });
    _ticker
      ..stop()
      ..start();
  }

  void _tick(Duration elapsed) {
    _t = elapsed.inMicroseconds / 1e6;
    if (_phase == _Phase.countdown && _t >= _countdown) _phase = _Phase.playing;
    if (_phase == _Phase.playing) {
      final g = _g;
      if (g >= _duration) {
        _phase = _Phase.over;
        _ticker.stop();
      } else {
        _update(g);
      }
    }
    _floaters.removeWhere((f) => _g - f.born > .8);
    setState(() {});
  }

  void _update(double g) {
    if (_radioIdx < kCatchRadio.length && g >= kCatchRadio[_radioIdx].$1) {
      final (_, speaker, text) = kCatchRadio[_radioIdx++];
      _radio = (speaker: speaker, text: text, born: _t);
    }
    final d = g / _duration; // difficulté 0 → 1
    for (var k = 0; k < _windows; k++) {
      final s = _slots[k];
      if (s == null) continue;
      if (s.hitAt != null) {
        if (g - s.hitAt! > .4) _slots[k] = null;
      } else if (g > s.born + s.life) {
        if (s.kind != _Kind.decoy) {
          _combo = 0;
          _escaped++;
        }
        _slots[k] = null;
      }
    }
    if (g >= _nextSpawn) {
      _spawn(g, d);
      if (d > .45 && _random.nextDouble() < .35) _spawn(g, d);
      final interval = .85 - .45 * d;
      _nextSpawn = g + interval * (.7 + _random.nextDouble() * .6);
    }
  }

  void _spawn(double g, double d) {
    final free = [for (var k = 0; k < _windows; k++) if (_slots[k] == null) k];
    if (free.isEmpty) return;
    final k = free[_random.nextInt(free.length)];
    final roll = _random.nextDouble();
    final life = 1.25 - .6 * d;
    if (roll < .08 && g - _lastGolden > 6) {
      _lastGolden = g;
      _slots[k] = _Slot(_Kind.golden, _quentin, g, life * .75);
    } else if (roll < .35 + .1 * d && _others.isNotEmpty) {
      _slots[k] = _Slot(_Kind.decoy, _others[_random.nextInt(_others.length)], g, life);
    } else {
      _slots[k] = _Slot(_Kind.quentin, _quentin, g, life);
    }
  }

  int get _multiplier => min(5, 1 + _combo ~/ 3);

  void _tap(int k) {
    if (_phase != _Phase.playing) return;
    final s = _slots[k];
    if (s == null || s.hitAt != null) return;
    final g = _g;
    s.hitAt = g;
    switch (s.kind) {
      case _Kind.quentin:
      case _Kind.golden:
        _combo++;
        _caught++;
        final pts = (s.kind == _Kind.golden ? 50 : 10) * _multiplier;
        _score += pts;
        _floaters.add(_Floater(k, s.kind == _Kind.golden ? 'JACKPOT\n+$pts' : '+$pts', Palette.yellow, g));
      case _Kind.decoy:
        _combo = 0;
        _wrong++;
        _score = max(0, _score - 15);
        _shakeUntil = g + .3;
        _floaters.add(_Floater(k, 'PAS ${kPeople[s.person].name.toUpperCase()}!\n-15', _red, g));
    }
  }

  String get _rank {
    if (_score >= 450) return 'Légende de la sortie';
    if (_score >= 250) return 'Chef de la sécurité';
    if (_score >= 100) return 'Vigile du 2e étage';
    return "Stagiaire en période d'essai";
  }

  @override
  Widget build(BuildContext context) {
    final left = (_duration - max(0, _g)).clamp(0, _duration);
    final hud = Row(children: [
      Expanded(child: HudChip(label: 'Score', value: '$_score', color: Palette.yellow)),
      const SizedBox(width: 8),
      Expanded(child: HudChip(label: 'Temps', value: '${left.ceil()}', color: Palette.cyan)),
      const SizedBox(width: 8),
      Expanded(child: HudChip(label: 'Combo', value: 'x$_multiplier', color: Palette.pink)),
    ]);

    // Secousse par pas de 4 px, pour rester dans le style.
    final shake = _g < _shakeUntil ? ((_t * 30).floor().isEven ? 4.0 : -4.0) : 0.0;

    return GameScaffold(
      title: 'ATTRAPE QUENTIN',
      hud: hud,
      child: Stack(children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Transform.translate(offset: Offset(shake, 0), child: _building()),
          ),
        ),
        if (_phase == _Phase.countdown || (_phase == _Phase.playing && _g < .6)) CountdownText(remaining: _countdown - _t),
        if (_phase == _Phase.playing && _radio != null && _t - _radio!.born < 2.8)
          LoreBanner(text: _radio!.text, speaker: _radio!.speaker),
        if (_phase == _Phase.story) StoryOverlay(title: 'ATTRAPE QUENTIN', lines: kStories[Games.catchQuentin]!, onDone: _storyDone),
        if (_phase == _Phase.intro) _intro(),
        if (_phase == _Phase.over)
          Positioned.fill(
            child: GameOverPanel(
              state: widget.state,
              game: Games.catchQuentin,
              score: _score,
              rank: _rank,
              detail: '$_caught Quentin raccompagné${_caught > 1 ? 's' : ''}, $_escaped échappé${_escaped > 1 ? 's' : ''}, '
                  '$_wrong collègue${_wrong > 1 ? 's' : ''} dérangé${_wrong > 1 ? 's' : ''} par erreur.',
              epilogue: catchEpilogue(_score),
              onReplay: _start,
            ),
          ),
      ]),
    );
  }

  Widget _building() => CustomPaint(
        painter: _FacadePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Palette.cyan, width: 3)),
              child: Text('MICHELIN ROANNE', style: pixelTitle(11, color: Palette.cyan)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                const gap = 12.0;
                final w = (c.maxWidth - 2 * gap) / 3;
                final h = min((c.maxHeight - 2 * gap) / 3, w * 1.1);
                final top0 = (c.maxHeight - (3 * h + 2 * gap)) / 2;
                return Stack(clipBehavior: Clip.none, children: [
                  for (var k = 0; k < _windows; k++)
                    Positioned(
                      left: (k % 3) * (w + gap),
                      top: top0 + (k ~/ 3) * (h + gap),
                      width: w,
                      height: h,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _tap(k),
                        child: CustomPaint(painter: _WindowPainter(_windowState(k))),
                      ),
                    ),
                  for (final f in _floaters)
                    Positioned(
                      left: (f.slot % 3) * (w + gap) - 30,
                      width: w + 60,
                      top: top0 + (f.slot ~/ 3) * (h + gap) + h * .25 - ((_g - f.born) * 10).floor() * 6,
                      child: IgnorePointer(
                        child: Text(px(f.text), textAlign: TextAlign.center, style: pixelTitle(12, color: f.color)),
                      ),
                    ),
                ]);
              }),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFF3BE37A), width: 3)),
              child: Text('SORTIE ->', style: pixelTitle(10, color: const Color(0xFF3BE37A))),
            ),
          ]),
        ),
      );

  _WindowState _windowState(int k) {
    final s = _slots[k];
    if (s == null) return const _WindowState();
    final g = _g;
    final age = g - s.born;
    final leaving = s.hitAt != null ? (g - s.hitAt!) / .4 : (age - (s.life - .15)) / .15;
    final rise = (min(1.0, age / .15) * (1 - leaving.clamp(0.0, 1.0))).clamp(0.0, 1.0);
    return _WindowState(
      sprite: _sprites[s.person],
      rise: rise,
      golden: s.kind == _Kind.golden,
      hit: s.hitAt == null ? null : (s.kind == _Kind.decoy ? _red : Palette.yellow),
    );
  }

  Widget _intro() => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: .75),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: PixelBox(
              border: Palette.cyan,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('MISSION', style: pixelTitle(12, color: Palette.cyan)),
                const SizedBox(height: 8),
                Text('SORS QUENTIN\nDE LA SIESTE', textAlign: TextAlign.center, style: pixelTitle(18)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF2A1450), border: Border.all(color: Palette.yellow, width: 3)),
                    child: const PixelAvatar('Quentin', size: 80),
                  ),
                  const SizedBox(width: 14),
                  Text('TA\nCIBLE', style: pixelTitle(14, color: Palette.yellow)),
                ]),
                const SizedBox(height: 16),
                const _Rule(color: Palette.yellow, text: 'Touche Quentin quand il apparaît : +10 points.'),
                const _Rule(color: Palette.pink, text: 'Enchaîne sans le rater : combo jusqu\'à x5.'),
                const _Rule(color: Palette.cyan, text: 'Quentin à couronne : jackpot de 50 points.'),
                const _Rule(color: _red, text: 'Ne touche pas les collègues : -15 et combo perdu.'),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: PixelButton(label: 'HISTOIRE', color: const Color(0xFF9A8CB8), onPressed: () => setState(() => _phase = _Phase.story))),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: PixelButton(label: 'JOUER  30 S', autofocus: true, onPressed: _start)),
                ]),
              ]),
            ),
          ),
        ),
      );
}

class _Rule extends StatelessWidget {
  const _Rule({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 6), child: Container(width: 8, height: 8, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: pixelBody(21))),
        ]),
      );
}

class _WindowState {
  const _WindowState({this.sprite, this.rise = 0, this.golden = false, this.hit});

  final Sprite? sprite;
  final double rise;
  final bool golden;
  final Color? hit;
}

/// Une fenêtre éclairée, avec son store, et la personne qui surgit.
class _WindowPainter extends CustomPainter {
  _WindowPainter(this.s);

  final _WindowState s;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = max(2.0, (size.width / 20).floorToDouble());
    final p = Paint()..isAntiAlias = false;
    // Cadre.
    p.color = const Color(0xFF0B0516);
    canvas.drawRect(Offset.zero & size, p);
    final inner = Rect.fromLTWH(unit, unit, size.width - 2 * unit, size.height - 2 * unit);
    // Intérieur éclairé : trois bandes de couleur.
    const bands = [Color(0xFFFFC870), Color(0xFFFF9A3C), Color(0xFFD9602A)];
    final bandH = (inner.height / 3 / unit).ceil() * unit;
    for (var b = 0; b < 3; b++) {
      p.color = bands[b];
      canvas.drawRect(Rect.fromLTWH(inner.left, inner.top + b * bandH, inner.width, min(bandH, inner.bottom - (inner.top + b * bandH))), p);
    }
    // Store vénitien en haut.
    p.color = const Color(0x55000000);
    for (var y = inner.top + unit; y < inner.top + inner.height * .35; y += unit * 2) {
      canvas.drawRect(Rect.fromLTWH(inner.left, y, inner.width, unit), p);
    }

    canvas.save();
    canvas.clipRect(inner);
    final sprite = s.sprite;
    if (sprite != null && s.rise > 0) {
      final spriteW = sprite.width * unit, spriteH = sprite.height * unit;
      final x = ((inner.center.dx - spriteW / 2) / unit).round() * unit;
      final hidden = ((1 - s.rise) * spriteH / unit).round() * unit;
      final y = inner.bottom - spriteH + hidden + unit;
      sprite.paint(canvas, Offset(x, y), unit, override: s.golden ? const {'T': Palette.yellow, 't': Color(0xFFC9A227), 'C': Color(0xFFFFF1A8)} : null);
      if (s.golden) crownSprite.paint(canvas, Offset(x + 3.5 * unit, y - 3 * unit), unit);
      if (s.hit != null) {
        // Grand X rouge (collègue) ou étoile jaune (Quentin attrapé).
        p.color = s.hit!;
        final cx = inner.center.dx, cy = inner.center.dy;
        for (var i = -3; i <= 3; i++) {
          if (s.hit == _red) {
            canvas.drawRect(Rect.fromLTWH(cx + i * unit, cy + i * unit, unit * 1.6, unit * 1.6), p);
            canvas.drawRect(Rect.fromLTWH(cx + i * unit, cy - i * unit, unit * 1.6, unit * 1.6), p);
          } else {
            canvas.drawRect(Rect.fromLTWH(cx + i * unit, cy, unit * 1.4, unit * 1.4), p);
            canvas.drawRect(Rect.fromLTWH(cx, cy + i * unit, unit * 1.4, unit * 1.4), p);
          }
        }
      }
    }
    canvas.restore();
    // Appui de fenêtre.
    p.color = const Color(0xFF6B4A8C);
    canvas.drawRect(Rect.fromLTWH(0, size.height - unit, size.width, unit), p);
  }

  @override
  bool shouldRepaint(_WindowPainter old) => true;
}

/// Façade de briques de l'immeuble.
class _FacadePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    p.color = const Color(0xFF2A1450);
    canvas.drawRect(Offset.zero & size, p);
    p.color = const Color(0xFF341A60);
    const bw = 24.0, bh = 12.0;
    for (var row = 0; row * bh < size.height; row++) {
      final off = row.isEven ? 0.0 : bw / 2;
      for (var x = -off; x < size.width; x += bw) {
        canvas.drawRect(Rect.fromLTWH(x + 2, row * bh + 2, bw - 4, bh - 4), p);
      }
    }
    p
      ..color = Palette.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRect((Offset.zero & size).deflate(2), p);
  }

  @override
  bool shouldRepaint(_FacadePainter old) => false;
}
