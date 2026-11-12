import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comptes créés sur cet appareil : retient le profil (bailleur / locataire)
/// choisi à l'inscription pour ouvrir le bon espace à la connexion.
class Accounts {
  static final _mem = <String, String>{};

  /// Clé d'un identifiant : e-mail en minuscules, ou chiffres du téléphone.
  static String keyOf(String id) {
    final t = id.trim().toLowerCase();
    return t.contains('@') ? t : t.replaceAll(RegExp(r'\D'), '');
  }

  static Future<void> save({required String phone, required String email, required String role}) async {
    final keys = [keyOf(phone), keyOf(email)].where((k) => k.isNotEmpty);
    for (final k in keys) {
      _mem[k] = role;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in keys) {
        await prefs.setString('account:$k', role);
      }
    } catch (e) {
      // Stockage indisponible : le compte reste connu jusqu'à la fermeture de l'app.
      debugPrint('Comptes : $e');
    }
  }

  /// 'tenant', 'landlord', ou null si l'identifiant est inconnu.
  static Future<String?> roleOf(String id) async {
    final k = keyOf(id);
    if (k.isEmpty) return null;
    if (_mem.containsKey(k)) return _mem[k];
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('account:$k');
    } catch (e) {
      debugPrint('Comptes : $e');
      return null;
    }
  }
}
