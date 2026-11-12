import 'package:flutter/material.dart';

/// Mode d'affichage global (clair / sombre), modifiable depuis les paramètres.
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

bool get isDarkMode => themeMode.value == ThemeMode.dark;
void setDarkMode(bool dark) => themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;

class Routes {
  static const landing = '/';
  static const auth = '/connexion';
  static const landlord = '/bailleur';
  static const tenant = '/locataire';
}

/// Remplace toute la pile par [route] (connexion, espace bailleur…).
void goRoot(BuildContext context, String route, {Object? args}) => Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false, arguments: args);
