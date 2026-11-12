import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/pdf_docs.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/ui.dart';

class Cat {
  const Cat(this.key, this.label, this.icon, this.tone);
  final String key, label;
  final IconData icon;
  final Tone tone;
}

/// Catégories de signalement : neutres sauf Propreté (cyan), Sécurité et Voisinage (magenta).
const cats = [
  Cat('plumb', 'Plomberie', PI.drop, Tone.neutral),
  Cat('elec', 'Électricité', PI.lightning, Tone.neutral),
  Cat('lock', 'Serrure et porte', PI.lock, Tone.neutral),
  Cat('clean', 'Propreté', PI.broom, Tone.paid),
  Cat('sec', 'Sécurité', PI.shield, Tone.late),
  Cat('neigh', 'Voisinage', PI.usersThree, Tone.magSoft),
  Cat('other', 'Autre', PI.dotsThree, Tone.muted),
];

class Urg {
  const Urg(this.key, this.label, this.hint, this.icon, this.tone);
  final String key, label, hint;
  final IconData icon;
  final Tone tone;
}

const urgencies = [
  Urg('low', 'Faible', 'Peut attendre quelques jours', PI.cellSignalLow, Tone.muted),
  Urg('mid', 'Moyen', 'À régler dans la semaine', PI.cellSignalMedium, Tone.neutral),
  Urg('urgent', 'Urgent', 'Danger ou dégât en cours', PI.warning, Tone.late),
];

class Announcement {
  const Announcement(this.title, this.body, this.when, this.icon);
  final String title, body, when;
  final IconData icon;
}

const tenantAnnouncements = [
  Announcement('Coupure d’eau jeudi', 'De 9 h à 12 h dans l’immeuble A. Pensez à faire vos réserves.', 'Hier · Immeuble A', PI.drop),
  Announcement(
    'Réunion des locataires',
    'Samedi 14 novembre à 10 h, dans la cour. Ordre du jour : propreté et sécurité.',
    '2 nov. · Toute la cité',
    PI.usersThree,
  ),
  Announcement(
    'Peinture des couloirs',
    'Travaux du 16 au 20 novembre, 2e étage. Merci de laisser les couloirs dégagés.',
    '30 oct. · Immeuble A',
    PI.paintRoller,
  ),
];

class MyReport {
  MyReport(this.id, this.title, this.cat, this.icon, this.tone, this.date, this.step, this.note, {this.rated = 0});
  final String id, title, cat, date, note;
  final IconData icon;
  final Tone tone;
  int step; // 1 envoyé · 2 pris en charge · 3 résolu
  int rated;
}

class Notif {
  Notif(this.id, this.today, this.icon, this.tone, this.title, this.body, this.when, this.go, {this.unread = false});
  final String id, title, body, when, go;
  final bool today;
  final IconData icon;
  final Tone tone;
  bool unread;
}

const rules = [
  ('Calme après 22 h', 'Musique et conversations à volume réduit de 22 h à 6 h.'),
  ('Visites', 'Les visiteurs sont accueillis jusqu’à 21 h et se présentent au gardien.'),
  ('Parties communes', 'Couloirs et escaliers restent dégagés. Pas de linge aux fenêtres.'),
  ('Déchets', 'Sacs fermés, déposés dans les bacs de la cour avant 8 h.'),
];

const contacts = [
  ('Daniel A.', 'Bailleur', 'DA', Tone.strong, '07 12 00 00 01'),
  ('Joseph K.', 'Gardien · 7 h – 22 h', 'JK', Tone.neutral, '07 12 00 00 02'),
  ('Pompiers', 'Urgence', '18', Tone.late, '18'),
  ('Police', 'Urgence', '17', Tone.neutral, '17'),
];

const payHistory = [
  ('Octobre 2026', '3 oct.', 'Reçu validé'),
  ('Septembre 2026', '2 sept.', 'Reçu validé'),
  ('Août 2026', '4 août', 'Reçu validé'),
  ('Juillet 2026', '1 juil.', 'Reçu validé'),
  ('Juin 2026', '3 juin', 'Reçu validé'),
];

const rent = 45000;

/// État de l'espace locataire (équivalent de la logique de la maquette).
class TenantStore extends ChangeNotifier {
  String screen = 'home';
  bool loading = true;

