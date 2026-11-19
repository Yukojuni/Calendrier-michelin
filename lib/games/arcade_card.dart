/// Encart « Salle d'arcade » de l'accueil : lance les mini-jeux.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import 'catch_quentin.dart';
import 'lane_race.dart';
import 'lore.dart';
import 'pixel.dart';
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
        art: const PixelAvatar('Quentin', size: 40),
        onTap: () => _open(context, CatchQuentinGame(state: state)),
      ),
      _GameTile(
        state: state,
        game: Games.race,
        title: 'ROUTE DES CONGÉS',
        pitch: 'Esquive les réunions, ramasse les jours de congé.',
        color: Palette.pink,
        art: CustomPaint(size: const Size(32, 36), painter: _SpritePainter(carSprite(kLooks[state.me]))),
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
          Text("Deux mini-jeux, une histoire, un classement d'équipe.", style: TextStyle(color: context.pal.muted, fontSize: 13)),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => showCharacterSheets(context),
                icon: const Icon(Icons.groups_rounded, size: 18),
                label: const Text('Les personnages', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Palette.yellow,
                  side: const BorderSide(color: Palette.yellow, width: 1.5),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              Text('Fiches, pouvoirs et faiblesses de chacun.', style: TextStyle(color: context.pal.muted, fontSize: 12.5)),
            ],
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
    required this.art,
    required this.onTap,
  });

  final AppState state;
  final String game, title, pitch;
  final Color color;
  final Widget art;
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
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: color, width: 3)),
              child: art,
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

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.sprite);

  final Sprite sprite;

  @override
  void paint(Canvas canvas, Size size) => sprite.paint(canvas, Offset.zero, size.width / sprite.width);

  @override
  bool shouldRepaint(_SpritePainter old) => false;
}
