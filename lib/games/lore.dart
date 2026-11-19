/// Lore des mini-jeux : histoires d'introduction, messages en cours de partie,
/// épilogues et fiches personnages de l'équipe.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../planning.dart';
import '../theme.dart';
import 'pixel.dart';
import 'score_store.dart';

// ---------------------------------------------------------------------------
// Fiches personnages
// ---------------------------------------------------------------------------

class Bio {
  const Bio(this.title, this.text, this.speed, this.stealth, this.motivation);

  final String title, text;
  final int speed, stealth, motivation; // de 1 à 5
}

const Map<String, Bio> kBios = {
  'Quentin': Bio('Le Stagiaire éternel',
      "Arrivé le 2 novembre, libération prévue le 29 janvier. Pouvoir spécial : réapparaître à n'importe quelle fenêtre. Faiblesse : les pots de départ.", 4, 5, 2),
  'Lucas': Bio('Le Pilote', "A codé ce guide entre deux réunions. Toujours le pied sur l'accélérateur quand il s'agit de partir en congé.", 5, 2, 4),
  'Opaline': Bio('La Stratège', 'Pose ses congés six mois à l\'avance. Personne ne sait comment elle obtient toujours les ponts.', 3, 4, 5),
  'Jenny': Bio("L'Insaisissable", "Introuvable les semaines d'exam, imbattable les semaines d'open space.", 5, 5, 3),
  'Samuel': Bio('Le Tribun', 'Réclame un référendum pour chaque départ. Le dernier portait sur celui de Quentin : adopté à l\'unanimité.', 2, 1, 5),
  'Tom': Bio('Le Vigile', "Surveille l'open space depuis son bureau près de la fenêtre. Rien ne lui échappe. Sauf Quentin.", 3, 3, 4),
  'Romain': Bio('Le Diplomate', "Blazer gris, sourire permanent. Négocie les RTT comme d'autres négocient des contrats.", 3, 4, 4),
};

