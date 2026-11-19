/// Mini-jeu « Attrape Quentin » : Quentin surgit aux fenêtres de l'open space,
/// il faut le toucher pour le raccompagner à la sortie, sans toucher les collègues.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_state.dart';
import '../planning.dart';
import '../theme.dart';
import 'game_ui.dart';
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

enum _Phase { intro, countdown, playing, over }

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
      if (i != _quentin && kPeople[i].photo != null) i,
  ];

  _Phase _phase = _Phase.intro;
  double _t = 0; // secondes depuis le début du décompte
  List<_Slot?> _slots = List.filled(_windows, null);
  final List<_Floater> _floaters = [];
  double _nextSpawn = 0, _shakeUntil = -1, _lastGolden = -10;
  int _score = 0, _combo = 0, _caught = 0, _wrong = 0, _escaped = 0;

  double get _g => _t - _countdown; // temps de jeu

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
    final d = g / _duration; // difficulté 0 → 1
    for (var k = 0; k < _windows; k++) {
      final s = _slots[k];
      if (s == null) continue;
      if (s.hitAt != null) {
        if (g - s.hitAt! > .35) _slots[k] = null;
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
    final free = [
      for (var k = 0; k < _windows; k++)
        if (_slots[k] == null) k,
    ];
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
        _floaters.add(_Floater(k, s.kind == _Kind.golden ? 'JACKPOT +$pts' : '+$pts', Palette.yellow, g));
      case _Kind.decoy:
        _combo = 0;
        _wrong++;
        _score = max(0, _score - 15);
        _shakeUntil = g + .3;
        _floaters.add(_Floater(k, 'PAS ${kPeople[s.person].name.toUpperCase()} ! −15', const Color(0xFFFF5A5F), g));
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
    final hud = Row(
      children: [
        Expanded(
          child: HudChip(label: 'Score', value: '$_score', color: Palette.yellow),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HudChip(label: 'Temps', value: '${left.ceil()} s', color: Palette.cyan),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HudChip(label: 'Combo', value: '×$_multiplier', color: Palette.pink),
        ),
      ],
    );

    final shake = _g < _shakeUntil ? sin(_t * 90) * 6 : 0.0;

    return GameScaffold(
      title: 'ATTRAPE QUENTIN',
      hud: hud,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Transform.translate(offset: Offset(shake, 0), child: _building()),
            ),
          ),
          if (_phase == _Phase.countdown || (_phase == _Phase.playing && _g < .6)) CountdownText(remaining: _countdown - _t),
          if (_phase == _Phase.intro) _intro(),
          if (_phase == _Phase.over)
            Positioned.fill(
              child: GameOverPanel(
                state: widget.state,
                game: Games.catchQuentin,
                score: _score,
                rank: _rank,
                detail:
                    '$_caught Quentin raccompagné${_caught > 1 ? 's' : ''}, $_escaped échappé${_escaped > 1 ? 's' : ''}, '
                    '$_wrong collègue${_wrong > 1 ? 's' : ''} dérangé${_wrong > 1 ? 's' : ''} par erreur.',
                onReplay: _start,
              ),
            ),
        ],
      ),
    );
  }

  Widget _building() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A1450), Color(0xFF1A0B30)]),
      border: Border.all(color: Palette.pink.withValues(alpha: .7), width: 2),
      boxShadow: [BoxShadow(color: Palette.pink.withValues(alpha: .3), blurRadius: 30)],
    ),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    child: Column(
      children: [
        Text(
          'OPEN SPACE · 2E ÉTAGE',
          style: display(18, color: Palette.cyan).copyWith(shadows: [Shadow(color: Palette.cyan.withValues(alpha: .8), blurRadius: 12)]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              const gap = 10.0;
              final w = (c.maxWidth - 2 * gap) / 3;
              // Fenêtres presque carrées, centrées verticalement.
              final h = min((c.maxHeight - 2 * gap) / 3, w * 1.15);
              final top0 = (c.maxHeight - (3 * h + 2 * gap)) / 2;
              return Stack(
                children: [
                  for (var k = 0; k < _windows; k++)
                    Positioned(left: (k % 3) * (w + gap), top: top0 + (k ~/ 3) * (h + gap), width: w, height: h, child: _window(k)),
                  for (final f in _floaters)
                    Positioned(
                      left: (f.slot % 3) * (w + gap) - 20,
                      width: w + 40,
                      top: top0 + (f.slot ~/ 3) * (h + gap) + h * .3 - (_g - f.born) * 60,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - (_g - f.born) / .8).clamp(0.0, 1.0),
                          child: Text(
                            f.text,
                            textAlign: TextAlign.center,
                            style: display(22, color: f.color).copyWith(shadows: const [Shadow(color: Colors.black, blurRadius: 8)]),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF3BE37A), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFF3BE37A).withValues(alpha: .5), blurRadius: 14)],
          ),
          child: Text('SORTIE  →', style: display(16, color: const Color(0xFF3BE37A))),
        ),
      ],
    ),
  );

  Widget _window(int k) {
    final s = _slots[k];
    final g = _g;
    double rise = 0;
    if (s != null) {
      final age = g - s.born;
      final leaving = s.hitAt != null ? (g - s.hitAt!) / .35 : (age - (s.life - .15)) / .15;
      rise = (min(1.0, age / .15) * (1 - leaving.clamp(0.0, 1.0))).clamp(0.0, 1.0);
    }
    final golden = s?.kind == _Kind.golden;
    final hit = s?.hitAt != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _tap(k),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A2B12), Color(0xFF7A3A1C)]),
          border: Border.all(color: const Color(0xFF0B0516), width: 4),
          boxShadow: [BoxShadow(color: Palette.orange.withValues(alpha: .25), blurRadius: 12)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, c) {
              final size = min(c.maxWidth, c.maxHeight) * .8;
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Store vénitien.
                  Positioned.fill(child: CustomPaint(painter: _BlindsPainter())),
                  if (s != null)
                    Positioned(
                      bottom: -size * (1 - rise) - 4,
                      child: Opacity(
                        opacity: hit ? .6 : 1,
                        child: Container(
                          width: size,
                          height: size,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: golden ? Palette.yellow : Colors.white, width: golden ? 4 : 3),
                            boxShadow: golden ? [BoxShadow(color: Palette.yellow.withValues(alpha: .9), blurRadius: 18)] : null,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (kPeople[s.person].photo != null) Image.asset(kPeople[s.person].photo!, fit: BoxFit.cover),
                              if (hit) ColoredBox(color: (s.kind == _Kind.decoy ? const Color(0xFFFF5A5F) : Palette.yellow).withValues(alpha: .45)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (golden && !hit)
                    Positioned(
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Palette.yellow, borderRadius: BorderRadius.circular(99)),
                        child: const Text(
                          '×5',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Palette.night),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _intro() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: .7),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: Palette.night,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Palette.cyan, width: 2),
          boxShadow: [BoxShadow(color: Palette.cyan.withValues(alpha: .35), blurRadius: 40)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mission', style: neon(30)),
            Text(
              'RACCOMPAGNE QUENTIN',
              textAlign: TextAlign.center,
              style: display(30, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Palette.yellow, width: 3),
                  ),
                  child: kPeople[_quentin].photo != null ? Image.asset(kPeople[_quentin].photo!, fit: BoxFit.cover) : null,
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text('Ta cible', style: display(26, color: Palette.yellow)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _Rule(color: Palette.yellow, text: 'Touche Quentin quand il apparaît : +10 points.'),
            const _Rule(color: Palette.pink, text: 'Enchaîne sans le rater pour monter le combo, jusqu\'à ×5.'),
            const _Rule(color: Palette.cyan, text: 'Quentin doré : jackpot de 50 points.'),
            const _Rule(color: Color(0xFFFF5A5F), text: 'Ne touche pas les collègues : −15 et combo perdu.'),
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
                child: Text('JOUER · 30 SECONDES', style: display(20, color: Palette.night)),
              ),
            ),
          ],
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
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35)),
        ),
      ],
    ),
  );
}

class _BlindsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(colors: [Palette.yellow.withValues(alpha: .35), Colors.transparent])
          .createShader(Rect.fromCircle(center: size.center(Offset.zero), radius: size.longestSide * .7));
    canvas.drawRect(Offset.zero & size, glow);
    final slat = Paint()..color = Colors.black.withValues(alpha: .18);
    for (double y = 6; y < size.height * .45; y += 7) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2.5), slat);
    }
  }

  @override
  bool shouldRepaint(_BlindsPainter old) => false;
}
