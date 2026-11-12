import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/accounts.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/fields.dart';
import '../../widgets/ui.dart';

// ───────────────────────────── Données ─────────────────────────────

class _Onb {
  const _Onb(this.kicker, this.icon, this.title, this.text, this.ph);
  final String kicker, title, text, ph;
  final IconData icon;
}

const _onb = [
  _Onb(
    'Bailleurs',
    PI.bed,
    'Gérez vos chambres',
    'Immeubles, étages et chambres au même endroit, avec le statut de chaque chambre en un coup d’œil.',
    'Illustration : plan des chambres',
  ),
  _Onb(
    'Bailleurs',
    PI.users,
    'Suivez vos locataires',
    'Le locataire envoie son reçu et le montant payé, vous validez. Quittances et relances, sans tableur.',
    'Illustration : suivi des loyers',
  ),
  _Onb(
    'Locataires',
    PI.megaphone,
    'Signalez un problème en un clic',
    'Fuite, panne ou serrure : le locataire déclare, le bailleur suit jusqu’à la résolution.',
    'Illustration : signalement',
  ),
];

class _City {
  const _City(this.id, this.name, this.area, this.owner, this.rooms);
  final String id, name, area, owner;
  final List<String> rooms;
  String get free => '${rooms.length} chambre${rooms.length > 1 ? 's' : ''} libre${rooms.length > 1 ? 's' : ''}';
}

const _cities = [
  _City('jardins', 'Cité Les Jardins', 'Quartier Centre', 'Daniel A.', [
    'A-104 · Studio · 45 000 FCFA',
    'B-302 · Simple · 35 000 FCFA',
    'B-401 · Studio · 45 000 FCFA',
    'C-105 · Simple · 35 000 FCFA',
  ]),
  _City('palmiers', 'Résidence Les Palmiers', 'Quartier Nord', 'Mireille K.', ['P-03 · Simple · 30 000 FCFA', 'P-11 · Studio · 50 000 FCFA']),
  _City('horizon', 'Cité Horizon', 'Campus universitaire', 'Serge B.', [
    'H-12 · Simple · 25 000 FCFA',
    'H-20 · Simple · 25 000 FCFA',
    'H-31 · Studio · 40 000 FCFA',
  ]),
  _City('baobab', 'Cité Le Baobab', 'Quartier Est', 'Awa T.', ['1-02 · Appartement · 75 000 FCFA']),
];

const _jobs = ['Étudiant(e)', 'Salarié(e)', 'Fonctionnaire', 'Travailleur indépendant', 'Commerçant(e)', 'En recherche d’emploi', 'Autre'];

class _Feat {
  const _Feat(this.icon, this.tone, this.kicker, this.title, this.text);
  final IconData icon;
  final Tone tone;
  final String kicker, title, text;
}

const _hf = [
  _Feat(PI.buildings, Tone.soft, 'Bailleurs', 'Gérez vos chambres', 'Le plan de chaque étage montre les chambres libres, occupées, en travaux ou en retard.'),
  _Feat(
    PI.money,
    Tone.paid,
    'Loyers',
    'Suivez vos locataires',
    'Le locataire envoie son justificatif de paiement, vous le validez. Relances et quittances PDF.',
  ),
  _Feat(PI.megaphone, Tone.neutral, 'Locataires', 'Signalez un problème en un clic', 'Une catégorie, une photo, et le bailleur suit jusqu’à la résolution.'),
];

bool _isEmail(String s) => RegExp(r'^\S+@\S+\.\S+$').hasMatch(s.trim());
int _digits(String s) => s.replaceAll(RegExp(r'\D'), '').length;

// ───────────────────────────── Parcours ─────────────────────────────

