/// Encart « Salle d'arcade » de l'accueil : lance les mini-jeux.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import 'catch_quentin.dart';
import 'lane_race.dart';
import 'score_store.dart';

class ArcadeCard extends StatelessWidget {
  const ArcadeCard({super.key, required this.state});

  final AppState state;

  void _open(BuildContext context, Widget game) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => game));

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _GameTile(
        state: state,
        game: Games.catchQuentin,
        title: 'ATTRAPE QUENTIN',
        pitch: 'Raccompagne-le à la sortie avant la fin du chrono.',
        color: Palette.cyan,
        icon: Icons.ads_click_rounded,
        onTap: () => _open(context, CatchQuentinGame(state: state)),
      ),
      _GameTile(
        state: state,
        game: Games.race,
        title: 'ROUTE DES CONGÉS',
        pitch: 'Esquive les réunions, ramasse les jours de congé.',
        color: Palette.pink,
        icon: Icons.directions_car_filled_rounded,
        onTap: () => _open(context, LaneRaceGame(state: state)),
      ),
    ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("SALLE D'ARCADE", style: display(26, color: context.pal.ink)),
              ),
              Text('Pause café', style: neon(24, color: Palette.pink)),
            ],
          ),
          const SizedBox(height: 4),
          Text("Deux mini-jeux, un classement d'équipe.", style: TextStyle(color: context.pal.muted, fontSize: 13)),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 560) {
                return Column(children: [tiles[0], const SizedBox(height: 10), tiles[1]]);
              }
              return Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 12),
                  Expanded(child: tiles[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.state,
    required this.game,
    required this.title,
    required this.pitch,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final AppState state;
  final String game, title, pitch;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Color.alphaBlend(color.withValues(alpha: .1), Palette.night),
          border: Border.all(color: color.withValues(alpha: .7), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: .2), blurRadius: 18)],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Palette.night, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: display(20, color: Colors.white)),
                  Text(pitch, style: TextStyle(fontSize: 12.5, color: context.pal.muted, height: 1.3)),
                  const SizedBox(height: 4),
                  StreamBuilder<Map<String, int>>(
                    stream: state.scores.watch(game),
                    builder: (context, snap) {
                      final scores = snap.data ?? const {};
                      final best = scores.entries.fold<MapEntry<String, int>?>(null, (a, b) => a == null || b.value > a.value ? b : a);
                      final mine = state.me == null ? null : scores[state.me];
                      final parts = [if (best != null) 'Record : ${best.value} (${best.key})', if (mine != null) 'Toi : $mine'];
                      return Text(
                        parts.isEmpty ? 'Aucun score pour l\'instant' : parts.join(' · '),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color.lerp(color, Colors.white, .4)),
                      );
                    },
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: color, size: 30),
          ],
        ),
      ),
    ),
  );
}
