import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'features/auth/auth_flow.dart';
import 'features/landing/landing_page.dart';
import 'features/landlord/landlord_shell.dart';
import 'features/tenant/tenant_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MaCiteApp());
}

// Thèmes construits une seule fois (et non à chaque changement de mode).
final _light = appTheme();
final _dark = appTheme(dark: true);

class MaCiteApp extends StatelessWidget {
  const MaCiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'MaCité',
        debugShowCheckedModeBanner: false,
        theme: _light,
        darkTheme: _dark,
        themeMode: mode,
        themeAnimationDuration: const Duration(milliseconds: 300),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        // Sur le web, on arrive sur la page publique ; sur mobile, sur le démarrage.
        initialRoute: kIsWeb ? Routes.landing : Routes.auth,
        onGenerateRoute: (settings) {
          final Widget page = switch (settings.name) {
            Routes.landing => const LandingPage(),
            Routes.landlord => const LandlordShell(),
            Routes.tenant => const TenantShell(),
            _ => AuthFlow(initial: settings.arguments as String?),
          };
          return PageRouteBuilder(
            settings: settings,
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (_, _, _) => page,
            transitionsBuilder: (_, anim, _, child) {
              // drive() ne crée pas d'écouteur à libérer, contrairement à CurvedAnimation.
              final a = anim.drive(CurveTween(curve: kEase));
              return FadeTransition(
                opacity: a,
                child: AnimatedBuilder(
                  animation: a,
                  builder: (_, c) => Transform.translate(offset: Offset(24 * (1 - a.value), 0), child: c),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
