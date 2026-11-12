import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Couleurs sémantiques résolues selon le mode clair / sombre.
/// Règle : 100–300 pour les fonds teintés, 700–900 pour le texte sur fond teinté.
class Pal {
  const Pal(this.dark);
  final bool dark;

  static Pal of(BuildContext context) => Pal(Theme.of(context).brightness == Brightness.dark);

  Color get bg => dark ? AppColors.n900 : AppColors.bg;
  Color get card => dark ? AppColors.n800 : AppColors.n100;
  Color get chip => dark ? const Color(0xFF555252) : AppColors.n200;
  Color get chipHover => dark ? AppColors.n700 : AppColors.n300;
  Color get line => dark ? AppColors.n700 : AppColors.n300;
  Color get divider => dark ? const Color(0xFF555252) : AppColors.n200;
  Color get text => dark ? AppColors.n200 : AppColors.text;
  Color get text2 => dark ? AppColors.n400 : AppColors.n700;
  Color get strong => dark ? AppColors.n300 : AppColors.n800;
  Color get faint => dark ? AppColors.n600 : AppColors.n300;
  Color get accent => dark ? AppColors.a400 : AppColors.accent;
  Color get link => dark ? AppColors.a300 : AppColors.a700;
  Color get btn => dark ? AppColors.a400 : AppColors.a700;
  Color get btnPressed => dark ? AppColors.a300 : AppColors.a800;
  Color get onBtn => dark ? AppColors.n900 : AppColors.n100;
  Color get outline => dark ? AppColors.a800 : AppColors.a200;
  Color get a100 => dark ? AppColors.a900 : AppColors.a100;
  Color get a200 => dark ? AppColors.a800 : AppColors.a200;
  Color get a500 => dark ? AppColors.a400 : AppColors.a500;
  Color get a700 => dark ? AppColors.a300 : AppColors.a700;
  Color get a800 => dark ? AppColors.a200 : AppColors.a800;
  Color get a900 => dark ? AppColors.a100 : AppColors.a900;
  Color get m100 => dark ? AppColors.m900 : AppColors.m100;
  Color get m200 => dark ? const Color(0xFF5E1A33) : AppColors.m200;
  Color get m700 => dark ? AppColors.m300 : AppColors.m700;
  Color get m800 => dark ? AppColors.m200 : AppColors.m800;
  Color get magenta => dark ? AppColors.m400 : AppColors.accent2;
  Color get navIndicator => dark ? AppColors.a900 : AppColors.a200;
  Color get overlay => const Color(0x8C201E1D);

  (Color, Color) tone(Tone t) => switch (t) {
    Tone.paid => (a100, a800),
    Tone.neutral => (chip, strong),
    Tone.muted => (chip, text2),
    Tone.late => (m200, m700),
    Tone.soft => (a100, a700),
    Tone.strong => (a200, a800),
    Tone.pale => (a100, a900),
    Tone.magSoft => (m100, m800),
    Tone.solid => (btn, onBtn),
  };
}

/// Tons des badges, pastilles et vignettes.
enum Tone { paid, neutral, muted, late, soft, strong, pale, magSoft, solid }

extension PalX on BuildContext {
  Pal get pal => Pal.of(this);
  bool get isWide => MediaQuery.sizeOf(this).width >= 1024;
}
