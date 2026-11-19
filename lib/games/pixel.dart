/// Pixel art des mini-jeux : personnages de l'équipe, sprites, cadres et polices.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

// ---------------------------------------------------------------------------
// Polices
// ---------------------------------------------------------------------------

/// La police 8 bits n'a pas de majuscules accentuées : on les remplace.
String px(String s) {
  const map = {'É': 'E', 'È': 'E', 'Ê': 'E', 'À': 'A', 'Â': 'A', 'Ç': 'C', 'Ô': 'O', 'Î': 'I', 'Û': 'U', 'Ù': 'U'};
  return s.split('').map((c) => map[c] ?? c).join();
}

/// Titres, chiffres et petites étiquettes (police 8 bits).
TextStyle pixelTitle(double size, {Color color = Colors.white}) => GoogleFonts.pressStart2p(
      fontSize: size,
      color: color,
      height: 1.35,
      shadows: const [Shadow(color: Colors.black, offset: Offset(2, 2))],
    );

/// Texte courant, plus lisible.
TextStyle pixelBody(double size, {Color color = Colors.white}) => GoogleFonts.vt323(fontSize: size, color: color, height: 1.1);

// ---------------------------------------------------------------------------
// Sprites
// ---------------------------------------------------------------------------

/// Image en pixels décrite par des lignes de caractères ; '.' = transparent.
class Sprite {
  const Sprite(this.rows, this.palette);

  final List<String> rows;
  final Map<String, Color> palette;

  int get width => rows.isEmpty ? 0 : rows.first.length;
  int get height => rows.length;

  /// Dessine le sprite, chaque pixel faisant [unit] px de côté.
  void paint(Canvas canvas, Offset at, double unit, {double opacity = 1, Map<String, Color>? override}) {
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final c = row[x];
        if (c == '.') continue;
        final color = override?[c] ?? palette[c];
        if (color == null) continue;
        paint.color = opacity < 1 ? color.withValues(alpha: color.a * opacity) : color;
        canvas.drawRect(Rect.fromLTWH(at.dx + x * unit, at.dy + y * unit, unit + .5, unit + .5), paint);
      }
    }
  }
}

/// Superpose des calques de même taille ('.' laisse voir le calque du dessous).
List<String> _stack(List<List<String>> layers) {
  final out = [for (final r in layers.first) r.split('')];
  for (final layer in layers.skip(1)) {
    for (var y = 0; y < layer.length && y < out.length; y++) {
      for (var x = 0; x < layer[y].length && x < out[y].length; x++) {
        if (layer[y][x] != '.') out[y][x] = layer[y][x];
      }
    }
  }
  return [for (final r in out) r.join()];
}

// ---------------------------------------------------------------------------
// Personnages de l'équipe (16 × 18)
// ---------------------------------------------------------------------------

enum Hair { short, curly, long, parted }

enum Top { tee, blazer, polo, jacket }

class Look {
  const Look({
    required this.hair,
    required this.hairColor,
    required this.skin,
    required this.top,
    required this.topColor,
    this.glasses = false,
    this.beard = false,
  });

  final Hair hair;
  final Color hairColor, skin, topColor;
  final Top top;
  final bool glasses, beard;
}

/// Description de chacun, d'après les photos de profil.
const Map<String, Look> kLooks = {
  'Opaline': Look(hair: Hair.parted, hairColor: Color(0xFF6B4226), skin: Color(0xFFF2C9A8), top: Top.blazer, topColor: Color(0xFF5B2EB8)),
  'Jenny': Look(hair: Hair.long, hairColor: Color(0xFF3B2416), skin: Color(0xFFE9B791), top: Top.tee, topColor: Color(0xFF2F5BD8)),
  'Samuel': Look(hair: Hair.short, hairColor: Color(0xFF7A5232), skin: Color(0xFFF0C4A0), top: Top.tee, topColor: Color(0xFFEDEDED), glasses: true),
  'Lucas': Look(hair: Hair.curly, hairColor: Color(0xFF241612), skin: Color(0xFFD49C76), top: Top.jacket, topColor: Color(0xFF2B3550), beard: true),
  'Tom': Look(hair: Hair.short, hairColor: Color(0xFF2B1D14), skin: Color(0xFFF2CDB0), top: Top.tee, topColor: Color(0xFFEDEDED)),
  'Romain': Look(hair: Hair.curly, hairColor: Color(0xFF5A3A22), skin: Color(0xFFF4C7A6), top: Top.blazer, topColor: Color(0xFF9AA0A8)),
  'Quentin': Look(hair: Hair.curly, hairColor: Color(0xFF6E4A2C), skin: Color(0xFFF2C6A2), top: Top.polo, topColor: Color(0xFF1F2A4D), glasses: true),
};

const _base = [
  '................',
  '................',
  '.....oooooo.....',
  '....oSSSSSSo....',
  '...oSSSSSSSSo...',
  '...oSSSSSSSSo...',
  '...oSeSSSSeSo...',
  '...oSSSSSSSSo...',
  '...oSSSSSSSSo...',
  '....oSSmmSSo....',
  '.....oSSSSo.....',
  '......oSSo......',
  '...TTTTSSTTTT...',
  '..TTTTTTTTTTTT..',
  '.TTTTTTTTTTTTTT.',
  '.TTTTTTTTTTTTTT.',
  '.TTTTTTTTTTTTTT.',
  '.TTTTTTTTTTTTTT.',
];

