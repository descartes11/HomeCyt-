import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/pdf_docs.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/ui.dart';

String fmt(num n) => formatFcfa(n);
String initialsOf(String name) => name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).join().replaceAll('.', '');

const avatarTones = [Tone.strong, Tone.neutral, Tone.pale, Tone.magSoft];

class Proof {
  const Proof(this.amount, this.date);
  final int amount;
  final String date;
}

class Tenant {
  Tenant({
    required this.id,
    required this.name,
    required this.job,
    required this.org,
    required this.room,
    required this.bld,
    required this.rent,
    required this.paid,
    this.days,
    this.method = '—',
    this.date,
    this.proof,
    required this.since,
    required this.lease,
    required this.idDoc,
    required this.emergency,
    required this.email,
    required this.phone,
    required this.index,
  });
  final String id, name, job, org, room, bld, since, lease, idDoc, emergency, email, phone;
  final int rent, index;
  int paid;
  int? days;
  String method;
  String? date;
  Proof? proof;

  String get initials => initialsOf(name);
  Tone get avatar => avatarTones[index % 4];
  String get bldName => 'Immeuble $bld';
  String get rentF => fmt(rent);
}

/// Vue calculée d'un locataire pour un mois donné (statut, badge, détail).
class TView {
  TView(this.t, {required this.past});
  final Tenant t;
  final bool past;

  int get paid => past ? t.rent : t.paid;
  String get st => paid >= t.rent ? 'paid' : (paid > 0 ? 'partial' : 'late');
  bool get hasProof => !past && t.proof != null && paid < t.rent;
  bool get isPaid => st == 'paid';
  bool get canRemind => st != 'paid' && !hasProof;

  ({String label, IconData icon, Tone tone}) get badge {
    if (hasProof) return (label: 'À vérifier', icon: PI.listChecks, tone: Tone.neutral);
    return switch (st) {
      'paid' => (label: 'Payé', icon: PI.checkCircle, tone: Tone.paid),
      'partial' => (label: 'Partiel', icon: PI.hourglassMedium, tone: Tone.neutral),
      _ => (label: 'En retard', icon: PI.clock, tone: Tone.late),
    };
  }

  String get detail {
    if (hasProof) return 'Justificatif de ${fmt(t.proof!.amount)} à vérifier';
    return switch (st) {
      'paid' => past ? 'Payé à temps' : 'Payé le ${t.date ?? '4 nov.'}',
      'partial' => 'Reste ${fmt(t.rent - paid)}',
      _ => t.days != null ? '${t.days} jours de retard' : 'En retard',
    };
  }

  String get paidF => fmt(paid);
  String get dueF => fmt(t.rent - paid);
  String get method => hasProof ? 'Reçu à vérifier' : (paid > 0 ? 'Reçu validé' : '—');
}

class Msg {
  const Msg(this.me, this.text, this.time);
  final bool me;
  final String text, time;
}

class Report {
  Report(this.id, this.title, this.cat, this.room, this.tenantName, this.tenantId, this.when, this.date, this.u, this.st, this.tech, this.desc, this.msgs);
  final String id, title, cat, room, tenantName, when, date, desc;
  final String? tenantId;
  final String u; // urgent · mid · low
  String st; // new · doing · done
  String tech;
  final List<Msg> msgs;
}

class Registration {
  const Registration(this.id, this.job, this.org, this.name, this.phone, this.email, this.cni, this.room, this.date);
  final String id, job, org, name, phone, email, cni, room, date;
  String get initials => initialsOf(name);
}

class Ann {
  const Ann(this.title, this.body, this.target, this.when, this.icon, this.reads);
  final String title, body, target, when, reads;
  final IconData icon;
}

class RoomInfo {
  RoomInfo({required this.id, required this.bld, required this.floor, required this.st, required this.tenant, required this.tenantName, required this.rent});
  final String id, bld, st, tenantName;
  final int floor, rent;
  final Tenant? tenant;

