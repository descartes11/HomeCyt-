import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';

/// Apparition : fondu + montée (8 px par défaut, 250 ms).
class FadeUp extends StatefulWidget {
  const FadeUp({super.key, required this.child, this.delay = Duration.zero, this.offset = 8, this.duration = const Duration(milliseconds: 250)});
  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  // Créée une seule fois : une CurvedAnimation par build() accumulait des écouteurs sur le contrôleur.
  late final CurvedAnimation _a = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _t = Timer(widget.delay, () => mounted ? _c.forward() : null);
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition met à jour l'opacité sans reconstruire le sous-arbre.
    return FadeTransition(
      opacity: _a,
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, child) => Transform.translate(offset: Offset(0, widget.offset * (1 - _a.value)), child: child),
        child: widget.child,
      ),
    );
  }
}

/// Apparition « pop » : échelle 0,85 → 1 + fondu.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 350)});
  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final CurvedAnimation _a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () => mounted ? _c.forward() : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 8 * (1 - _c.value)),
          child: Transform.scale(scale: 0.85 + 0.15 * _a.value, child: child),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Flottement vertical continu (cartes décoratives).
class FloatY extends StatefulWidget {
  const FloatY({super.key, required this.child, this.amplitude = 8, this.period = const Duration(seconds: 5), this.phase = 0});
  final Widget child;
  final double amplitude;
  final Duration period;
  final double phase;

  @override
  State<FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<FloatY> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    // Affecter `value` arrête le contrôleur : on fixe la phase d'abord, puis on lance la boucle
    // (dans l'ordre inverse, la carte ne flottait jamais).
    _c.value = widget.phase;
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    // Animation permanente : isolée pour ne repeindre ni la page autour, ni le contenu de la carte.
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(offset: Offset(0, -widget.amplitude * Curves.easeInOut.transform(_c.value)), child: child),
      child: RepaintBoundary(child: widget.child),
    ),
  );
}

/// Bloc squelette (chargement) — fond neutral-200 qui pulse.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = AppRadius.md});
  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  late final Animation<double> _o = Tween(begin: 0.55, end: 1.0).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return FadeTransition(
      opacity: _o,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
  }
}

/// Transition d'écran : glissement 24 px + fondu, 300 ms, Cubic(0.2, 0, 0, 1).
class ScreenSwitcher extends StatelessWidget {
  const ScreenSwitcher({super.key, required this.child, this.axis = Axis.horizontal});
  final Widget child;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    // Calque séparé : les transitions et apparitions du contenu ne repeignent pas
    // la navigation autour (et inversement).
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: kEase,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previous.map((w) => IgnorePointer(child: w)),
            ?current,
          ],
        ),
        transitionBuilder: (child, anim) {
          final dx = axis == Axis.horizontal ? 24.0 : 0.0;
          final dy = axis == Axis.vertical ? 24.0 : 0.0;
          return FadeTransition(
            opacity: anim,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, c) => Transform.translate(offset: Offset(dx * (1 - anim.value), dy * (1 - anim.value)), child: c),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}

/// Petit indicateur de chargement circulaire.
class Spinner extends StatelessWidget {
  const Spinner({super.key, this.size = 18, this.color, this.stroke = 2});
  final double size;
  final Color? color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.pal.onBtn;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: stroke, color: c, backgroundColor: c.withValues(alpha: 0.3)),
    );
  }
}
