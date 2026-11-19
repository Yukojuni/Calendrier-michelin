/// Style « Vice » : nuit violette, coucher de soleil rose-orange, néon cyan.
/// Un seul thème sombre, le même quel que soit le réglage du téléphone.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bg,
    required this.surface,
    required this.sunk,
    required this.ink,
    required this.muted,
    required this.line,
    required this.meRow,
    required this.sel,
    required this.todayCol,
    required this.ent,
    required this.eco,
    required this.cge,
    required this.tt,
    required this.fer,
  });

  // Couleurs de l'univers.
  static const night = Color(0xFF140A26);
  static const nightDeep = Color(0xFF0B0516);
  static const plum = Color(0xFF2A1450);
  static const pink = Color(0xFFFF4FA3);
  static const orange = Color(0xFFFF9A3C);
  static const yellow = Color(0xFFFFD95A);
  static const cyan = Color(0xFF39E5FF);
  static const violet = Color(0xFFA98BFF);
  static const paper = Color(0xFFF3E3C3);
  static const paperInk = Color(0xFF2A1A0E);

  /// Accent des badges (jour courant, toute l'équipe au bureau…).
  static const accent = yellow;
  static const accentInk = night;
  static const navy = night;

  final Color bg, surface, sunk, ink, muted, line, meRow, sel, todayCol;
  final Color ent, eco, cge, tt, fer;

  static const vice = Palette(
    bg: night,
    surface: Color(0xFF1C0E33),
    sunk: plum,
    ink: Color(0xFFFFF4FA),
    muted: Color(0xFFC9B8E6),
    line: Color(0xFF34244F),
    meRow: Color(0x1FFFD95A),
    sel: Color(0xFFFFF4FA),
    todayCol: Color(0x14FFD95A),
    ent: cyan,
    eco: orange,
    cge: pink,
    tt: violet,
    fer: Color(0xFF4A3A68),
  );

  // Les anciens noms pointent vers le même thème.
  static const light = vice;
  static const dark = vice;

  /// Couleur d'un statut du planning.
  Color status(String code) => switch (code) {
        'E' => ent,
        'S' || 'X' || 'C' => eco,
        'K' => cge,
        't' || 'T' => tt,
        'F' => fer,
        _ => Colors.transparent,
      };

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) => t < .5 ? this : (other as Palette? ?? this);
}

extension PaletteX on BuildContext {
  Palette get pal => Theme.of(this).extension<Palette>()!;
}

/// Titres : capitales condensées.
TextStyle display(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
    GoogleFonts.anton(fontSize: size, color: color, height: 1.1, letterSpacing: size > 20 ? 1 : .5);

/// Écriture néon (« Aujourd'hui », « Courage… »).
TextStyle neon(double size, {Color color = Palette.cyan}) => GoogleFonts.yellowtail(
      fontSize: size,
      color: color,
      height: 1,
      shadows: [Shadow(color: color.withValues(alpha: .7), blurRadius: 12)],
    );

ThemeData buildTheme([Brightness _ = Brightness.dark]) {
  const p = Palette.vice;
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.pink,
      brightness: Brightness.dark,
      surface: p.surface,
      primary: Palette.pink,
      onPrimary: Palette.night,
      secondary: Palette.cyan,
    ),
    scaffoldBackgroundColor: p.bg,
    extensions: const [p],
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink),
    dividerColor: p.line,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(color: Palette.night, fontSize: 12.5),
      waitDuration: const Duration(milliseconds: 250),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: const TextStyle(color: Palette.night, fontWeight: FontWeight.w700),
      width: 420,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: Palette.plum,
      side: BorderSide(color: p.line),
      labelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w600),
    ),
  );
}
