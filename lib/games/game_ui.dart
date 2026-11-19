/// Éléments communs aux mini-jeux (style pixel art) : écran de jeu, compteurs,
/// décompte, fin de partie et classement.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import 'pixel.dart';

/// Page plein écran d'un mini-jeu.
class GameScaffold extends StatelessWidget {
  const GameScaffold({super.key, required this.title, required this.child, this.hud});

  final String title;
  final Widget child;
  final Widget? hud;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Palette.nightDeep,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
                  child: Row(children: [
                    IconButton(
                      tooltip: "Retour à l'accueil",
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    Expanded(child: Text(px(title), style: pixelTitle(15, color: Palette.yellow), overflow: TextOverflow.ellipsis)),
                  ]),
                ),
                if (hud != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: hud),
                Expanded(child: child),
              ]),
            ),
          ),
        ),
      );
}

/// Compteur du haut (score, temps…).
class HudChip extends StatelessWidget {
  const HudChip({super.key, required this.label, this.value = '', this.color = Palette.cyan, this.child});

  final String label;
  final String value;
  final Color color;

  /// Remplace la valeur (icônes de vies…).
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 7),
        decoration: BoxDecoration(color: Colors.black, border: Border.all(color: color, width: 3)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(px(label.toUpperCase()), style: pixelTitle(7, color: color).copyWith(shadows: const [])),
          const SizedBox(height: 5),
          SizedBox(height: 20, child: child ?? Text(value, maxLines: 1, style: pixelTitle(14, color: Colors.white))),
        ]),
      );
}

/// Décompte « 3, 2, 1, GO » affiché au-dessus du jeu.
class CountdownText extends StatelessWidget {
  const CountdownText({super.key, required this.remaining});

  /// Temps restant avant le départ, en secondes (négatif juste après le départ).
  final double remaining;

  @override
  Widget build(BuildContext context) {
    if (remaining <= -.6) return const SizedBox.shrink();
    final text = remaining > 0 ? '${remaining.ceil()}' : 'GO!';
    // Grossit par paliers, pour rester « pixel ».
    final t = remaining > 0 ? remaining - remaining.floor() : 1 + remaining / .6;
    final step = ((1 - t.clamp(0.0, 1.0)) * 4).floor();
    return IgnorePointer(
      child: Center(
        child: Text(
          text,
          style: pixelTitle(56.0 + step * 8, color: Palette.yellow).copyWith(shadows: const [
            Shadow(color: Palette.pink, offset: Offset(5, 5)),
            Shadow(color: Colors.black, offset: Offset(9, 9)),
          ]),
        ),
      ),
    );
  }
}

/// Écran de fin : score, titre obtenu, record et classement de l'équipe.
class GameOverPanel extends StatefulWidget {
  const GameOverPanel({
    super.key,
    required this.state,
    required this.game,
    required this.score,
    required this.rank,
    required this.detail,
    this.epilogue,
    required this.onReplay,
  });

  final AppState state;
  final String game;
  final int score;
  final String rank;
  final String detail;

  /// Fin de l'histoire, selon le score.
  final String? epilogue;
  final VoidCallback onReplay;

  @override
  State<GameOverPanel> createState() => _GameOverPanelState();
}

class _GameOverPanelState extends State<GameOverPanel> {
  bool _record = false;

  @override
  void initState() {
    super.initState();
    final me = widget.state.me;
    if (me != null && widget.score > 0) {
      widget.state.scores.submit(widget.game, me, widget.score).then((record) {
        if (!mounted || !record) return;
        setState(() => _record = true);
        widget.state.confetti.value++;
      }).catchError((Object _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.me;
    return Container(
      color: Colors.black.withValues(alpha: .75),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: PixelBox(
          border: Palette.pink,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('GAME OVER', style: pixelTitle(20, color: Palette.pink)),
            const SizedBox(height: 14),
            Text('${widget.score}', style: pixelTitle(40, color: Palette.yellow)),
            const SizedBox(height: 10),
            Text(px(widget.rank.toUpperCase()), textAlign: TextAlign.center, style: pixelTitle(11)),
            const SizedBox(height: 8),
            Text(widget.detail, textAlign: TextAlign.center, style: pixelBody(20, color: const Color(0xFFC9B8E6))),
            if (widget.epilogue != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4A3A68), width: 3)),
                child: Text(widget.epilogue!, textAlign: TextAlign.center, style: pixelBody(21, color: Palette.yellow)),
              ),
            ],
            if (_record) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: Palette.yellow,
                child: Text('NOUVEAU RECORD !', style: pixelTitle(10, color: Palette.night).copyWith(shadows: const [])),
              ),
            ],
            if (me == null) ...[
              const SizedBox(height: 10),
              Text("Choisis ton nom sur l'accueil pour enregistrer tes scores.", textAlign: TextAlign.center, style: pixelBody(19, color: Palette.yellow)),
            ],
            const SizedBox(height: 16),
            _Leaderboard(state: widget.state, game: widget.game),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: PixelButton(label: 'QUITTER', color: const Color(0xFF9A8CB8), onPressed: () => Navigator.of(context).maybePop())),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: PixelButton(label: 'REJOUER', autofocus: true, onPressed: widget.onReplay)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.state, required this.game});

  final AppState state;
  final String game;

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, int>>(
        stream: state.scores.watch(game),
        builder: (context, snap) {
          final entries = (snap.data ?? {}).entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Palette.cyan, width: 3)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('HIGH SCORES', textAlign: TextAlign.center, style: pixelTitle(10, color: Palette.cyan)),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                Text("Personne n'a encore joué. Premier record à prendre !", textAlign: TextAlign.center, style: pixelBody(19, color: const Color(0xFFC9B8E6))),
              for (var k = 0; k < entries.length && k < 7; k++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    SizedBox(width: 30, child: Text('${k + 1}.', style: pixelTitle(10, color: k == 0 ? Palette.yellow : Colors.white))),
                    PixelAvatar(entries[k].key, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entries[k].key.toUpperCase(),
                          overflow: TextOverflow.ellipsis, style: pixelTitle(9, color: entries[k].key == state.me ? Palette.pink : Colors.white)),
                    ),
                    Text('${entries[k].value}', style: pixelTitle(10, color: k == 0 ? Palette.yellow : Colors.white)),
                  ]),
                ),
            ]),
          );
        },
      );
}
