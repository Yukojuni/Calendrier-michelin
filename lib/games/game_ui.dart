/// Éléments communs aux mini-jeux : écran de jeu, décompte, fin de partie et classement.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../planning.dart';
import '../theme.dart';
import '../ui/widgets.dart';

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: "Retour à l'accueil",
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: display(24, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (hud != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: hud),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Pastille d'information du haut (score, temps…).
class HudChip extends StatelessWidget {
  const HudChip({super.key, required this.label, required this.value, this.color = Palette.cyan});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .6), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color.lerp(color, Colors.white, .5)),
        ),
        Text(
          value,
          style: display(24, color: color).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    ),
  );
}

/// Décompte « 3, 2, 1, GO » affiché au-dessus du jeu.
class CountdownText extends StatelessWidget {
  const CountdownText({super.key, required this.remaining});

  /// Temps restant avant le départ, en secondes (peut être négatif juste après le départ).
  final double remaining;

  @override
  Widget build(BuildContext context) {
    if (remaining <= -.6) return const SizedBox.shrink();
    final text = remaining > 0 ? '${remaining.ceil()}' : 'GO !';
    final t = remaining > 0 ? remaining - remaining.floor() : 1 + remaining / .6;
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 + (1 - t.clamp(0.0, 1.0)) * .6,
            child: Text(
              text,
              style: display(96, color: Palette.yellow).copyWith(
                shadows: [
                  Shadow(color: Palette.pink.withValues(alpha: .9), blurRadius: 24),
                  const Shadow(color: Colors.black, offset: Offset(0, 4)),
                ],
              ),
            ),
          ),
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
    required this.onReplay,
  });

  final AppState state;
  final String game;
  final int score;
  final String rank;
  final String detail;
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
      widget.state.scores
          .submit(widget.game, me, widget.score)
          .then((record) {
            if (!mounted || !record) return;
            setState(() => _record = true);
            widget.state.confetti.value++;
          })
          .catchError((Object _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.me;
    return Container(
      color: Colors.black.withValues(alpha: .72),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: Palette.night,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Palette.pink, width: 2),
            boxShadow: [BoxShadow(color: Palette.pink.withValues(alpha: .4), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fin de partie', style: neon(30, color: Palette.pink)),
              const SizedBox(height: 4),
              Text('${widget.score}', style: display(72, color: Palette.yellow)),
              Text(
                widget.rank.toUpperCase(),
                textAlign: TextAlign.center,
                style: display(24, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                widget.detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC9B8E6), fontSize: 13),
              ),
              if (_record) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Palette.yellow, borderRadius: BorderRadius.circular(99)),
                  child: Text('NOUVEAU RECORD', style: display(16, color: Palette.night)),
                ),
              ],
              if (me == null) ...[
                const SizedBox(height: 10),
                const Text(
                  "Choisis ton nom sur l'accueil pour enregistrer tes scores.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.yellow, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 16),
              _Leaderboard(state: widget.state, game: widget.game),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF4A3A68)),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quitter', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      autofocus: true,
                      onPressed: widget.onReplay,
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.pink,
                        foregroundColor: Palette.night,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('REJOUER', style: display(20, color: Palette.night)),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Eyebrow("Classement de l'équipe", color: Palette.cyan),
            const SizedBox(height: 6),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Personne n\'a encore joué. Premier record à prendre !', style: TextStyle(color: Color(0xFFC9B8E6), fontSize: 13)),
              ),
            for (var k = 0; k < entries.length && k < 7; k++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text('${k + 1}', style: display(18, color: k == 0 ? Palette.yellow : Colors.white70)),
                    ),
                    Avatar(_person(entries[k].key), size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entries[k].key,
                        style: TextStyle(color: Colors.white, fontWeight: entries[k].key == state.me ? FontWeight.w800 : FontWeight.w500),
                      ),
                    ),
                    Text('${entries[k].value}', style: display(18, color: k == 0 ? Palette.yellow : Colors.white)),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );

  static Person? _person(String name) {
    for (final p in kPeople) {
      if (p.name == name) return p;
    }
    return null;
  }
}