  String get bldName => 'Immeuble $bld · ${bNames[bld]}';
  String get floorLabel => floor == 1 ? '1er étage' : '${floor}e étage';
  String get type => rent <= 35000 ? 'Simple' : (rent <= 50000 ? 'Studio' : 'Appartement');
  bool get hasTenant => tenantName.isNotEmpty;
  bool get isFree => st == 'free';
  String get rentF => fmt(rent);
  RoomStyle get style => roomStyles[st]!;
}

class RoomStyle {
  const RoomStyle(this.label, this.bg, this.border, this.fg, this.icon, this.darkBg, this.darkFg, {this.darkBorder});
  final String label;
  final Color bg, border, fg, darkBg, darkFg;
  final Color? darkBorder;

  Color borderOf(bool dark) => dark ? (darkBorder ?? border) : border;
  final IconData icon;
}

/// Tuiles de chambre (fond / bordure 2 px / texte).
const roomStyles = {
  // Libre : fond clair, bordure fine. Occupée : aplat foncé, texte clair — distinction immédiate.
  'free': RoomStyle('Libre', AppColors.n100, AppColors.a500, AppColors.a800, PI.doorOpen, AppColors.n800, AppColors.a200),
  'occ': RoomStyle('Occupée', AppColors.a700, AppColors.a700, AppColors.n100, PI.user, AppColors.a400, AppColors.n900, darkBorder: AppColors.a400),
  'works': RoomStyle('En travaux', AppColors.n200, AppColors.n500, AppColors.n800, PI.trafficCone, AppColors.n700, AppColors.n200),
  'late': RoomStyle('Loyer en retard', AppColors.m200, AppColors.accent2, AppColors.m800, PI.clock, Color(0xFF5E1A33), AppColors.m200),
};

const bNames = {'A': 'Les Lauriers', 'B': 'Les Acacias', 'C': 'Les Manguiers'};
const bAddr = {'A': 'Rue 12, quartier Centre', 'B': 'Avenue 4, quartier Nord', 'C': 'Rue 30, quartier Est'};
const floorsOf = {
  'A': [1, 2, 3],
  'B': [1, 2, 3, 4],
  'C': [1, 2],
};
const perFloor = {'A': 6, 'B': 4, 'C': 7};
const freeRooms = ['A-104', 'B-302', 'C-105', 'B-401'];
const worksRooms = ['A-306', 'C-202'];
const pool = ['Kevin O.', 'Aline R.', 'Junior B.', 'Nadia F.', 'Eric D.', 'Clarisse M.', 'Hugo T.', 'Inès K.', 'Samuel A.', 'Léa N.', 'Omar B.', 'Judith E.'];
const equipByType = {
  'Simple': ['Lit', 'Bureau', 'Ventilateur', 'Compteur prépayé'],
  'Studio': ['Lit', 'Bureau', 'Armoire', 'Ventilateur', 'Douche interne', 'Compteur prépayé', 'Wi-Fi'],
  'Appartement': ['Lit double', 'Bureau', 'Armoire', 'Climatisation', 'Douche interne', 'Cuisine équipée', 'Compteur prépayé', 'Wi-Fi'],
};
const allEquip = ['Lit', 'Bureau', 'Armoire', 'Ventilateur', 'Climatisation', 'Douche interne', 'Cuisine équipée', 'Compteur prépayé', 'Wi-Fi'];

const catStyle = {
  'Plomberie': (PI.drop, Tone.neutral),
  'Électricité': (PI.lightning, Tone.neutral),
  'Serrure et porte': (PI.lock, Tone.neutral),
  'Propreté': (PI.broom, Tone.paid),
  'Sécurité': (PI.shield, Tone.late),
  'Voisinage': (PI.usersThree, Tone.magSoft),
  'Autre': (PI.dotsThree, Tone.muted),
};
const urgStyle = {
  'urgent': ('Urgent', Tone.late, PI.warning),
  'mid': ('Moyen', Tone.neutral, PI.cellSignalMedium),
  'low': ('Faible', Tone.muted, PI.cellSignalLow),
};
const repStatus = {'new': ('Nouveau', Tone.neutral, PI.sparkle), 'doing': ('En cours', Tone.neutral, PI.wrench), 'done': ('Résolu', Tone.paid, PI.checkCircle)};
const techs = ['Non assigné', 'Alain (électricien)', 'Bruno (plombier)', 'Joseph K. (gardien)'];
const annTypes = [
  ('water', 'Coupure d’eau', PI.drop),
  ('power', 'Coupure d’électricité', PI.lightning),
  ('meet', 'Réunion', PI.usersThree),
  ('works', 'Travaux', PI.trafficCone),
  ('other', 'Autre', PI.megaphone),
];
const chartData = [('Juin', 1410), ('Juil.', 1520), ('Août', 1480), ('Sept.', 1610), ('Oct.', 1590)];
const months = ['Novembre 2026', 'Octobre 2026', 'Septembre 2026', 'Août 2026', 'Juillet 2026', 'Juin 2026'];