const Map<Hair, List<String>> _hair = {
  Hair.short: [
    '................',
    '....HHHHHHHH....',
    '...HHHHHHHHHH...',
    '..HHHHHHHHHHHH..',
    '..HHHhHHHHhHHH..',
    '..HH........HH..',
    '..H..........H..',
  ],
  Hair.curly: [
    '.....H.HH.H.....',
    '...HHHHHHHHHH...',
    '..HHHhHHHHhHHH..',
    '..HHHHHHHHHHHH..',
    '..HHhH.HH.HhHH..',
    '..HH........HH..',
    '..H..........H..',
  ],
  Hair.long: [
    '................',
    '....HHHHHHHH....',
    '...HHHHHHHHHH...',
    '..HHHHHHHHHHHH..',
    '..HHHHHhHHHHHH..',
    '..HHH......HHH..',
    '..HH........HH..',
    '..HH........HH..',
    '..HH........HH..',
    '..HHh......hHH..',
    '..HHH......HHH..',
    '..HHHh....hHHH..',
    '.HHHH......HHHH.',
    '.HHH........HHH.',
    '.HH..........HH.',
  ],
  Hair.parted: [
    '................',
    '....HHHHHHHH....',
    '...HHHHHhHHHH...',
    '..HHHHHh.HHHHH..',
    '..HHHHh...hHHH..',
    '..HHH......HHH..',
    '..HH........HH..',
    '..HH........HH..',
    '..HH........HH..',
    '..HH........HH..',
    '..HHh......hHH..',
    '..HHH......HHH..',
    '.HHHH......HHHH.',
    '.HHHH......HHHH.',
    '.HHH........HHH.',
  ],
};

const _glasses = [
  '................',
  '................',
  '................',
  '................',
  '................',
  '....ggg..ggg....',
  '....g.gggg.g....',
  '....ggg..ggg....',
];

const _beard = [
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '.....bbbbbb.....',
  '....obbmmbbo....',
  '.....obbbbo.....',
];

const Map<Top, List<String>> _top = {
  Top.tee: [],
  Top.blazer: [
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '......WSSW......',
    '..TTTtWWWWtTTT..',
    '.TTTTtWWWWtTTTT.',
    '.TTTTTtWWtTTTTT.',
    '.TTTTTtWWtTTTTT.',
    '.TTTTTTtWTTTTTT.',
  ],
  Top.polo: [
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '...TTCCSSCCTT...',
    '..TTTTCttCTTTT..',
    '.TTTTTTttTTTTTT.',
    '.TTWTTTTTTTWTTT.',
    '.TTTTTWTTTTTTWT.',
    '.TWTTTTTTWTTTTT.',
  ],
  Top.jacket: [
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '...TTCTSSTCTT...',
    '..TTTCttttCTTT..',
    '.TTTTTTtWTTTTTT.',
    '.TTTTTTtTTTTTTT.',
    '.TTTTTTtWTTTTTT.',
    '.TTTTTTtTTTTTTT.',
  ],
};

List<String> _pad(List<String> rows) => [...rows, for (var k = rows.length; k < 18; k++) '................'];

Color _shade(Color c, double amount) => Color.lerp(c, Colors.black, amount)!;
Color _light(Color c, double amount) => Color.lerp(c, Colors.white, amount)!;

/// Sprite du personnage d'une personne (16 × 18 : tête et épaules).
Sprite personSprite(String name) {
  final look = kLooks[name] ?? kLooks['Tom']!;
  final layers = <List<String>>[
    _base,
    _pad(_top[look.top]!),
    if (look.beard) _pad(_beard),
    _pad(_hair[look.hair]!),
    if (look.glasses) _pad(_glasses),
  ];
  return Sprite(_stack(layers), {
    'o': const Color(0xFF1A0B12),
    'S': look.skin,
    'e': const Color(0xFF1A0B12),
    'm': const Color(0xFFB5524A),
    'H': look.hairColor,
    'h': _shade(look.hairColor, .35),
    'g': const Color(0xFF8A8AA0),
    'b': _shade(look.hairColor, .1),
    'T': look.topColor,
    't': _shade(look.topColor, .3),
    'C': _light(look.topColor, .45),
    'W': const Color(0xFFF4F4F4),
  });
}

/// Couronne posée au-dessus d'un personnage (Quentin doré).
const crownSprite = Sprite([
  '.y..y..y.',
  '.yy.y.yy.',
  'yyyyyyyyy',
  'yrryyyrry',
  'yyyyyyyyy',
], {'y': Palette.yellow, 'r': Palette.pink});

/// Avatar pixel d'une personne, affiché net à n'importe quelle taille.
class PixelAvatar extends StatelessWidget {
  const PixelAvatar(this.name, {super.key, required this.size, this.background});

  final String name;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * 18 / 16,
        child: CustomPaint(painter: _SpritePainter(personSprite(name), background)),
      );
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.sprite, this.background);

  final Sprite sprite;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) canvas.drawRect(Offset.zero & size, Paint()..color = background!);
    final unit = size.width / sprite.width;
    sprite.paint(canvas, Offset.zero, unit);
  }

  @override
  bool shouldRepaint(_SpritePainter old) => old.sprite != sprite || old.background != background;
}

// ---------------------------------------------------------------------------
// Cadres
// ---------------------------------------------------------------------------

/// Boîte au style pixel : bord épais, angles droits, ombre décalée sans flou.
class PixelBox extends StatelessWidget {
  const PixelBox({super.key, required this.child, this.color = Palette.night, this.border = Colors.white, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final Color color, border;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: border, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
        ),
        child: child,
      );
}

/// Bouton au style pixel.
class PixelButton extends StatelessWidget {
  const PixelButton({super.key, required this.label, required this.onPressed, this.color = Palette.pink, this.autofocus = false});

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          autofocus: autofocus,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: [BoxShadow(color: _shade(color, .5), offset: const Offset(0, 4))],
            ),
            child: Text(px(label), textAlign: TextAlign.center, style: pixelTitle(12, color: Palette.night).copyWith(shadows: const [])),
          ),
        ),
      );
}
