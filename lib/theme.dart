/// Couleurs et typographies (clair / sombre).
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

  static const accent = Color(0xFFFCE500);
  static const accentInk = Color(0xFF101A33);
  static const navy = Color(0xFF101A33);

  final Color bg, surface, sunk, ink, muted, line, meRow, sel, todayCol;
  final Color ent, eco, cge, tt, fer;

  static const light = Palette(
    bg: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    sunk: Color(0xFFEEF1F7),
    ink: Color(0xFF101A33),
    muted: Color(0xFF66708A),
    line: Color(0xFFE3E7EF),
    meRow: Color(0xFFFFFBD6),
    sel: Color(0xFF101A33),
    todayCol: Color(0x1427509B),
    ent: Color(0xFFC9D8F2),
    eco: Color(0xFFF7C66B),
    cge: Color(0xFF2FB67C),
    tt: Color(0xFFA996F2),
    fer: Color(0xFFD9DDE5),
  );

  static const dark = Palette(
    bg: Color(0xFF0B1020),
    surface: Color(0xFF141A2E),
    sunk: Color(0xFF1B2238),
    ink: Color(0xFFE8ECF6),
    muted: Color(0xFF8F99B3),
    line: Color(0xFF252D46),
    meRow: Color(0xFF2A2710),
    sel: Color(0xFFFCE500),
    todayCol: Color(0x0FFFFFFF),
    ent: Color(0xFF2C4370),
    eco: Color(0xFFB98A2E),
    cge: Color(0xFF2FB67C),
    tt: Color(0xFF7D68D6),
    fer: Color(0xFF323A52),
  );

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

TextStyle display(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
    GoogleFonts.getFont('Bricolage Grotesque', fontSize: size, fontWeight: weight, color: color, height: 1.15);

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Palette.dark : Palette.light;
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF27509B),
      brightness: b,
      surface: p.surface,
      primary: b == Brightness.dark ? Palette.accent : Palette.navy,
      onPrimary: b == Brightness.dark ? Palette.accentInk : Colors.white,
    ),
    scaffoldBackgroundColor: p.bg,
    extensions: [p],
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink),
    dividerColor: p.line,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: p.surface, fontSize: 12.5),
      waitDuration: const Duration(milliseconds: 250),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: TextStyle(color: p.surface, fontWeight: FontWeight.w600),
      width: 420,
    ),
  );
}