List<Tenant> _seedTenants() {
  var i = 0;
  Tenant t(
    String id,
    String name,
    String job,
    String org,
    String room,
    String bld,
    int rent,
    int paid, {
    int? days,
    String method = '—',
    String? date,
    Proof? proof,
    required String since,
    required String lease,
    required String idDoc,
    required String emergency,
    required String email,
    required String phone,
  }) => Tenant(
    id: id,
    name: name,
    job: job,
    org: org,
    room: room,
    bld: bld,
    rent: rent,
    paid: paid,
    days: days,
    method: method,
    date: date,
    proof: proof,
    since: since,
    lease: lease,
    idDoc: idDoc,
    emergency: emergency,
    email: email,
    phone: phone,
    index: i++,
  );
  return [
    t(
      'dk',
      'David K.',
      'Salarié',
      'Banque Atlantique',
      'B-204',
      'B',
      60000,
      0,
      days: 12,
      since: '1 mars 2025',
      lease: '12 mois, jusqu’au 28 févr. 2027',
      idDoc: 'CNI n° 0000 4521 7783',
      emergency: 'Jeanne K. (mère) · 07 98 76 54 32',
      email: 'david.k@mail.com',
      phone: '07 12 34 56 01',
    ),
    t(
      'sm',
      'Sarah M.',
      'Étudiante',
      'Université, licence 3',
      'A-102',
      'A',
      45000,
      45000,
      method: 'Justificatif validé',
      date: '2 nov.',
      since: '1 sept. 2025',
      lease: '24 mois, jusqu’au 31 août 2027',
      idDoc: 'Passeport n° 00A 112 908',
      emergency: 'Paul M. (frère) · 07 22 11 00 99',
      email: 'sarah.m@mail.com',
      phone: '07 12 34 56 02',
    ),
    t(
      'fb',
      'Fatou B.',
      'Étudiante',
      'École de commerce',
      'A-305',
      'A',
      35000,
      35000,
      method: 'Justificatif validé',
      date: '1 nov.',
      since: '15 janv. 2026',
      lease: '6 mois renouvelables',
      idDoc: 'CNI n° 0000 8810 2231',
      emergency: 'Awa B. (sœur) · 07 45 67 89 10',
      email: 'fatou.b@mail.com',
      phone: '07 12 34 56 03',
    ),
    t(
      'pn',
      'Paul N.',
      'Fonctionnaire',
      'Ministère de la Santé',
      'A-203',
      'A',
      45000,
      0,
      days: 8,
      proof: const Proof(45000, '4 nov. · 09:12'),
      since: '1 oct. 2024',
      lease: '36 mois, jusqu’au 30 sept. 2027',
      idDoc: 'CNI n° 0000 3345 6619',
      emergency: 'Marc N. (père) · 07 33 44 55 66',
      email: 'paul.n@mail.com',
      phone: '07 12 34 56 04',
    ),
    t(
      'ga',
      'Grace A.',
      'Commerçante',
      'Marché central',
      'C-103',
      'C',
      35000,
      20000,
      method: 'Justificatif validé',
      date: '3 nov.',
      proof: const Proof(15000, '4 nov. · 18:40'),
      since: '1 févr. 2026',
      lease: '12 mois, jusqu’au 31 janv. 2027',
      idDoc: 'CNI n° 0000 9902 1145',
      emergency: 'Esther A. (mère) · 07 66 55 44 33',
      email: 'grace.a@mail.com',
      phone: '07 12 34 56 05',
    ),
    t(
      'is',
      'Ibrahim S.',
      'Travailleur indépendant',
      'Graphiste',
      'B-110',
      'B',
      50000,
      50000,
      method: 'Justificatif validé',
      date: '4 nov.',
      since: '1 juin 2025',
      lease: '24 mois, jusqu’au 31 mai 2027',
      idDoc: 'Passeport n° 00B 774 120',
      emergency: 'Moussa S. (oncle) · 07 11 22 33 44',
      email: 'ibrahim.s@mail.com',
      phone: '07 12 34 56 06',
    ),
    t(
      'ml',
      'Marie L.',
      'Salariée',
      'Clinique du Centre',
      'C-201',
      'C',
      40000,
      40000,
      method: 'Justificatif validé',
      date: '1 nov.',
      since: '1 avr. 2026',
      lease: '12 mois, jusqu’au 31 mars 2027',
      idDoc: 'CNI n° 0000 5567 0012',
      emergency: 'Luc L. (père) · 07 99 88 77 66',
      email: 'marie.l@mail.com',
      phone: '07 12 34 56 07',
    ),
    t(
      'yt',
      'Yann T.',
      'Étudiant',
      'Institut polytechnique',
      'B-301',
      'B',
      45000,
      0,
      days: 3,
      since: '1 août 2026',
      lease: '12 mois, jusqu’au 31 juil. 2027',
      idDoc: 'CNI n° 0000 2210 8873',
      emergency: 'Rose T. (mère) · 07 10 20 30 40',
      email: 'yann.t@mail.com',
      phone: '07 12 34 56 08',
    ),
  ];
}