/// Écrans communs : démarrage, accueil, présentation, connexion, inscription.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key, this.initial});

  /// Écran d'entrée : 'login', 'role', 'code', 'forgot', 'onb' ou null (démarrage).
  final String? initial;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  String screen = 'splash';
  int onb = 0, hs = 0;
  String idMode = 'phone';
  bool tried = false, busy = false, offline = false, resetSent = false;
  int attempts = 0;
  String role = 'tenant';
  String city = '';
  bool cityTried = false, fTried = false, accept = false, accTried = false;
  String? job, room;

  final ident = TextEditingController();
  final pw = TextEditingController();
  final cityQ = TextEditingController();
  final f = {
    for (final k in ['name', 'phone', 'email', 'cni', 'org', 'pw', 'pw2']) k: TextEditingController(),
  };

  Timer? _splash, _carousel;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null && ['home', 'login', 'role', 'code', 'forgot', 'onb', 'info', 'done'].contains(i)) {
      screen = i;
      if (i == 'code') role = 'tenant';
    } else {
      _splash = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && screen == 'splash') setState(() => screen = 'home');
      });
    }
    _carousel = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (mounted && screen == 'home') setState(() => hs = (hs + 1) % 3);
    });
    for (final c in [ident, pw, cityQ, ...f.values]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _splash?.cancel();
    _carousel?.cancel();
    for (final c in [ident, pw, cityQ, ...f.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void go(String s) => setState(() {
    screen = s;
    if (s == 'login') {
      tried = false;
      resetSent = false;
    }
    if (s == 'forgot') resetSent = false;
  });

  bool _back() {
    const back = {'onb': 'home', 'login': 'home', 'forgot': 'login', 'role': 'login', 'code': 'role', 'info': 'role', 'done': 'login'};
    final b = screen == 'info' && role == 'tenant' ? 'code' : back[screen];
    if (b == null) return true;
    go(b);
    return false;
  }

  // ─── Validation ───
  String? get idError {
    if (!tried) return null;
    if (ident.text.trim().isEmpty) return 'Ce champ est obligatoire.';
    if (idMode == 'email' ? !_isEmail(ident.text) : _digits(ident.text) < 8) {
      return idMode == 'email' ? 'Adresse e-mail invalide.' : 'Numéro invalide : 8 chiffres minimum.';
    }
    return null;
  }

  void submitLogin() {
    final bad = ident.text.trim().isEmpty || pw.text.isEmpty || (idMode == 'email' ? !_isEmail(ident.text) : _digits(ident.text) < 8);
    setState(() => tried = true);
    if (bad) return;
    setState(() => busy = true);
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;
      if (attempts == 0) {
        // Démonstration du bandeau « hors ligne » au premier essai, comme la maquette.
        setState(() {
          busy = false;
          offline = true;
          attempts = 1;
        });
        return;
      }
      final id = ident.text.toLowerCase();
      // Compte créé sur cet appareil : on ouvre l'espace du profil choisi à l'inscription.
      final saved = await Accounts.roleOf(id);
      if (!mounted) return;
      final demoTenant = id.contains('sarah') || id.replaceAll(RegExp(r'\D'), '') == '0712345602';
      final tenant = saved == null ? demoTenant : saved == 'tenant';
      goRoot(context, tenant ? Routes.tenant : Routes.landlord);
    });
  }

  _City get selCity => _cities.firstWhere((c) => c.id == city, orElse: () => _cities.first);

  List<_FieldDef> fields(bool check) {
    final t = role == 'tenant';
    final tr = fTried || check;
    String v(String k) => f[k]!.text;
    String? e(String msg) => tr && msg.isNotEmpty ? msg : null;
    return [
      _FieldDef('name', 'Nom complet', PI.user, 'Prénom et nom', bad: v('name').trim().isEmpty ? 'Ce champ est obligatoire.' : ''),
      _FieldDef(
        'phone',
        'Téléphone',
        PI.phone,
        '07 12 34 56 78',
        kb: TextInputType.phone,
        bad: _digits(v('phone')) < 8 ? 'Numéro invalide : 8 chiffres minimum.' : '',
      ),
      _FieldDef(
        'email',
        'Adresse e-mail',
        PI.envelope,
        'nom@exemple.com',
        kb: TextInputType.emailAddress,
        bad: !_isEmail(v('email')) ? 'Adresse e-mail invalide.' : '',
      ),
      if (t) ...[
        _FieldDef(
          'cni',
          'Numéro de CNI',
          PI.identificationCard,
          'Ex. 0000 1234 5678',
          bad: v('cni').replaceAll(' ', '').length < 6 ? 'Indiquez le numéro de votre carte d’identité.' : '',
        ),
        _FieldDef('cniPhoto', 'Photo de la CNI', PI.camera, '', kind: 'file', hint: 'Recto lisible, sans reflet. Elle n’est visible que par votre bailleur.'),
        _FieldDef('job', 'Fonction', PI.briefcase, 'Sélectionnez votre fonction', kind: 'job', bad: job == null ? 'Indiquez votre fonction.' : ''),
        _FieldDef('org', 'Établissement ou employeur', PI.buildings, 'Ex. Université, entreprise…', hint: 'Facultatif. Aide votre bailleur à vous identifier.'),
        _FieldDef('room', 'Chambre', PI.bed, 'Sélectionnez votre chambre', kind: 'room', bad: room == null ? 'Sélectionnez votre chambre.' : ''),
      ],
      _FieldDef(
        'pw',
        'Mot de passe',
        PI.lock,
        '8 caractères minimum',
        obscure: true,
        hint: 'Au moins 8 caractères, dont un chiffre.',
        bad: v('pw').length < 8 || !RegExp(r'\d').hasMatch(v('pw')) ? 'Au moins 8 caractères, dont un chiffre.' : '',
      ),
      _FieldDef(
        'pw2',
        'Confirmer le mot de passe',
        PI.lockKey,
        'Saisissez-le à nouveau',
        obscure: true,
        bad: v('pw2').isEmpty
            ? 'Confirmez votre mot de passe.'
            : v('pw2') != v('pw')
            ? 'Les deux mots de passe ne correspondent pas.'
            : '',
      ),
    ].map((d) => d..error = e(d.bad)).toList();
  }

  void submitInfo() {
    final bad = fields(true).any((d) => d.bad.isNotEmpty);
    if (bad || !accept) {
      setState(() {
        fTried = true;
        accTried = true;
      });
      return;
    }
    Accounts.save(phone: f['phone']!.text, email: f['email']!.text, role: role);
    go('done');
  }

  // ─── Construction ───
  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final p = context.pal;
    final splash = screen == 'splash';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _back() && Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: splash ? p.btn : p.bg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ScreenSwitcher(
              child: KeyedSubtree(key: ValueKey('$screen-$wide-${screen == 'onb' ? onb : ''}'), child: wide ? _desktop(context) : _mobile(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobile(BuildContext context) => switch (screen) {
    'splash' => _splashView(),
    'home' => _welcomeMobile(),
    'onb' => _onbMobile(),
    _ => _formScroll(_formFor(screen, mobile: true), mobile: true),
  };

  Widget _desktop(BuildContext context) => switch (screen) {
    'splash' => _splashView(),
    'home' => _welcomeDesktop(),
    'onb' => _onbDesktop(),
    _ => _authDesktop(_formFor(screen, mobile: false)),
  };

  Widget _formFor(String s, {required bool mobile}) => switch (s) {
    'login' => _login(mobile),
    'forgot' => _forgot(mobile),
    'role' => _role(mobile),
    'code' => _citySelect(mobile),
    'info' => _signup(mobile),
    _ => _done(mobile),
  };

  // ─── Démarrage ───
  Widget _splashView() {
    const n100 = AppColors.n100;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: n100, borderRadius: AppRadius.r, boxShadow: AppShadows.lg),
                  alignment: Alignment.center,
                  child: Image.asset('assets/images/logo-mark.png', width: 69, height: 69),
                ),
              ),
              const SizedBox(height: 16),
              FadeUp(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  'MaCité',
                  style: ts(32, w: FontWeight.w700, c: n100, ls: -0.3),
                ),
              ),
              const SizedBox(height: 16),
              FadeUp(
                delay: const Duration(milliseconds: 250),
                child: Text('La gestion locative, simplement', style: ts(16, c: n100)),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 64,
          child: Center(child: Spinner(size: 28, stroke: 3, color: n100)),
        ),
      ],
    );
  }

  // ─── Accueil mobile ───
  Widget _welcomeMobile() {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft, child: Logo()),
          const SizedBox(height: 20),
          _headline(32),
          const SizedBox(height: 10),
          Text('Pour les bailleurs et leurs locataires, au même endroit.', style: ts(16, c: p.text2, h: 1.5)),
          const SizedBox(height: 20),
          Expanded(child: _carouselCard(mobile: true)),
          const SizedBox(height: 20),
          Btn('Créer un compte', height: 56, expand: true, onPressed: () => go('role')),
          const SizedBox(height: 12),
          Btn('Se connecter', kind: BtnKind.outline, height: 56, expand: true, onPressed: () => go('login')),
          const SizedBox(height: 8),
          Center(
            child: LinkButton(
              'Découvrir l’application',
              icon: PI.playCircle,
              color: p.text2,
              onPressed: () => setState(() {
                onb = 0;
                screen = 'onb';
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headline(double size) {
    final p = context.pal;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'La gestion locative, '),
          TextSpan(
            text: 'simplement.',
            style: TextStyle(color: p.link),
          ),
        ],
      ),
      style: ts(size, w: FontWeight.w800, c: p.text, h: 1.08, ls: -size * 0.02),
    );
  }

  Widget _carouselCard({required bool mobile}) {
    final p = context.pal;
    final h = _hf[hs];
    Widget extra;
    if (hs == 0) {
      const cells = [
        (Tone.strong, AppColors.accent),
        (Tone.pale, AppColors.a500),
        (Tone.strong, AppColors.accent),
        (Tone.late, AppColors.accent2),
        (Tone.strong, AppColors.accent),
        (Tone.neutral, AppColors.n500),
        (Tone.strong, AppColors.accent),
        (Tone.pale, AppColors.a500),
      ];
      extra = GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 2,
        children: [
          for (var i = 0; i < cells.length; i++)
            PopIn(
              delay: Duration(milliseconds: 200 + i * 60),
              child: Container(
                decoration: BoxDecoration(
                  color: p.tone(cells[i].$1).$1,
                  borderRadius: AppRadius.r,
                  border: Border.all(color: cells[i].$2, width: 2),
                ),
              ),
            ),
        ],
      );
    } else {
      extra = PopIn(
        delay: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: p.bg, borderRadius: AppRadius.r),
          child: Row(
            children: [
              IconTile(hs == 1 ? PI.checkCircle : PI.drop, size: 32, iconSize: 20, tone: hs == 1 ? Tone.paid : Tone.neutral),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hs == 1 ? 'Loyer reçu' : 'Signalement envoyé',
                      style: ts(13, w: FontWeight.w700, c: p.text),
                    ),
                    Text(hs == 1 ? '45 000 FCFA · MTN MoMo' : 'Plomberie · en 24 secondes', style: ts(12, c: p.text2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: p.card, borderRadius: AppRadius.r, boxShadow: AppShadows.lg),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -64,
            top: -64,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(color: p.a100, shape: BoxShape.circle),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: kEase,
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a),
                        child: c,
                      ),
                    ),
                    // Comme la maquette : l'ancienne diapositive disparaît, seule la nouvelle glisse.
                    layoutBuilder: (cur, prev) => cur ?? const SizedBox(),
                    child: Column(
                      key: ValueKey(hs),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PopIn(
                          delay: const Duration(milliseconds: 100),
                          child: IconTile(h.icon, size: 64, iconSize: 36, tone: h.tone),
                        ),
                        const SizedBox(height: 14),
                        Kicker(h.kicker),
                        const SizedBox(height: 14),
                        Text(
                          h.title,
                          style: ts(22, w: FontWeight.w700, c: p.text),
                        ),
                        const SizedBox(height: 14),
                        Text(h.text, style: ts(15, c: p.text2, h: 1.5)),
                        const SizedBox(height: 18),
                        extra,
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Dots(count: 3, index: hs, onPick: (i) => setState(() => hs = i)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Accueil ordinateur ───
  Widget _welcomeDesktop() {
    final p = context.pal;
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            child: Row(
              children: [
                const Logo(),
                const Spacer(),
                Btn('Se connecter', kind: BtnKind.outline, height: 44, fontSize: 15, onPressed: () => go('login')),
                const SizedBox(width: 8),
                Btn('Créer un compte', height: 44, fontSize: 15, onPressed: () => go('role')),
              ],
            ),
          ),
          MaxWidth(
            max: 1200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 40, 48, 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FadeUp(
                      offset: 12,
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const StatusBadge('Loyers en FCFA · Mobile Money', icon: PI.lightning, height: 32, fontSize: 13),
                          const SizedBox(height: 24),
                          _headline(56),
                          const SizedBox(height: 24),
                          Text(
                            'Bailleurs : gérez vos immeubles, vos chambres et vos loyers. Locataires : payez et signalez un problème depuis votre téléphone.',
                            style: ts(19, c: p.text2, h: 1.55),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              Btn('Commencer', icon: PI.rocketLaunch, height: 56, onPressed: () => go('role')),
                              Btn(
                                'Découvrir l’application',
                                icon: PI.playCircle,
                                kind: BtnKind.outline,
                                height: 56,
                                onPressed: () => setState(() {
                                  onb = 0;
                                  screen = 'onb';
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 64),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(height: 420, child: _carouselCard(mobile: false)),
                        Positioned(
                          left: -32,
                          bottom: -24,
                          child: FloatY(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(color: p.card, borderRadius: AppRadius.r, boxShadow: AppShadows.md),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const IconTile(PI.money, size: 36, iconSize: 20, tone: Tone.paid),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Loyer reçu',
                                        style: ts(14, w: FontWeight.w700, c: p.text),
                                      ),
                                      Text('45 000 FCFA · MTN MoMo', style: ts(13, c: p.text2)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          MaxWidth(
            max: 1200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 16, 48, 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _hf.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(
                      child: FadeUp(
                        delay: Duration(milliseconds: 150 + i * 120),
                        offset: 12,
                        child: AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconTile(_hf[i].icon, size: 44, tone: _hf[i].tone),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hf[i].title,
                                      style: ts(16, w: FontWeight.w700, c: p.text),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_hf[i].text, style: ts(14, c: p.text2, h: 1.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Présentation ───
  void _onbNext() {
    if (onb < 2) {
      setState(() => onb++);
    } else {
      go('login');
    }
  }

  Widget _onbContent({required bool big}) {
    final p = context.pal;
    final o = _onb[onb];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusBadge(o.kicker, icon: o.icon, tone: Tone.soft, height: 32, fontSize: 13),
        const SizedBox(height: 16),
        FadeUp(
          child: Text(
            o.title,
            style: ts(big ? 40 : 28, w: FontWeight.w700, c: p.text, h: 1.15),
          ),
        ),
        const SizedBox(height: 12),
        FadeUp(
          delay: const Duration(milliseconds: 80),
          child: Text(o.text, style: ts(big ? 18 : 16, c: p.text2, h: 1.5)),
        ),
      ],
    );
  }

  Widget _onbFooter() => Row(
    children: [
      Dots(count: 3, index: onb),
      const Spacer(),
      Btn(onb == 2 ? 'Commencer' : 'Suivant', trailingIcon: PI.arrowRight, height: 56, onPressed: _onbNext),
    ],
  );

  Widget _onbMobile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: LinkButton('Passer', color: context.pal.text2, onPressed: () => go('login')),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FadeUp(child: ImageSlot(_onb[onb].ph, icon: _onb[onb].icon)),
          ),
          const SizedBox(height: 24),
          _onbContent(big: false),
          const SizedBox(height: 32),
          _onbFooter(),
        ],
      ),
    );
  }

  Widget _onbDesktop() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ImageSlot(_onb[onb].ph, icon: _onb[onb].icon),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Logo(),
                    const Spacer(),
                    LinkButton('Passer', color: context.pal.text2, onPressed: () => go('login')),
                  ],
                ),
                const Spacer(),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: _onbContent(big: true)),
                const Spacer(),
                _onbFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mise en page des formulaires ───
  Widget _formScroll(Widget child, {required bool mobile}) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(mobile ? 24 : 0, mobile ? 8 : 0, mobile ? 24 : 0, 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: c.maxHeight - 40),
        child: IntrinsicHeight(child: child),
      ),
    ),
  );

  Widget _authDesktop(Widget form) {
    const n100 = AppColors.n100;
    final p = context.pal;
    return Row(
      children: [
        Container(
          width: 520,
          color: p.btn,
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: n100, borderRadius: AppRadius.r),
                    alignment: Alignment.center,
                    child: Image.asset('assets/images/logo-mark.png', width: 32, height: 32),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MaCité',
                    style: ts(22, w: FontWeight.w700, c: p.onBtn),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Expanded(child: ImageSlot('Photo d’une cité ou d’un immeuble', icon: PI.buildings)),
              const SizedBox(height: 32),
              Text(
                'Chambres, loyers et signalements au même endroit.',
                style: ts(28, w: FontWeight.w700, c: p.onBtn, h: 1.2),
              ),
              const SizedBox(height: 8),
              Text('Pour les bailleurs et leurs locataires.', style: ts(16, c: p.onBtn.withValues(alpha: 0.85))),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - 96),
                child: Center(
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: form),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _backRow(bool mobile, String label, VoidCallback onBack, {String? step}) {
    final p = context.pal;
    return Row(
      children: [
        if (mobile)
          Transform.translate(
            offset: const Offset(-12, 0),
            child: IconBtn(PI.arrowLeft, onPressed: onBack, tooltip: 'Retour'),
          )
        else
          Transform.translate(
            offset: const Offset(-12, 0),
            child: LinkButton(label, icon: PI.arrowLeft, color: p.text2, onPressed: onBack),
          ),
        const Spacer(),
        if (step != null && step.isNotEmpty)
          Text(
            step,
            style: ts(13, w: FontWeight.w600, c: p.text2),
          ),
      ],
    );
  }

  Widget _titleBlock(String title, String text) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenTitle(title),
        const SizedBox(height: 8),
        Text(text, style: ts(16, c: p.text2, h: 1.5)),
      ],
    );
  }

  // ─── Connexion ───
  Widget _login(bool mobile) {
    final p = context.pal;
    final pwErr = tried && pw.text.isEmpty ? 'Saisissez votre mot de passe.' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mobile) ...[
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Image.asset('assets/images/logo-mark.png', width: 56, height: 56)),
          const SizedBox(height: 16),
        ],
        ScreenTitle('Connexion', size: mobile ? 28 : 32),
        const SizedBox(height: 8),
        Text('Heureux de vous revoir.', style: ts(16, c: p.text2)),
        const SizedBox(height: 24),
        if (offline) ...[
          Banner2(
            mobile ? 'Pas de connexion internet. Vérifiez vos données mobiles.' : 'Pas de connexion internet. Vérifiez votre réseau puis réessayez.',
            icon: PI.wifiSlash,
          ),
          const SizedBox(height: 24),
        ],
        Segmented<String>(
          options: const [('phone', 'Téléphone', null), ('email', 'E-mail', null)],
          value: idMode,
          onChanged: (v) => setState(() {
            idMode = v;
            tried = false;
          }),
        ),
        const SizedBox(height: 24),
        AppField(
          key: ValueKey(idMode),
          label: idMode == 'phone' ? 'Numéro de téléphone' : 'Adresse e-mail',
          controller: ident,
          icon: idMode == 'phone' ? PI.phone : PI.envelope,
          hint: idMode == 'phone' ? '07 12 34 56 78' : 'nom@exemple.com',
          keyboardType: idMode == 'phone' ? TextInputType.phone : TextInputType.emailAddress,
          error: idError,
        ),
        const SizedBox(height: 16),
        AppField(
          label: 'Mot de passe',
          controller: pw,
          icon: PI.lock,
          hint: 'Votre mot de passe',
          obscure: true,
          error: pwErr,
          onSubmitted: (_) => submitLogin(),
          labelTrailing: mobile ? null : _forgotLink(),
        ),
        if (mobile) Align(alignment: Alignment.centerRight, child: _forgotLink()),
        if (mobile) const Spacer() else const SizedBox(height: 24),
        const SizedBox(height: 16),
        Btn(busy ? 'Connexion…' : (offline ? 'Réessayer' : 'Se connecter'), busy: busy, height: 56, expand: true, onPressed: submitLogin),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Pas encore de compte ?', style: ts(14, c: p.text2)),
            LinkButton('Créer un compte', onPressed: () => go('role')),
          ],
        ),
      ],
    );
  }

  Widget _forgotLink() => Transform.translate(
    offset: const Offset(12, 0),
    child: LinkButton('Mot de passe oublié ?', onPressed: () => go('forgot')),
  );

  // ─── Mot de passe oublié ───
  Widget _forgot(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _backRow(mobile, 'Connexion', () => go('login')),
        const SizedBox(height: 16),
        _titleBlock('Mot de passe oublié', 'Indiquez votre numéro ou votre e-mail. Nous vous enverrons un code pour choisir un nouveau mot de passe.'),
        const SizedBox(height: 24),
        if (resetSent) ...[const Banner2('Code envoyé. Il est valable 10 minutes.', icon: PI.envelopeOpen, tone: Tone.paid), const SizedBox(height: 24)],
        AppField(label: 'Téléphone ou e-mail', controller: ident, icon: PI.user, hint: '07 12 34 56 78'),
        if (mobile) const Spacer() else const SizedBox(height: 32),
        const SizedBox(height: 24),
        Btn(
          resetSent ? 'Renvoyer le code' : 'Recevoir un code',
          height: 56,
          expand: true,
          onPressed: () {
            setState(() => resetSent = true);
            showToast(context, 'Code envoyé par SMS');
          },
        ),
        if (mobile) ...[
          const SizedBox(height: 12),
          Btn('Retour à la connexion', kind: BtnKind.outline, height: 56, expand: true, onPressed: () => go('login')),
        ],
      ],
    );
  }

  // ─── Profil ───
  Widget _role(bool mobile) {
    const roles = [
      ('landlord', 'Je suis bailleur', 'Propriétaire ou gestionnaire : gérez vos immeubles, chambres et loyers.', PI.handshake),
      ('tenant', 'Je suis locataire', 'Étudiant ou jeune actif : inscrivez-vous dans votre cité, envoyez vos justificatifs, signalez un problème.', PI.user),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _backRow(mobile, 'Connexion', () => go('login')),
        const SizedBox(height: 16),
        _titleBlock('Qui êtes-vous ?', 'Votre espace sera adapté à votre profil.'),
        const SizedBox(height: 24),
        for (var i = 0; i < roles.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          FadeUp(
            delay: Duration(milliseconds: i * 80),
            child: SelectCard(
              icon: roles[i].$4,
              title: roles[i].$2,
              subtitle: roles[i].$3,
              selected: role == roles[i].$1,
              onTap: () => setState(() => role = roles[i].$1),
            ),
          ),
        ],
        if (mobile) const Spacer() else const SizedBox(height: 32),
        const SizedBox(height: 24),
        Btn(
          'Continuer',
          height: 56,
          expand: true,
          onPressed: () {
            setState(() {
              cityTried = false;
              fTried = false;
            });
            go(role == 'tenant' ? 'code' : 'info');
          },
        ),
      ],
    );
  }

  // ─── Choix de la cité ───
  Widget _citySelect(bool mobile) {
    final q = cityQ.text.trim().toLowerCase();
    final list = _cities.where((c) => q.isEmpty || '${c.name} ${c.area}'.toLowerCase().contains(q)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _backRow(mobile, 'Profil', () => go('role'), step: 'Étape 1 sur 2'),
        const SizedBox(height: 16),
        _titleBlock('Choisissez votre cité', 'Votre bailleur recevra votre demande d’inscription et la validera.'),
        const SizedBox(height: 24),
        AppField(controller: cityQ, icon: PI.magnifyingGlass, hint: 'Nom de la cité ou quartier'),
        const SizedBox(height: 16),
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          FadeUp(
            delay: Duration(milliseconds: i * 50),
            child: SelectCard(
              icon: PI.city,
              title: list[i].name,
              subtitle: '${list[i].area} · ${list[i].free}',
              extra: 'Bailleur : ${list[i].owner}',
              selected: city == list[i].id,
              onTap: () => setState(() {
                city = list[i].id;
                cityTried = false;
                room = null;
              }),
            ),
          ),
        ],
        if (list.isEmpty)
          const EmptyState(
            icon: PI.magnifyingGlassMinus,
            title: 'Aucune cité trouvée',
            text: 'Vérifiez l’orthographe ou demandez le nom exact à votre bailleur.',
          ),
        if (cityTried && city.isEmpty) ...[const SizedBox(height: 12), const ErrorText('Sélectionnez votre cité pour continuer.')],
        if (mobile) const Spacer() else const SizedBox(height: 32),
        const SizedBox(height: 24),
        Btn(
          'Continuer',
          height: 56,
          expand: true,
          onPressed: () {
            if (city.isEmpty) {
              setState(() => cityTried = true);
            } else {
              setState(() {
                fTried = false;
                accTried = false;
              });
              go('info');
            }
          },
        ),
      ],
    );
  }

  // ─── Inscription ───
  Widget _signup(bool mobile) {
    final p = context.pal;
    final t = role == 'tenant';
    final defs = fields(false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _backRow(mobile, 'Retour', () => go(t ? 'code' : 'role'), step: t ? 'Étape 2 sur 2' : ''),
        const SizedBox(height: 16),
        ScreenTitle(t ? 'Vos informations' : 'Créer mon compte bailleur'),
        const SizedBox(height: 20),
        if (t) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(color: p.a100, borderRadius: AppRadius.r),
            child: Row(
              children: [
                Ph(PI.city, color: p.a800),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    city.isEmpty ? 'Aucune cité' : selCity.name,
                    style: ts(15, w: FontWeight.w700, c: p.a800),
                  ),
                ),
                LinkButton('Changer', onPressed: () => go('code')),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        for (final d in defs) ...[_fieldWidget(d), const SizedBox(height: 16)],
        CheckLine(
          value: accept,
          error: accTried && !accept,
          onChanged: (v) => setState(() => accept = v),
          label: 'J’accepte les conditions d’utilisation et le règlement intérieur de la cité.',
        ),
        if (accTried && !accept) ...[const SizedBox(height: 6), const ErrorText('Cochez la case pour continuer.')],
        const SizedBox(height: 24),
        Btn(t ? 'Envoyer ma demande' : 'Créer mon compte', height: 56, expand: true, onPressed: submitInfo),
      ],
    );
  }

  Widget _fieldWidget(_FieldDef d) {
    switch (d.kind) {
      case 'file':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.label,
              style: ts(13, w: FontWeight.w600, c: context.pal.text),
            ),
            const SizedBox(height: 8),
            const ImageSlot('Photo de la CNI (recto)', height: 140, icon: PI.identificationCard),
            const SizedBox(height: 6),
            Text(
              d.hint!,
              style: ts(13, w: FontWeight.w500, c: context.pal.text2, h: 1.4),
            ),
          ],
        );
      case 'job':
        return AppSelect<String>(
          label: d.label,
          icon: d.icon,
          hint: d.ph,
          value: job,
          error: d.error,
          items: [for (final j in _jobs) (j, j)],
          onChanged: (v) => setState(() => job = v),
        );
      case 'room':
        return AppSelect<String>(
          label: d.label,
          icon: d.icon,
          hint: d.ph,
          value: room,
          error: d.error,
          items: [for (final r in selCity.rooms) (r.split(' · ').first, r)],
          onChanged: (v) => setState(() => room = v),
        );
      default:
        return AppField(label: d.label, controller: f[d.key], icon: d.icon, hint: d.ph, keyboardType: d.kb, obscure: d.obscure, error: d.error, helper: d.hint);
    }
  }

  // ─── Confirmation ───
  Widget _done(bool mobile) {
    final p = context.pal;
    final t = role == 'tenant';
    final steps = [
      ('Demande envoyée', PI.checkCircle, Tone.paid),
      ('Validation par le bailleur', PI.hourglassHigh, Tone.neutral),
      ('Accès à votre espace locataire', PI.lockOpen, Tone.muted),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mobile) const Spacer() else const SizedBox(height: 24),
        Center(
          child: PopIn(child: IconTile(t ? PI.hourglassHigh : PI.checkCircle, size: 96, iconSize: 52, tone: t ? Tone.neutral : Tone.paid)),
        ),
        const SizedBox(height: 24),
        FadeUp(
          child: Text(
            t ? 'Demande envoyée' : 'Compte créé',
            textAlign: TextAlign.center,
            style: ts(28, w: FontWeight.w700, c: p.text),
          ),
        ),
        const SizedBox(height: 12),
        FadeUp(
          delay: const Duration(milliseconds: 80),
          child: Text(
            t
                ? 'Votre demande d’inscription à ${selCity.name} a été transmise à votre bailleur. Vous recevrez un SMS dès qu’il l’aura validée.'
                : 'Ajoutez votre premier immeuble pour commencer.',
            textAlign: TextAlign.center,
            style: ts(16, c: p.text2, h: 1.5),
          ),
        ),
        if (t) ...[
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  FadeUp(
                    delay: Duration(milliseconds: 200 + i * 120),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          IconTile(steps[i].$2, size: 36, iconSize: 20, tone: steps[i].$3),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              steps[i].$1,
                              style: ts(15, w: i <= 1 ? FontWeight.w600 : FontWeight.w500, c: i <= 1 ? p.text : p.text2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (mobile) const Spacer() else const SizedBox(height: 32),
        const SizedBox(height: 24),
        Btn(
          t ? 'Retour à la connexion' : 'Accéder à mon espace',
          height: 56,
          expand: true,
          onPressed: () {
            if (t) {
              go('login');
            } else {
              goRoot(context, Routes.landlord);
            }
          },
        ),
      ],
    );
  }
}

class _FieldDef {
  _FieldDef(this.key, this.label, this.icon, this.ph, {this.kind = 'input', this.kb, this.obscure = false, this.hint, this.bad = ''});
  final String key, label, ph, kind;
  final IconData icon;
  final TextInputType? kb;
  final bool obscure;
  final String? hint;
  final String bad;
  String? error;
}
