/// Intro façon bande-annonce, jouée au lancement de l'app.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class IntroTrailer extends StatefulWidget {
  const IntroTrailer({super.key, this.image = 'assets/memes/vice.jpg'});

  final String image;

  @override
  State<IntroTrailer> createState() => _IntroTrailerState();
}

class _IntroTrailerState extends State<IntroTrailer> with SingleTickerProviderStateMixin {
  static const _length = Duration(milliseconds: 7200);
  late final AnimationController _c = AnimationController(vsync: this, duration: _length);
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _done = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Animations réduites : pas de bande-annonce.
      if (MediaQuery.of(context).disableAnimations) {
        setState(() => _done = true);
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _skip() {
    // Saute directement au fondu de sortie.
    if (_c.value < .9) _c.forward(from: .9);
  }

  /// Valeur 0→1 entre deux instants (en fraction de la durée totale), lissée.
  double _seg(double a, double b, [Curve curve = Curves.easeInOut]) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  /// Apparition entre a et b, disparition entre c et d.
  double _inOut(double a, double b, double c, double d) => _seg(a, b) * (1 - _seg(c, d));

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        final portrait = size.height > size.width;
        final exit = 1 - _seg(.9, 1);
        final image = _inOut(.2, .34, .82, .9);
        final zoom = 1.18 - .18 * _seg(.2, .9, Curves.easeOut);
        final bars = _seg(.0, .12, Curves.easeOutCubic) * (1 - _seg(.88, .96));
        final barH = size.height * (portrait ? .12 : .1) * bars;

        Widget caption(String text, double opacity, {double size = 46, Color color = Colors.white}) => Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - opacity)),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: display(size, color: color).copyWith(
                    letterSpacing: 3,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 18)],
                  ),
                ),
              ),
            );

        return Opacity(
          opacity: exit,
          child: Material(
            color: Colors.black,
            child: Stack(fit: StackFit.expand, children: [
              Opacity(
                opacity: image,
                child: Transform.scale(
                  scale: zoom,
                  alignment: portrait ? const Alignment(.35, 0) : Alignment.center,
                  child: Image.asset(
                    widget.image,
                    fit: BoxFit.cover,
                    alignment: portrait ? const Alignment(.42, 0) : Alignment.center,
                  ),
                ),
              ),
              // Voile sombre pour lire les sous-titres.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: .1), Colors.black.withValues(alpha: .65)],
                    ),
                  ),
                ),
              ),
              // Carton d'ouverture, sur fond noir.
              Center(child: caption('CET HIVER', _inOut(.03, .1, .16, .21), size: portrait ? 44 : 64)),
              // Sous-titres sur l'image.
              Positioned(
                left: 24,
                right: 24,
                bottom: barH + (portrait ? 56 : 64),
                child: Stack(alignment: Alignment.bottomCenter, children: [
                  caption("UNE ÉQUIPE D'ALTERNANTS", _inOut(.36, .42, .5, .54), size: portrait ? 30 : 44),
                  caption('UN SEUL PLANNING', _inOut(.54, .6, .66, .7), size: portrait ? 30 : 44),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Opacity(opacity: _inOut(.7, .76, .84, .89), child: Text('Vice Mode', style: neon(portrait ? 34 : 46, color: Palette.pink))),
                    caption('LE GUIDE DES CONGÉS', _inOut(.72, .78, .84, .89), size: portrait ? 38 : 60, color: Palette.yellow),
                  ]),
                ]),
              ),
              // Bandes noires de cinéma.
              Positioned(left: 0, right: 0, top: 0, height: barH, child: const ColoredBox(color: Colors.black)),
              Positioned(left: 0, right: 0, bottom: 0, height: barH, child: const ColoredBox(color: Colors.black)),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: Opacity(
                  opacity: .85 * _seg(.04, .1),
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: .12),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Passer', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