List<Report> _seedReports() => [
  Report(
    's1',
    'Fuite sous l’évier',
    'Plomberie',
    'A-102',
    'Sarah M.',
    'sm',
    'il y a 2 h',
    '4 nov. · 07:30',
    'urgent',
    'new',
    '',
    'L’eau coule sous l’évier depuis ce matin, le placard du bas est mouillé.',
    [const Msg(false, 'Bonjour, l’eau coule sous l’évier depuis ce matin. J’ai mis une bassine.', '07:30')],
  ),
  Report(
    's2',
    'Prise électrique hors service',
    'Électricité',
    'B-204',
    'David K.',
    'dk',
    'hier',
    '3 nov. · 19:12',
    'mid',
    'doing',
    'Alain (électricien)',
    'La prise à côté du bureau ne marche plus depuis la coupure d’hier soir.',
    [
      const Msg(false, 'La prise du bureau ne fonctionne plus.', 'Hier 19:12'),
      const Msg(true, 'Merci, j’envoie Alain demain matin.', 'Hier 20:05'),
      const Msg(false, 'D’accord, je serai là après 9 h.', 'Hier 20:10'),
    ],
  ),
  Report(
    's3',
    'Serrure bloquée',
    'Serrure et porte',
    'C-103',
    'Grace A.',
    'ga',
    'hier',
    '3 nov. · 22:40',
    'urgent',
    'new',
    '',
    'La clé tourne dans le vide, je n’arrive plus à fermer la porte.',
    [const Msg(false, 'Je ne peux plus fermer ma porte à clé.', 'Hier 22:40')],
  ),
  Report(
    's4',
    'Ampoule du couloir',
    'Électricité',
    'Couloir A, 2e',
    'Joseph K. (gardien)',
    null,
    '2 nov.',
    '2 nov. · 18:00',
    'low',
    'new',
    '',
    'L’ampoule du couloir du 2e étage est grillée.',
    [const Msg(false, 'Ampoule grillée au 2e étage.', '2 nov.')],
  ),
  Report(
    's6',
    'Poubelles non ramassées',
    'Propreté',
    'Cour, immeuble B',
    'Ibrahim S.',
    'is',
    '1 nov.',
    '1 nov. · 10:15',
    'mid',
    'doing',
    'Joseph K. (gardien)',
    'Les bacs de la cour débordent depuis trois jours.',
    [const Msg(false, 'Les bacs débordent.', '1 nov.'), const Msg(true, 'Le service de ramassage passe demain.', '1 nov.')],
  ),
  Report(
    's8',
    'Moustiquaire déchirée',
    'Autre',
    'C-201',
    'Marie L.',
    'ml',
    '31 oct.',
    '31 oct. · 16:20',
    'low',
    'new',
    '',
    'La moustiquaire de la fenêtre est déchirée sur 20 cm.',
    [const Msg(false, 'La moustiquaire est déchirée.', '31 oct.')],
  ),
  Report(
    's5',
    'Robinet qui goutte',
    'Plomberie',
    'A-102',
    'Sarah M.',
    null,
    '12 oct.',
    '12 oct. · 08:00',
    'low',
    'done',
    'Bruno (plombier)',
    'Le robinet de la douche goutte en continu.',
    [const Msg(false, 'Le robinet goutte.', '12 oct.'), const Msg(true, 'Joint remplacé, merci de confirmer.', '14 oct.')],
  ),
  Report(
    's7',
    'Fenêtre qui ferme mal',
    'Autre',
    'B-110',
    'Ibrahim S.',
    null,
    '5 oct.',
    '5 oct. · 12:00',
    'low',
    'done',
    'Joseph K. (gardien)',
    'La fenêtre de la chambre ne ferme plus complètement.',
    [const Msg(false, 'La fenêtre ferme mal.', '5 oct.')],
  ),
];