  // Signalement
  int step = 1;
  String? cat;
  String desc = '';
  bool descError = false;
  String urg = 'mid';
  bool sending = false;

  // Loyer
  bool paid = false, pending = false;
  int sentAmt = 0;

  int openRule = 0;
  final prefs = {'rent': true, 'reports': true, 'ann': true, 'sms': false};

  final myReports = [
    MyReport('r1', 'Ampoule de la salle de bain', 'Électricité', PI.lightning, Tone.neutral, '28 oct.', 2, 'Un technicien passera jeudi matin.'),
    MyReport('r2', 'Robinet qui goutte', 'Plomberie', PI.drop, Tone.neutral, '12 oct.', 3, 'Joint remplacé le 14 oct.'),
    MyReport('r3', 'Poignée de porte cassée', 'Serrure et porte', PI.lock, Tone.neutral, '2 sept.', 3, 'Poignée changée le 4 sept.', rated: 4),
  ];

  final notifs = [
    Notif(
      'n1',
      true,
      PI.money,
      Tone.neutral,
      'Rappel de loyer',
      'Votre loyer de 45 000 FCFA est à payer avant demain, 5 novembre.',
      '08:00',
      'payments',
      unread: true,
    ),
    Notif(
      'n2',
      true,
      PI.wrench,
      Tone.neutral,
      'Signalement pris en charge',
      '« Ampoule de la salle de bain » : un technicien passera jeudi matin.',
      '07:42',
      'myreports',
      unread: true,
    ),
    Notif('n3', false, PI.megaphone, Tone.neutral, 'Nouvelle annonce', 'Coupure d’eau jeudi de 9 h à 12 h dans l’immeuble A.', 'Hier', 'city'),
    Notif('n4', false, PI.usersThree, Tone.neutral, 'Réunion des locataires', 'Samedi 14 novembre à 10 h, dans la cour.', '2 nov.', 'city'),
    Notif('n5', false, PI.checkCircle, Tone.paid, 'Signalement résolu', '« Robinet qui goutte » est résolu. Donnez votre avis.', '14 oct.', 'myreports'),
  ];

  void Function(String msg)? toaster;
  Timer? _t;

