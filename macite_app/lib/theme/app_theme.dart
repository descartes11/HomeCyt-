// MaCité v2 — tokens Broadsheet pour Flutter (Material 3).
// Source : design_handoff_macite_v2/app_theme.dart et tokens/styles.css.
// Différence : la police est embarquée (assets/fonts) au lieu de google_fonts.
import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF3F2F2); // fond d'écran (papier)
  static const surface = Color(0xFFEAE9E9);
  static const text = Color(0xFF201E1D);
  static const accent = Color(0xFF0088B0); // cyan : icônes, focus, grands textes
  static const accent2 = Color(0xFFD6006C); // magenta : retards, urgences, déconnexion
  static const divider = Color(0x29201E1D);

  static const n100 = Color(0xFFF8F4F4),
      n200 = Color(0xFFEAE7E7),
      n300 = Color(0xFFD7D3D3),
      n400 = Color(0xFFBAB6B6),
      n500 = Color(0xFF9B9797),
      n600 = Color(0xFF7D7979),
      n700 = Color(0xFF605D5D),
      n800 = Color(0xFF444141),
      n900 = Color(0xFF2D2B2B);
  static const a100 = Color(0xFFE9F8FF),
      a200 = Color(0xFFCBEEFF),
      a300 = Color(0xFF99E0FF),
      a400 = Color(0xFF62C5EE),
      a500 = Color(0xFF38A6CF),
      a600 = Color(0xFF1186AC),
      a700 = Color(0xFF006786),
      a800 = Color(0xFF004961),
      a900 = Color(0xFF0A303E);
  static const m100 = Color(0xFFFFF1F4),
      m200 = Color(0xFFFFDEE6),
      m300 = Color(0xFFFFC0D0),
      m400 = Color(0xFFFF90B1),
      m500 = Color(0xFFFF458E),
      m600 = Color(0xFFD82071),
      m700 = Color(0xFFAA0B56),
      m800 = Color(0xFF790E3D),
      m900 = Color(0xFF4B1528);

  // Rôles d'interface
  static const card = n100; // cartes, barres, champs
  static const primaryBtn = a700; // bouton plein (texte n100)
  static const primaryBtnPressed = a800;
  static const outlineBorder = a200; // bouton contour (texte a700)
  static const textSecondary = n700;
  static const link = a700;

  // Mode sombre
  static const darkBg = n900, darkSurface = n800, darkText = n200, darkTextSecondary = n400;
}

class AppSpacing {
  static const s1 = 5.0, s2 = 10.0, s3 = 15.0, s4 = 20.0, s6 = 30.0, s8 = 40.0;
}

class AppRadius {
  // Coins arrondis (demande client) : 12 px pour cadres, boutons, champs et onglets ;
  // 8 px pour l'onglet actif posé dans une piste ; 20 px pour le haut des feuilles du bas.
  static const sm = 8.0, md = 12.0, lg = 20.0;
  static const r = BorderRadius.all(Radius.circular(md));
  static const rs = BorderRadius.all(Radius.circular(sm));
}

class AppShadows {
  static const sm = [BoxShadow(color: Color(0x242D2B2B), blurRadius: 2, offset: Offset(0, 1))];
  static const md = [BoxShadow(color: Color(0x292D2B2B), blurRadius: 10, offset: Offset(0, 3))];
  static const lg = [BoxShadow(color: Color(0x382D2B2B), blurRadius: 32, offset: Offset(0, 12))];
}

/// Courbe standard des transitions (Cubic(0.2, 0, 0, 1)).
const kEase = Cubic(0.2, 0, 0, 1);

/// Montserrat partout (embarquée dans assets/fonts : identique sur Android, iOS, web et Windows, hors ligne).
const kFontFamily = 'Montserrat';

TextTheme appTextTheme(Color c) {
  TextStyle s(double size, FontWeight w, {double h = 1.3, double ls = 0}) =>
      TextStyle(fontFamily: kFontFamily, fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: c);
  return TextTheme(
    displaySmall: s(32, FontWeight.w700, h: 1.1, ls: -0.3), // chiffres clés
    headlineMedium: s(28, FontWeight.w700, h: 1.2), // titre d'écran
    titleLarge: s(20, FontWeight.w600), // section
    titleMedium: s(16, FontWeight.w600),
    bodyLarge: s(16, FontWeight.w400, h: 1.5),
    bodyMedium: s(16, FontWeight.w400, h: 1.3),
    bodySmall: s(13, FontWeight.w500, h: 1.4),
    labelLarge: s(16, FontWeight.w600), // boutons
    labelMedium: s(13, FontWeight.w600), // libellés
    labelSmall: s(12, FontWeight.w600), // badges
  );
}

ThemeData appTheme({bool dark = false}) {
  final bg = dark ? AppColors.darkBg : AppColors.bg;
  final fg = dark ? AppColors.darkText : AppColors.text;
  final card = dark ? AppColors.darkSurface : AppColors.card;
  final primary = dark ? AppColors.a400 : AppColors.a700;
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: primary,
    onPrimary: dark ? AppColors.n900 : AppColors.n100,
    primaryContainer: dark ? AppColors.a900 : AppColors.a200,
    onPrimaryContainer: dark ? AppColors.a200 : AppColors.a900,
    secondary: dark ? AppColors.m400 : AppColors.accent2,
    onSecondary: AppColors.n100,
    error: dark ? AppColors.m400 : AppColors.m700,
    onError: AppColors.n100,
    surface: card,
    onSurface: fg,
    onSurfaceVariant: dark ? AppColors.darkTextSecondary : AppColors.n700,
    outline: dark ? AppColors.n700 : AppColors.n300,
    outlineVariant: dark ? AppColors.n800 : AppColors.n200,
  );
  const r = RoundedRectangleBorder(borderRadius: AppRadius.r);
  final text = appTextTheme(fg);
  return ThemeData(
    useMaterial3: true,
    fontFamily: kFontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    textTheme: text,
    splashFactory: InkRipple.splashFactory,
    cardTheme: CardThemeData(color: card, elevation: 0, margin: EdgeInsets.zero, shape: r),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, 48),
        shape: r,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: card,
        minimumSize: const Size(0, 48),
        shape: r,
        side: BorderSide(color: dark ? AppColors.a800 : AppColors.outlineBorder),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: dark ? AppColors.darkTextSecondary : AppColors.n700, shape: r, textStyle: text.labelLarge),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.25),
      selectionHandleColor: AppColors.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.n900,
      contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.n100, fontSize: 14),
      shape: r,
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    focusColor: AppColors.accent.withValues(alpha: 0.3),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      modalBackgroundColor: card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
    ),
    dialogTheme: DialogThemeData(backgroundColor: card, shape: r),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder(), TargetPlatform.windows: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

/// 45000 → « 45 000 FCFA »
String formatFcfa(num v) {
  final s = v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  return '$s FCFA';
}

/// 45000 → « 45 000 » (sans unité)
String formatNumber(num v) => v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

/// « 45 000 » → 45000
int parseAmount(String s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0;