/// État « Ajouter un locataire » (3 étapes + succès).
class AddTenantState {
  int step = 1;
  String name = '', phone = '', idn = '';
  String room = '';
  int dur = 12;
  bool err = false;
}

/// État du formulaire de chambre.
class RoomFormState {
  RoomFormState({
    this.num = '',
    this.floor = '1',
    this.type = 'Simple',
    this.rent = '35 000',
    List<String>? equip,
    this.status = 'free',
    this.editing = false,
    this.bld = 'A',
  }) : equip = equip ?? ['Lit', 'Bureau', 'Ventilateur'];
  String num, floor, type, rent, status, bld;
  List<String> equip;
  bool editing;
  bool err = false;
}

/// État de l'espace bailleur (équivalent de la logique de la maquette).
class LandlordStore extends ChangeNotifier {
  String screen = 'dashboard', prev = 'dashboard';
  bool fromMore = false, loading = true;
  final tenants = _seedTenants();
  String selId = 'dk';
  String query = '', tFilter = 'all', bFilter = 'all', rFilter = 'all';
  int monthIdx = 0;
  final notes = <String, String>{'dk': 'Préfère être contacté par message après 18 h.'};
  String bSel = 'A', roomSel = 'A-102';
  final reports = _seedReports();
  String repSel = 's1', rTab = 'new';
  final anns = <Ann>[
    const Ann('Coupure d’eau jeudi', 'De 9 h à 12 h dans l’immeuble A. Pensez à faire vos réserves.', 'Immeuble A', 'Hier', PI.drop, '14/16 lus'),
    const Ann(
      'Réunion des locataires',
      'Samedi 14 novembre à 10 h, dans la cour. Ordre du jour : propreté et sécurité.',
      'Toute la cité',
      '2 nov.',
      PI.usersThree,
      '38/44 lus',
    ),
    const Ann(
      'Peinture des couloirs',
      'Travaux du 16 au 20 novembre, 2e étage. Merci de laisser les couloirs dégagés.',
      'Immeuble A',
      '30 oct.',
      PI.paintRoller,
      '16/16 lus',
    ),
  ];
  String annTarget = 'all', annType = 'water';
  final regs = <Registration>[
    const Registration(
      'r1',
      'Étudiante',
      'Université, master 1',
      'Aïcha D.',
      '07 45 12 98 30',
      'aicha.d@mail.com',
      '0000 7731 4402',
      'A-104',
      'aujourd’hui, 08:20',
    ),
    const Registration('r2', 'Salarié', 'Entreprise de télécoms', 'Kofi M.', '07 66 21 03 57', 'kofi.m@mail.com', '0000 1290 8815', 'B-302', 'hier, 17:45'),
  ];
  final bp = {'auto': true, 'j3': true, 'rep': true, 'sms': true};
  AddTenantState at = AddTenantState();
  RoomFormState rf = RoomFormState();

  void Function(String msg)? toaster;
  Timer? _t;

