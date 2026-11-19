/// Petits éléments réutilisés partout.
library;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Carte blanche arrondie.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: child,
    );
  }
}

/// Petit titre en capitales au-dessus d'un bloc.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1, color: color ?? context.pal.muted),
      );
}

/// Photo de profil ronde, ou initiale sur fond coloré.
class Avatar extends StatelessWidget {
  const Avatar(this.person, {super.key, this.size = 28, this.ring, this.placeholder = '?'});

  final Person? person;
  final double size;
  final Color? ring;

  /// Texte affiché quand il n'y a personne.
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final person = this.person;
    final hsl = HSLColor.fromAHSL(1, person?.hue ?? 220, dark ? .35 : .7, dark ? .30 : .88);
    final fg = HSLColor.fromAHSL(1, person?.hue ?? 220, dark ? .8 : .55, dark ? .88 : .28);
    Widget inner = Center(
      child: Text(
        person?.initial ?? placeholder,
        style: TextStyle(fontSize: size * .42, fontWeight: FontWeight.w700, color: person == null ? p.muted : fg.toColor()),
      ),
    );
    if (person?.photo != null) {
      inner = Image.asset(person!.photo!, fit: BoxFit.cover, width: size, height: size, errorBuilder: (_, _, _) => inner);
    }
    return Tooltip(
      message: person?.name ?? '',
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: person == null ? p.sunk : hsl.toColor(),
          border: ring != null ? Border.all(color: ring!, width: size > 40 ? 3 : 2) : null,
        ),
        child: inner,
      ),
    );
  }
}

/// Pastille de couleur d'un statut.
class StatusDot extends StatelessWidget {
  const StatusDot(this.color, {super.key, this.size = 10, this.round = false});

  final Color color;
  final double size;
  final bool round;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(round ? size : 3)),
      );
}

/// Motif hachuré des jours fériés.
class HatchPainter extends CustomPainter {
  HatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(HatchPainter old) => old.color != color;
}