  TenantStore() {
    _t = Timer(const Duration(milliseconds: 900), () {
      loading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _t?.cancel();
    super.dispose();
  }

  bool _disposed = false;

  /// Action différée, ignorée si l'espace a été quitté entre-temps.
  void _later(int ms, VoidCallback f) => Timer(Duration(milliseconds: ms), () {
    if (!_disposed) f();
  });

  void toast(String m) => toaster?.call(m);

  // ─── Documents PDF ───
  bool _pdfBusy = false;

  /// Génère un PDF et ouvre le menu de l'appareil (ouvrir, enregistrer, partager).
  Future<void> _pdf(String name, Future<Uint8List> Function() build, String ok) async {
    if (_pdfBusy) return;
    _pdfBusy = true;
    toast('Préparation du PDF…');
    final done = await sharePdf(name, build);
    _pdfBusy = false;
    if (_disposed) return;
    toast(done ? ok : 'Le PDF n’a pas pu être généré sur cet appareil');
  }

  /// Quittance d'un mois déjà payé ([paidOn] : « 3 oct. »).
  void receipt(String month, String paidOn) => _pdf(
    'Quittance Sarah M. $month',
    () => buildQuittances([
      Quittance(
        tenant: 'Sarah M.',
        room: 'A-102',
        building: 'Immeuble A · Les Lauriers',
        month: month,
        amount: formatFcfa(rent),
        paidOn: '$paidOn ${month.split(' ').last}',
      ),
    ]),
    'Quittance de ${month.toLowerCase()} générée (PDF)',
  );

  void lease() => _pdf(
    'Contrat de bail A-102',
    () => buildBail(
      tenant: 'Sarah M.',
      room: 'A-102',
      building: 'Immeuble A · Les Lauriers',
      rent: formatFcfa(rent),
      start: '1 septembre 2025',
      duration: '24 mois, jusqu’au 31 août 2027',
      signedOn: '28 août 2025',
    ),
    'Contrat de bail généré (PDF)',
  );

  void go(String s) {
    _t?.cancel();
    screen = s;
    loading = s != 'report';
    notifyListeners();
    if (loading) {
      _t = Timer(const Duration(milliseconds: 450), () {
        loading = false;
        notifyListeners();
      });
    }
  }

  void startReport() {
    step = 1;
    cat = null;
    desc = '';
    descError = false;
    urg = 'mid';
    go('report');
  }

  Cat get selCat => cats.firstWhere((c) => c.key == cat, orElse: () => cats.first);
  Urg get selUrg => urgencies.firstWhere((u) => u.key == urg);

  void pickCat(String k) {
    cat = k;
    notifyListeners();
    _later(180, () {
      step = 2;
      notifyListeners();
    });
  }

  void setDesc(String v) {
    desc = v;
    if (descError) {
      descError = false;
      notifyListeners();
    }
  }

  void setUrg(String k) {
    urg = k;
    notifyListeners();
  }

  void stepBack() {
    if (step == 1) {
      go('home');
    } else {
      step--;
      notifyListeners();
    }
  }

  void next() {
    if (step == 2 && desc.trim().length < 5) {
      descError = true;
      notifyListeners();
      return;
    }
    if (step == 3) {
      sending = true;
      notifyListeners();
      _later(900, () {
        final c = selCat;
        final t = desc.trim();
        myReports.insert(
          0,
          MyReport(
            'new${DateTime.now().millisecondsSinceEpoch}',
            t.isEmpty ? c.label : (t.length > 42 ? t.substring(0, 42) : t),
            c.label,
            c.icon,
            c.tone,
            'Aujourd’hui',
            1,
            'Votre bailleur a été prévenu.',
          ),
        );
        sending = false;
        step = 4;
        notifyListeners();
      });
      return;
    }
    step++;
    notifyListeners();
  }

  void rate(MyReport m, int i) {
    m.rated = i;
    notifyListeners();
    toast('Merci pour votre avis');
  }

  int get openReports => myReports.where((m) => m.step < 3).length;
  int get unread => notifs.where((n) => n.unread).length;

  void openNotif(Notif n) {
    n.unread = false;
    go(n.go);
  }

  void markAll() {
    for (final n in notifs) {
      n.unread = false;
    }
    notifyListeners();
  }

  void toggleRule(int i) {
    openRule = openRule == i ? -1 : i;
    notifyListeners();
  }

  void togglePref(String k) {
    prefs[k] = !(prefs[k] ?? false);
    notifyListeners();
  }

  /// Le locataire envoie un justificatif : le loyer passe « En vérification ».
  void proofSent(int amount) {
    pending = true;
    sentAmt = amount;
    notifyListeners();
    toast('Justificatif de ${formatFcfa(amount)} envoyé · votre bailleur va le vérifier');
  }

  // ─── Statut du loyer ───
  ({bool unpaid, String label, IconData icon, Tone tone, String due, String balance}) get rentStatus {
    if (pending) {
      return (
        unpaid: false,
        label: 'En vérification',
        icon: PI.listChecks,
        tone: Tone.neutral,
        due: 'Justificatif de ${formatFcfa(sentAmt)} envoyé · en attente du bailleur',
        balance: formatFcfa(rent),
      );
    }
    if (paid) {
      return (unpaid: false, label: 'Payé', icon: PI.checkCircle, tone: Tone.paid, due: 'Prochaine échéance : 5 décembre', balance: formatFcfa(0));
    }
    return (unpaid: true, label: 'À payer', icon: PI.clock, tone: Tone.neutral, due: 'À payer avant demain, 5 novembre', balance: formatFcfa(rent));
  }

  ({String label, IconData icon, Tone tone, String text}) get payStatus {
    if (pending) {
      return (label: 'En vérification', icon: PI.listChecks, tone: Tone.neutral, text: 'Justificatif envoyé, en attente du bailleur');
    }
    if (paid) return (label: 'À jour', icon: PI.checkCircle, tone: Tone.paid, text: 'Prochaine échéance le 5 décembre');
    return (label: 'À payer', icon: PI.clock, tone: Tone.neutral, text: 'Loyer de novembre à payer avant le 5');
  }

  String get paidYear => formatFcfa((paid ? 11 : 10) * rent);
}