  LandlordStore() {
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

  void toast(String m) => toaster?.call(m);
  void refresh() => notifyListeners();

  void go(String s, {bool? more}) {
    _t?.cancel();
    prev = screen;
    screen = s;
    if (more != null) fromMore = more;
    loading = true;
    notifyListeners();
    _t = Timer(const Duration(milliseconds: 450), () {
      loading = false;
      notifyListeners();
    });
  }

  void set(VoidCallback f) {
    f();
    notifyListeners();
  }

  // ─── Locataires et loyers ───
  List<TView> get list => [for (final t in tenants) TView(t, past: false)];
  List<TView> get rentsAll => [for (final t in tenants) TView(t, past: monthIdx > 0)];
  TView get sel => list.firstWhere((v) => v.t.id == selId, orElse: () => list.first);
  List<TView> get late => list.where((v) => !v.isPaid).toList();
  List<TView> get proofs => list.where((v) => v.hasProof).toList();

  int get collected => 1070000 + list.fold(0, (a, v) => a + (v.t.paid < v.t.rent ? v.t.paid : v.t.rent));
  int get expected => 1070000 + list.fold(0, (a, v) => a + v.t.rent);
  int get unpaid => list.fold(0, (a, v) => a + (v.t.rent - (v.t.paid < v.t.rent ? v.t.paid : v.t.rent)));
  double get rate => collected / expected;

  List<TView> get tenantList {
    final q = query.trim().toLowerCase();
    return list
        .where(
          (v) =>
              (q.isEmpty || '${v.t.name} ${v.t.room}'.toLowerCase().contains(q)) &&
              (tFilter == 'all' || (tFilter == 'ok' ? v.isPaid : !v.isPaid)) &&
              (bFilter == 'all' || v.t.bld == bFilter),
        )
        .toList();
  }

  List<TView> get rentList => rentsAll.where((v) => (rFilter == 'all' || v.st == rFilter) && (bFilter == 'all' || v.t.bld == bFilter)).toList();
  int rentCount(String st) => rentsAll.where((v) => v.st == st).length;
  int get rExpected => rentsAll.fold(0, (a, v) => a + v.t.rent);
  int get rPaid => rentsAll.fold(0, (a, v) => a + (v.paid < v.t.rent ? v.paid : v.t.rent));

  void openTenant(String id) {
    selId = id;
    go('tenant');
  }

  void remind(TView v) => toast('Relance envoyée par SMS à ${v.t.name}');
  // ─── Quittances (PDF) ───
  String _paidOn(Tenant t, int i) => i == 0 ? '${t.date ?? '4 nov.'} 2026' : '${2 + i % 3} ${months[i].toLowerCase()}';

  Quittance _quittance(Tenant t, int i) =>
      Quittance(tenant: t.name, room: t.room, building: '${t.bldName} · ${bNames[t.bld]}', month: months[i], amount: t.rentF, paidOn: _paidOn(t, i));

  /// Quittance du locataire pour le mois affiché.
  void receipt(TView v) => receiptFor(v.t, monthIdx);

  /// Quittance d'un locataire pour le mois [i] (0 = mois en cours).
  void receiptFor(Tenant t, int i) {
    final m = i.clamp(0, months.length - 1);
    _pdf('Quittance ${t.name} ${months[m]}', () => buildQuittances([_quittance(t, m)]), 'Quittance PDF de ${t.name} générée');
  }

  /// Toutes les quittances du mois affiché (une page par locataire à jour).
  void receiptsOfMonth() {
    final paid = rentsAll.where((v) => v.isPaid).toList();
    if (paid.isEmpty) {
      toast('Aucun loyer entièrement payé pour ${months[monthIdx].toLowerCase()}');
      return;
    }
    _pdf(
      'Quittances ${months[monthIdx]}',
      () => buildQuittances([for (final v in paid) _quittance(v.t, monthIdx)]),
      '${paid.length} quittances de ${months[monthIdx].toLowerCase()} générées (PDF)',
    );
  }

  void approveProof(String id) {
    final t = tenants.firstWhere((x) => x.id == id);
    final p = t.proof;
    if (p == null) return;
    t.paid = (t.paid + p.amount).clamp(0, t.rent);
    t.proof = null;
    t.method = 'Justificatif validé';
    t.date = '4 nov.';
    notifyListeners();
    toast('Paiement de ${fmt(p.amount)} validé · quittance envoyée à ${t.name}');
  }

  void rejectProof(String id) {
    final t = tenants.firstWhere((x) => x.id == id);
    t.proof = null;
    notifyListeners();
    toast('Justificatif refusé · ${t.name} est prévenu(e)');
  }

  void approveReg(Registration g) {
    regs.remove(g);
    notifyListeners();
    toast('Inscription de ${g.name} validée · chambre ${g.room} attribuée');
  }

  void rejectReg(Registration g) {
    regs.remove(g);
    notifyListeners();
    toast('Demande de ${g.name} refusée · un SMS l’en informe');
  }

  List<(String, String, String, ({String label, IconData icon, Tone tone}), bool)> historyOf(TView v) => [
    for (var i = 0; i < months.length; i++)
      (
        months[i],
        v.t.rentF,
        i == 0 ? v.detail : 'Le ${2 + i % 3} · Reçu validé',
        i == 0 ? v.badge : (label: 'Payé', icon: PI.checkCircle, tone: Tone.paid),
        i == 0 ? v.isPaid : true,
      ),
  ];

  // ─── Immeubles et chambres ───
  RoomInfo roomData(String id) {
    final b = id[0];
    final f = int.parse(id[2]);
    final i = int.parse(id.substring(3)) - 1;
    Tenant? t;
    for (final x in tenants) {
      if (x.room == id) t = x;
    }
    final isPaid = t != null && TView(t, past: false).isPaid;
    final st = freeRooms.contains(id) ? 'free' : (worksRooms.contains(id) ? 'works' : (t != null && !isPaid ? 'late' : 'occ'));
    final tn = t?.name ?? ((st == 'occ' || st == 'late') ? pool[(f * 7 + i * 3 + b.codeUnitAt(0)) % pool.length] : '');
    final rent = t?.rent ?? const [35000, 45000, 60000][(i + f) % 3];
    return RoomInfo(id: id, bld: b, floor: f, st: st, tenant: t, tenantName: tn, rent: rent);
  }

  List<(String, List<RoomInfo>)> floors(String b) => [
    for (final f in floorsOf[b]!.reversed)
      (f == 1 ? '1er étage' : '${f}e étage', [for (var i = 0; i < perFloor[b]!; i++) roomData('$b-$f${(i + 1).toString().padLeft(2, '0')}')]),
  ];

  List<RoomInfo> allRooms(String b) => floors(b).expand((f) => f.$2).toList();

  ({String id, String name, String addr, int rooms, int floors, int pct, int late, int occ}) building(String b) {
    final rs = allRooms(b);
    final occ = rs.where((r) => r.st == 'occ' || r.st == 'late').length;
    final late = rs.where((r) => r.st == 'late').length;
    return (
      id: b,
      name: 'Immeuble $b · ${bNames[b]}',
      addr: bAddr[b]!,
      rooms: rs.length,
      floors: floorsOf[b]!.length,
      pct: (occ / rs.length * 100).round(),
      late: late,
      occ: occ,
    );
  }

  void openRoom(String id) {
    roomSel = id;
    go('room');
  }

  void addRoom() {
    rf = RoomFormState(bld: bSel);
    go('roomForm');
  }

  void editRoom() {
    final r = roomData(roomSel);
    rf = RoomFormState(
      num: r.id,
      floor: '${r.floor}',
      type: r.type,
      rent: formatNumber(r.rent),
      equip: equipByType[r.type]!.where(allEquip.contains).toList(),
      status: r.st == 'works' ? 'works' : 'free',
      editing: true,
      bld: r.bld,
    );
    go('roomForm');
  }

  void saveRoom() {
    if (rf.num.trim().isEmpty || parseAmount(rf.rent) == 0) {
      rf.err = true;
      notifyListeners();
      return;
    }
    go(rf.editing ? 'room' : 'building');
    toast(rf.editing ? 'Chambre ${rf.num} mise à jour' : 'Chambre ${rf.num} ajoutée à l’immeuble ${rf.bld}');
  }

  void cancelRoom() => go(rf.editing ? 'room' : 'building');

  // ─── Ajouter un locataire ───
  void newTenant({String room = ''}) {
    at = AddTenantState()..room = room;
    go('addTenant');
  }

  void atNext() {
    if (at.step == 1 && (at.name.trim().isEmpty || at.phone.replaceAll(RegExp(r'\D'), '').length < 8)) {
      at.err = true;
    } else if (at.step == 2 && at.room.isEmpty) {
      at.err = true;
    } else {
      at.step++;
      at.err = false;
    }
    notifyListeners();
  }

  void atBack() {
    if (at.step == 1) {
      go(const ['addTenant', 'soon'].contains(prev) ? 'tenants' : prev);
    } else {
      at.step--;
      at.err = false;
      notifyListeners();
    }
  }

  // ─── Signalements ───
  Report get rep => reports.firstWhere((r) => r.id == repSel, orElse: () => reports.first);
  List<Report> get pending => reports.where((r) => r.st != 'done').toList();
  int get urgentCount => pending.where((r) => r.u == 'urgent').length;

  void openReport(String id) {
    repSel = id;
    go('report');
  }

  void setRepStatus(String st) {
    rep.st = st;
    notifyListeners();
    toast('Statut : ${repStatus[st]!.$1} · ${rep.tenantName} est notifié(e)');
  }

  void setTech(String t) {
    final r = rep;
    r.tech = t == 'Non assigné' ? '' : t;
    if (t != 'Non assigné' && r.st == 'new') r.st = 'doing';
    notifyListeners();
    if (t != 'Non assigné') toast('Assigné à $t');
  }

  void sendChat(String txt) {
    final t = txt.trim();
    if (t.isEmpty) return;
    final r = rep;
    r.msgs.add(Msg(true, t, 'À l’instant'));
    notifyListeners();
    Timer(const Duration(milliseconds: 1600), () {
      if (_disposed) return; // espace quitté avant la réponse
      r.msgs.add(const Msg(false, 'Merci, c’est noté !', 'À l’instant'));
      notifyListeners();
    });
  }

  // ─── Annonces ───
  int get occTotal => ['A', 'B', 'C'].fold(0, (a, b) => a + building(b).occ);
  int get targetCount => annTarget == 'all' ? occTotal : building(annTarget).occ;

  bool sendAnn(String title, String body) {
    if (title.trim().isEmpty) return false;
    final tgt = annTarget == 'all' ? 'Toute la cité' : 'Immeuble $annTarget';
    final ic = annTypes.firstWhere((a) => a.$1 == annType, orElse: () => annTypes.last).$3;
    anns.insert(0, Ann(title.trim(), body.trim().isEmpty ? '—' : body.trim(), tgt, 'À l’instant', ic, '0/$targetCount lus'));
    notifyListeners();
    toast('Annonce envoyée à $targetCount locataires');
    return true;
  }

  // ─── PDF ───
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

  FicheLocataire _fiche(Tenant t) {
    final v = TView(t, past: false);
    return FicheLocataire(
      name: t.name,
      status: '${v.badge.label} · ${v.detail}',
      rows: [
        ('Chambre', '${t.room} · ${t.bldName} · ${bNames[t.bld]}'),
        ('Loyer mensuel', t.rentF),
        ('Payé ce mois', v.paidF),
        ('Reste dû', v.dueF),
        ('Fonction', t.job),
        ('Établissement ou employeur', t.org),
        ('Téléphone', t.phone),
        ('E-mail', t.email),
        ('Pièce d’identité', t.idDoc),
        ('Dans la cité depuis', t.since),
        ('Bail', t.lease),
        ('Contact d’urgence', t.emergency),
      ],
      note: notes[t.id],
    );
  }

  void pdfOne() {
    final t = sel.t;
    _pdf('Fiche ${t.name}', () => buildFiches([_fiche(t)]), 'Fiche de ${t.name} : PDF généré');
  }

  void pdfAll() =>
      _pdf('Fiches locataires $kCityName', () => buildFiches([for (final t in tenants) _fiche(t)]), 'Dossier des ${tenants.length} locataires : PDF généré');
}