/// Ouvre les fiches personnages de l'équipe.
Future<void> showCharacterSheets(BuildContext context) => showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
          child: PixelBox(
            border: Palette.yellow,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(px('SÉLECTION DES PERSONNAGES'), textAlign: TextAlign.center, style: pixelTitle(13, color: Palette.yellow)),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final p in kPeople)
                      if (kBios[p.name] case final bio?) _CharacterCard(name: p.name, school: p.school, bio: bio),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              PixelButton(label: 'FERMER', autofocus: true, onPressed: () => Navigator.of(context).pop()),
            ]),
          ),
        ),
      ),
    );

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.name, required this.school, required this.bio});

  final String name, school;
  final Bio bio;

  @override
  Widget build(BuildContext context) => Container(
        width: 320,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Palette.cyan, width: 3)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(4),
            color: const Color(0xFF2A1450),
            child: PixelAvatar(name, size: 64),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(px(name.toUpperCase()), style: pixelTitle(11, color: Palette.yellow)),
              const SizedBox(height: 4),
              Text(px(bio.title.toUpperCase()), style: pixelTitle(7, color: Palette.pink)),
              Text(school, style: pixelBody(17, color: const Color(0xFFC9B8E6))),
              const SizedBox(height: 4),
              Text(bio.text, style: pixelBody(18)),
              const SizedBox(height: 6),
              _Stat('VITESSE', bio.speed, Palette.cyan),
              _Stat('DISCRETION', bio.stealth, Palette.violet),
              _Stat('MOTIVATION', bio.motivation, Palette.orange),
            ]),
          ),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label $value sur 5',
        child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(children: [
            SizedBox(width: 92, child: Text(label, style: pixelTitle(6, color: Colors.white).copyWith(shadows: const []))),
            for (var k = 0; k < 5; k++)
              Container(margin: const EdgeInsets.only(right: 2), width: 14, height: 8, color: k < value ? color : const Color(0xFF2A2440)),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------------
// Histoires
// ---------------------------------------------------------------------------

/// Une réplique : [speaker] est un prénom de l'équipe, ou null pour le narrateur.
class StoryLine {
  const StoryLine(this.text, [this.speaker]);

  final String text;
  final String? speaker;
}

const Map<String, List<StoryLine>> kStories = {
  Games.catchQuentin: [
    StoryLine("Le siège, 2e étage. 19 h 04. L'open space est vide... presque."),
    StoryLine("Chef, il est encore là. Le stagiaire. Il se cache derrière les stores depuis le 2 novembre.", 'Tom'),
    StoryLine("Son contrat dit 29 janvier. Mais personne n'a jamais vu Quentin quitter le bâtiment."),
    StoryLine('On a tout essayé : pot de départ, badge désactivé, Wi-Fi coupé. Il revient toujours.', 'Romain'),
    StoryLine('Je vous entends, vous savez. Je suis juste derrière la fenêtre du milieu.', 'Quentin'),
    StoryLine('Ta mission : le raccompagner à la sortie. Gentiment. Tu as 30 secondes avant qu\'il retrouve la machine à café.'),
  ],
  Games.race: [
    StoryLine('Vendredi, 17 h 58. Ton congé commence à 18 h.'),
    StoryLine("J'ai posé mes congés il y a six mois. Toi, tu as deux minutes pour quitter la ville.", 'Opaline'),
    StoryLine('Le boss vient d\'envoyer une invitation : « Point rapide, 18 h 01 ».'),
    StoryLine('Fonce vers la plage. Évite les réunions, les exams et surtout les mails.', 'Jenny'),
    StoryLine('Ramasse tous les jours de congé sur la route. Un RTT peut te sauver la vie.', 'Lucas'),
  ],
};

/// Messages radio pendant « Attrape Quentin », à ces secondes de jeu.
const List<(double, String, String)> kCatchRadio = [
  (8, 'Tom', 'Il a pris un deuxième café !'),
  (16, 'Romain', "Quentin doré repéré, il a mis la couronne du pot de départ !"),
  (24, 'Samuel', "Le référendum est clair : il doit sortir avant la fin !"),
];

/// Panneaux de « Route des congés », à partir de ces scores.
const List<(int, String)> kRaceSigns = [
  (300, 'SORTIE PARKING'),
  (800, 'ROCADE DES RÉUNIONS'),
  (1500, 'CORNICHE DU PONT DE MAI'),
  (2500, 'VICE BEACH 2 KM'),
  (4000, 'ODEUR DE CRÈME SOLAIRE'),
];

String catchEpilogue(int score) {
  if (score >= 450) return 'Quentin a rendu son badge. L\'open space applaudit. Le 29 janvier peut enfin arriver.';
  if (score >= 250) return "Quentin est dehors. Il fait coucou par la fenêtre. Le combat reprend demain.";
  if (score >= 100) return "Quentin a été raccompagné jusqu'au hall. Il est remonté par l'escalier de secours.";
  return "Quentin s'est caché dans le local imprimante. Il imprime son CV... pour rester.";
}

String raceEpilogue(int score) {
  if (score >= 3000) return 'Vice Beach. Pieds dans le sable. Ton message d\'absence répond à ta place.';
  if (score >= 1500) return 'La mer est en vue. Tu passes ton téléphone en mode avion.';
  if (score >= 500) return 'Tu as atteint la rocade. Ton téléphone vibre encore, mais tu ne regardes pas.';
  return 'Le boss t\'a rattrapé au parking. Le « point rapide » a duré deux heures.';
}

/// Vrai si l'histoire de ce jeu a déjà été vue sur cet appareil.
Future<bool> storySeen(String game) async {
  try {
    return (await SharedPreferences.getInstance()).getBool('gdc-lore-$game') ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> markStorySeen(String game) async {
  try {
    await (await SharedPreferences.getInstance()).setBool('gdc-lore-$game', true);
  } catch (_) {}
}

/// Boîte de dialogue façon RPG : texte qui s'écrit lettre par lettre, portrait du personnage qui parle.
class StoryOverlay extends StatefulWidget {
  const StoryOverlay({super.key, required this.title, required this.lines, required this.onDone});

  final String title;
  final List<StoryLine> lines;
  final VoidCallback onDone;

  @override
  State<StoryOverlay> createState() => _StoryOverlayState();
}

class _StoryOverlayState extends State<StoryOverlay> {
  int _line = 0, _chars = 0;
  Timer? _timer;

  StoryLine get _current => widget.lines[_line];
  bool get _typed => _chars >= _current.text.length;

  @override
  void initState() {
    super.initState();
    _type();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _type() {
    _timer?.cancel();
    _chars = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 22), (t) {
      if (!mounted) return t.cancel();
      setState(() => _chars++);
      if (_typed) t.cancel();
    });
  }

  void _next() {
    if (!_typed) {
      _timer?.cancel();
      setState(() => _chars = _current.text.length);
      return;
    }
    if (_line + 1 >= widget.lines.length) {
      widget.onDone();
      return;
    }
    setState(() => _line++);
    _type();
  }

  @override
  Widget build(BuildContext context) {
    final speaker = _current.speaker;
    final bio = speaker == null ? null : kBios[speaker];
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Container(
          color: Colors.black.withValues(alpha: .82),
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            const SizedBox(height: 8),
            Text(px(widget.title), textAlign: TextAlign.center, style: pixelTitle(14, color: Palette.yellow)),
            const SizedBox(height: 6),
            Text('CHAPITRE ${_line + 1} / ${widget.lines.length}', style: pixelTitle(8, color: const Color(0xFF9A8CB8))),
            const Spacer(),
            if (speaker != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF2A1450), border: Border.all(color: Palette.cyan, width: 3)),
                  child: PixelAvatar(speaker, size: 72),
                ),
              ),
            const SizedBox(height: 10),
            PixelBox(
              border: speaker == null ? Colors.white : Palette.cyan,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                  speaker == null ? 'NARRATEUR' : px('${speaker.toUpperCase()}${bio == null ? '' : ' · ${bio.title.toUpperCase()}'}'),
                  style: pixelTitle(8, color: speaker == null ? const Color(0xFFC9B8E6) : Palette.cyan),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: Text(_current.text.substring(0, _chars.clamp(0, _current.text.length)), style: pixelBody(24)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(_typed ? (_line + 1 >= widget.lines.length ? 'À TOI ! >' : 'SUITE >') : '...',
                      style: pixelTitle(9, color: Palette.pink)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PixelButton(label: 'PASSER', color: const Color(0xFF9A8CB8), onPressed: widget.onDone)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: PixelButton(label: 'SUITE', autofocus: true, onPressed: _next)),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Bandeau de message en haut du jeu (radio, panneau de route).
class LoreBanner extends StatelessWidget {
  const LoreBanner({super.key, required this.text, this.speaker, this.sign = false});

  final String text;
  final String? speaker;

  /// Panneau de route vert plutôt que message radio.
  final bool sign;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sign ? const Color(0xFF1E7A46) : Colors.black,
                border: Border.all(color: sign ? Colors.white : Palette.cyan, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (speaker != null) ...[PixelAvatar(speaker!, size: 32), const SizedBox(width: 8)],
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    if (!sign) Text(px('RADIO ${speaker?.toUpperCase() ?? ''}'), style: pixelTitle(7, color: Palette.cyan)),
                    Text(sign ? px(text) : text, style: sign ? pixelTitle(11) : pixelBody(21)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}
