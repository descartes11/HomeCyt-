import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/ui.dart';

const _features = [
  (
    PI.buildings,
    Tone.soft,
    'Immeubles et chambres',
    'Le plan de chaque étage montre en un coup d’œil les chambres libres, occupées, en travaux ou en retard de loyer.',
  ),
  (PI.money, Tone.paid, 'Loyers suivis', 'Justificatifs envoyés par le locataire, validés par le bailleur, relances et quittances PDF.'),
  (
    PI.megaphone,
    Tone.neutral,
    'Signalements en un clic',
    'Le locataire choisit une catégorie, ajoute une photo et envoie. Le bailleur suit jusqu’à la résolution.',
  ),
  (PI.chats, Tone.neutral, 'Annonces de la cité', 'Coupure d’eau, réunion, travaux : une annonce part vers tout un immeuble ou toute la cité.'),
];

const _aud = {
  'landlord': (
    'Créer mon espace bailleur',
    [
      (PI.houseLine, 'Ajoutez vos immeubles', 'Créez vos immeubles, étages et chambres avec leur loyer et leurs équipements.'),
      (PI.userCheck, 'Validez vos locataires', 'Vos locataires s’inscrivent dans votre cité : vous validez leur demande et leur chambre.'),
      (PI.chartLineUp, 'Suivez tout', 'Loyers, retards et signalements sont réunis sur votre tableau de bord.'),
    ],
  ),
  'tenant': (
    'Rejoindre ma cité',
    [
      (PI.city, 'Choisissez votre cité', 'Renseignez vos informations et votre chambre : votre bailleur valide votre inscription.'),
      (PI.uploadSimple, 'Envoyez votre justificatif', 'Photo du reçu et montant payé : votre quittance arrive après validation.'),
      (PI.megaphone, 'Signalez un problème', 'En moins de 30 secondes, avec une photo, et suivez la réparation.'),
    ],
  ),
};

const _rooms1 = [('A-301', 'occ'), ('A-302', 'occ'), ('A-303', 'free'), ('A-304', 'occ'), ('A-305', 'occ'), ('A-306', 'works')];
const _rooms2 = [('A-201', 'occ'), ('A-202', 'occ'), ('A-203', 'late'), ('A-204', 'occ'), ('A-205', 'free'), ('A-206', 'occ')];
const _pay = [
  ('Sarah M.', 'SM', 'A-102', '45 000 FCFA', Tone.strong),
  ('Paul N.', 'PN', 'A-203', '45 000 FCFA', Tone.neutral),
  ('Fatou B.', 'FB', 'A-305', '35 000 FCFA', Tone.pale),
  ('Kevin O.', 'KO', 'A-201', '45 000 FCFA', Tone.magSoft),
];

/// Page publique avant connexion (web).
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final scroll = ScrollController();
  final keys = {
    for (final k in ['top', 'features', 'profiles', 'payments']) k: GlobalKey(),
  };
  int slide = 0, payTick = 0;
  String aud = 'landlord';
  bool scrolled = false;
  Timer? _slideT, _payT;

  @override
  void initState() {
    super.initState();
    _startSlides();
    _payT = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (_visible) setState(() => payTick = (payTick + 1) % 4);
    });
    scroll.addListener(() {
      final s = scroll.offset > 8;
      if (s != scrolled) setState(() => scrolled = s);
    });
  }

  /// Faux quand un autre écran recouvre la page : inutile de la reconstruire en arrière-plan.
  bool get _visible => mounted && (ModalRoute.of(context)?.isCurrent ?? true);

  void _startSlides() {
    _slideT?.cancel();
    _slideT = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_visible) setState(() => slide = (slide + 1) % 3);
    });
  }

  void pick(int i) {
    setState(() => slide = i);
    _startSlides();
  }

  @override
  void dispose() {
    _slideT?.cancel();
    _payT?.cancel();
    scroll.dispose();
    super.dispose();
  }

  void jump(String k) {
    final ctx = keys[k]?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: kEase);
  }

  void toAuth(String screen) => Navigator.of(context).pushNamed(Routes.auth, arguments: screen);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final wide = w >= 1040;
    final p = context.pal;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 72),
                _hero(context, w),
                _featuresSection(context, w),
                _audiences(context, w),
                _payments(context, w),
                _cta(context, w),
                _footer(context),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 72,
                  decoration: BoxDecoration(
                    color: p.bg.withValues(alpha: 0.88),
                    border: Border(bottom: BorderSide(color: scrolled ? p.line : Colors.transparent)),
                  ),
                  child: MaxWidth(
                    max: 1200,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Tap(
                            onTap: () => scroll.animateTo(0, duration: const Duration(milliseconds: 500), curve: kEase),
                            child: const Logo(),
                          ),
                          if (wide) ...[
                            const SizedBox(width: 16),
                            for (final n in const [('features', 'Fonctionnalités'), ('profiles', 'Bailleurs et locataires'), ('payments', 'Paiements')])
                              _NavLink(n.$2, onTap: () => jump(n.$1)),
                          ],
                          const Spacer(),
                          Btn('Se connecter', kind: BtnKind.outline, height: 44, fontSize: 15, padding: 16, onPressed: () => toAuth('login')),
                          if (wide) ...[
                            const SizedBox(width: 8),
                            Btn('Créer un compte', height: 44, fontSize: 15, padding: 18, onPressed: () => toAuth('role')),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _pad(double w) => w < 600 ? 16 : 24;

  // ─── Héros ───
  Widget _hero(BuildContext context, double w) {
    final p = context.pal;
    final two = w >= 900;
    final h1 = (w * 0.056).clamp(38.0, 64.0);
    final text = FadeUp(
      offset: 12,
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge('Loyers en FCFA · justificatifs en photo', icon: PI.lightning, height: 32, fontSize: 13),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'La gestion locative, '),
                TextSpan(
                  text: 'simplement.',
                  style: TextStyle(color: p.link),
                ),
              ],
            ),
            style: ts(h1, w: FontWeight.w800, c: p.text, h: 1.05, ls: -h1 * 0.03),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Bailleurs : gérez vos immeubles, vos chambres et vos loyers. Locataires : envoyez vos justificatifs de paiement et signalez un problème depuis votre téléphone.',
              style: ts((w * 0.016).clamp(17.0, 20.0), c: p.text2, h: 1.55),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Btn('Commencer gratuitement', icon: PI.rocketLaunch, height: 56, onPressed: () => toAuth('role')),
              Btn('Voir comment ça marche', icon: PI.playCircle, kind: BtnKind.outline, height: 56, onPressed: () => jump('features')),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              for (final t in const ['Android, iOS et web', 'En français', 'Fonctionne avec peu de réseau'])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Ph(PI.checkCircle, size: 18, color: p.a700),
                    const SizedBox(width: 6),
                    Text(
                      t,
                      style: ts(14, w: FontWeight.w600, c: p.strong),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
    final phone = _phoneMock(context);
    return Container(
      key: keys['top'],
      padding: EdgeInsets.fromLTRB(_pad(w), (w * 0.07).clamp(40, 96), _pad(w), (w * 0.05).clamp(32, 64)),
      child: MaxWidth(
        max: 1200,
        child: Column(
          children: [
            two
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: text),
                      const SizedBox(width: 48),
                      Expanded(child: Center(child: phone)),
                    ],
                  )
                : Column(children: [text, const SizedBox(height: 48), phone]),
            const SizedBox(height: 32),
            Dots(count: 3, index: slide, onPick: pick, activeWidth: 28),
          ],
        ),
      ),
    );
  }

  Widget _phoneMock(BuildContext context) {
    final p = context.pal;
    final screen = switch (slide) {
      0 => _s0(context),
      1 => _s1(context),
      _ => _s2(context),
    };
    return SizedBox(
      width: 420,
      height: 640,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 320,
            height: 620,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.n900, borderRadius: BorderRadius.circular(36), boxShadow: AppShadows.lg),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                color: p.bg,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
                      child: Row(
                        children: [
                          Text(
                            '9:41',
                            style: ts(13, w: FontWeight.w700, c: p.text),
                          ),
                          const Spacer(),
                          Ph(PI.cellSignalFull, size: 14, color: p.text),
                          const SizedBox(width: 4),
                          Ph(PI.wifiHigh, size: 14, color: p.text),
                          const SizedBox(width: 4),
                          Ph(PI.batteryFull, size: 14, color: p.text),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: ScreenSwitcher(
                          child: KeyedSubtree(key: ValueKey(slide), child: screen),
                        ),
                      ),
                    ),
                    Container(
                      height: 64,
                      color: p.card,
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: Tap(
                                onTap: () => pick(i),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      width: 52,
                                      height: 28,
                                      decoration: BoxDecoration(color: slide == i ? p.navIndicator : Colors.transparent, borderRadius: AppRadius.r),
                                      child: Center(
                                        child: Ph(const [PI.chartLineUp, PI.buildings, PI.megaphone][i], size: 20, color: slide == i ? p.a800 : p.text2),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      const ['Loyers', 'Chambres', 'Signaler'][i],
                                      style: ts(11, w: slide == i ? FontWeight.w700 : FontWeight.w500, c: slide == i ? p.a800 : p.text2),
                                    ),
                                  ],
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
          ),
          Positioned(left: -10, top: 400, child: FloatY(child: _floatCard(context, PI.money, Tone.paid, 'Justificatif reçu', '45 000 FCFA · à vérifier'))),
          Positioned(
            right: -10,
            top: 120,
            child: FloatY(phase: 0.5, child: _floatCard(context, PI.bellRinging, Tone.neutral, 'Rappel envoyé', 'Échéance le 5 novembre')),
          ),
        ],
      ),
    );
  }

  Widget _floatCard(BuildContext context, IconData ic, Tone tone, String t, String s) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: p.card, borderRadius: AppRadius.r, boxShadow: AppShadows.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTile(ic, size: 36, iconSize: 20, tone: tone),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t,
                style: ts(13, w: FontWeight.w700, c: p.text),
              ),
              Text(s, style: ts(12, c: p.text2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _s0(BuildContext context) {
    final p = context.pal;
    const bars = [0.55, 0.7, 0.62, 0.8, 0.76, 0.92];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mercredi 4 novembre',
          style: ts(11, w: FontWeight.w500, c: p.text2),
        ),
        Text(
          'Bonjour, Daniel',
          style: ts(20, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.btn, borderRadius: AppRadius.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loyers encaissés · novembre', style: ts(11, c: p.onBtn)),
              const SizedBox(height: 4),
              Text(
                '1 260 000 FCFA',
                style: ts(20, w: FontWeight.w700, c: p.onBtn),
              ),
              const SizedBox(height: 8),
              Progress(0.88, height: 5, color: p.onBtn, track: p.onBtn.withValues(alpha: 0.25)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final k in [(PI.clock, Tone.late, 'Impayés', '165 000 FCFA'), (PI.chartDonut, Tone.paid, 'Occupation', '92 %')]) ...[
              if (k.$3 == 'Occupation') const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: p.card, borderRadius: AppRadius.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile(k.$1, size: 26, iconSize: 16, tone: k.$2),
                      const SizedBox(height: 6),
                      Text(k.$3, style: ts(10, c: p.text2)),
                      Text(
                        k.$4,
                        style: ts(13, w: FontWeight.w700, c: p.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: p.card, borderRadius: AppRadius.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encaissements',
                  style: ts(12, w: FontWeight.w700, c: p.text),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < bars.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: bars[i]),
                              duration: Duration(milliseconds: 500 + i * 80),
                              curve: kEase,
                              builder: (_, v, _) => FractionallySizedBox(
                                heightFactor: v,
                                child: Container(
                                  decoration: BoxDecoration(color: i == 5 ? p.a200 : p.btn, borderRadius: AppRadius.r),
                                ),
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
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _roomGrid(BuildContext context, List<(String, String)> rooms, int base) {
    const st = {
      'free': (AppColors.n100, AppColors.a800, AppColors.a500, PI.doorOpen),
      'occ': (AppColors.a700, AppColors.n100, AppColors.a700, PI.user),
      'works': (AppColors.n200, AppColors.n800, AppColors.n600, PI.trafficCone),
      'late': (AppColors.m200, AppColors.m800, AppColors.accent2, PI.clock),
    };
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.35,
      children: [
        for (var i = 0; i < rooms.length; i++)
          PopIn(
            delay: Duration(milliseconds: base + i * 60),
            child: Container(
              decoration: BoxDecoration(
                color: st[rooms[i].$2]!.$1,
                borderRadius: AppRadius.r,
                border: Border.all(color: st[rooms[i].$2]!.$3, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Ph(st[rooms[i].$2]!.$4, size: 16, color: st[rooms[i].$2]!.$2),
                  Text(
                    rooms[i].$1,
                    style: ts(11, w: FontWeight.w700, c: st[rooms[i].$2]!.$2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _s1(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Immeuble A · Les Lauriers',
          style: ts(17, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 10),
        Kicker('3e étage', color: p.text2),
        const SizedBox(height: 6),
        _roomGrid(context, _rooms1, 0),
        const SizedBox(height: 10),
        Kicker('2e étage', color: p.text2),
        const SizedBox(height: 6),
        _roomGrid(context, _rooms2, 300),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (final l in const [
              ('Libre', AppColors.a500),
              ('Occupée', AppColors.a700),
              ('En travaux', AppColors.n600),
              ('Loyer en retard', AppColors.accent2),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: l.$2, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l.$1,
                    style: ts(10, w: FontWeight.w600, c: p.text2),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _s2(BuildContext context) {
    final p = context.pal;
    const cats = [
      (PI.drop, 'Plomberie', Tone.neutral),
      (PI.lightning, 'Électricité', Tone.neutral),
      (PI.lock, 'Serrure et porte', Tone.neutral),
      (PI.broom, 'Propreté', Tone.paid),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quel est le problème ?',
          style: ts(18, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: [
            for (var i = 0; i < cats.length; i++)
              PopIn(
                delay: Duration(milliseconds: i * 80),
                child: Container(
                  decoration: BoxDecoration(
                    color: i == 0 ? p.a100 : p.card,
                    borderRadius: AppRadius.r,
                    border: Border.all(color: i == 0 ? p.btn : p.line, width: i == 0 ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconTile(cats[i].$1, size: 40, iconSize: 22, tone: cats[i].$3),
                      const SizedBox(height: 6),
                      Text(
                        cats[i].$2,
                        style: ts(12, w: FontWeight.w600, c: p.text),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        PopIn(
          delay: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.a100, borderRadius: AppRadius.r),
            child: Row(
              children: [
                Ph(PI.checkCircle, color: p.a800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Signalement envoyé',
                    style: ts(13, w: FontWeight.w700, c: p.a800),
                  ),
                ),
                Text('en 24 secondes', style: ts(11, c: p.a800)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Fonctionnalités ───
  Widget _featuresSection(BuildContext context, double w) {
    final p = context.pal;
    final cols = w >= 1040 ? 4 : (w >= 640 ? 2 : 1);
    return Container(
      key: keys['features'],
      color: p.card,
      padding: EdgeInsets.symmetric(horizontal: _pad(w), vertical: 80),
      child: MaxWidth(
        max: 1200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Reveal(
              scroll: scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Kicker('Fonctionnalités'),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      'Tout ce qu’il faut pour gérer une cité, au même endroit.',
                      style: ts((w * 0.035).clamp(28.0, 40.0), w: FontWeight.w700, c: p.text, h: 1.15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, box) {
                final cw = (box.maxWidth - (cols - 1) * 16) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (var i = 0; i < _features.length; i++)
                      SizedBox(
                        width: cw,
                        child: Reveal(
                          scroll: scroll,
                          delay: Duration(milliseconds: i * 100),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: p.bg, borderRadius: AppRadius.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconTile(_features[i].$1, size: 52, iconSize: 28, tone: _features[i].$2),
                                const SizedBox(height: 16),
                                Text(
                                  _features[i].$3,
                                  style: ts(19, w: FontWeight.w700, c: p.text),
                                ),
                                const SizedBox(height: 8),
                                Text(_features[i].$4, style: ts(15, c: p.text2, h: 1.55)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Profils ───
  Widget _audiences(BuildContext context, double w) {
    final p = context.pal;
    final a = _aud[aud]!;
    final cols = w >= 900 ? 3 : 1;
    return Container(
      key: keys['profiles'],
      padding: EdgeInsets.symmetric(horizontal: _pad(w), vertical: 80),
      child: MaxWidth(
        max: 1200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Reveal(
              scroll: scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Kicker('Comment ça marche'),
                  const SizedBox(height: 12),
                  Text(
                    'Un espace pour chacun.',
                    style: ts((w * 0.035).clamp(28.0, 40.0), w: FontWeight.w700, c: p.text),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Segmented<String>(
                      height: 44,
                      options: const [('landlord', 'Je suis bailleur', PI.handshake), ('tenant', 'Je suis locataire', PI.user)],
                      value: aud,
                      onChanged: (v) => setState(() => aud = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, box) {
                final cw = (box.maxWidth - (cols - 1) * 16) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (var i = 0; i < a.$2.length; i++)
                      SizedBox(
                        width: cw,
                        child: FadeUp(
                          key: ValueKey('$aud$i'),
                          delay: Duration(milliseconds: i * 100),
                          offset: 12,
                          child: AppCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(color: p.btn, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: ts(16, w: FontWeight.w700, c: p.onBtn),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Ph(a.$2[i].$1, size: 28, color: p.a700),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  a.$2[i].$2,
                                  style: ts(19, w: FontWeight.w700, c: p.text),
                                ),
                                const SizedBox(height: 8),
                                Text(a.$2[i].$3, style: ts(15, c: p.text2, h: 1.55)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Btn(a.$1, trailingIcon: PI.arrowRight, height: 52, onPressed: () => toAuth(aud == 'tenant' ? 'code' : 'role')),
          ],
        ),
      ),
    );
  }

  // ─── Paiements ───
  Widget _payments(BuildContext context, double w) {
    final p = context.pal;
    final two = w >= 900;
    final paidCount = payTick + 1;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Kicker('Paiements'),
        const SizedBox(height: 12),
        Text(
          'Un reçu en photo, et le loyer est suivi.',
          style: ts((w * 0.035).clamp(28.0, 40.0), w: FontWeight.w700, c: p.text, h: 1.15),
        ),
        const SizedBox(height: 16),
        Text(
          'Le locataire paie comme d’habitude, puis envoie la photo de son reçu et le montant payé. Le bailleur valide, la quittance PDF est générée et le locataire la retrouve dans son espace.',
          style: ts(17, c: p.text2, h: 1.55),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            StatusBadge('Photo du reçu', icon: PI.camera, height: 34, fontSize: 14),
            StatusBadge('Montant payé', icon: PI.money, height: 34, fontSize: 14),
            StatusBadge('Validation du bailleur', icon: PI.listChecks, height: 34, fontSize: 14),
          ],
        ),
      ],
    );
    final table = AppCard(
      padding: const EdgeInsets.all(20),
      shadow: AppShadows.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Loyers de novembre',
                  style: ts(18, w: FontWeight.w700, c: p.text),
                ),
              ),
              Text(
                'Immeuble A',
                style: ts(13, w: FontWeight.w600, c: p.text2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _pay.length; i++) ...[
            if (i > 0) const Hr(),
            Builder(
              builder: (_) {
                final paid = i != 1 && (i < paidCount || i == 0);
                final b = paid ? ('Payé', Tone.paid, PI.checkCircle) : (i == 1 ? ('En retard', Tone.late, PI.clock) : ('À venir', Tone.muted, PI.hourglass));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Avatar(_pay[i].$2, tone: _pay[i].$5),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pay[i].$1,
                              style: ts(15, w: FontWeight.w700, c: p.text),
                            ),
                            Text(
                              '${_pay[i].$3} · ${_pay[i].$4}',
                              style: ts(13, w: FontWeight.w500, c: p.text2),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (c, a) => ScaleTransition(
                          scale: a,
                          child: FadeTransition(opacity: a, child: c),
                        ),
                        child: StatusBadge(b.$1, key: ValueKey(b.$1), icon: b.$3, tone: b.$2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
    return Container(
      key: keys['payments'],
      color: p.card,
      padding: EdgeInsets.symmetric(horizontal: _pad(w), vertical: 80),
      child: MaxWidth(
        max: 1200,
        child: Reveal(
          scroll: scroll,
          child: two
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: 64),
                    Expanded(
                      child: Container(color: p.bg, padding: const EdgeInsets.all(24), child: table),
                    ),
                  ],
                )
              : Column(children: [text, const SizedBox(height: 32), table]),
        ),
      ),
    );
  }

  // ─── Appel à l'action ───
  Widget _cta(BuildContext context, double w) {
    final p = context.pal;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _pad(w), vertical: 80),
      child: MaxWidth(
        max: 1200,
        child: Reveal(
          scroll: scroll,
          child: Container(
            padding: EdgeInsets.all(w < 600 ? 28 : 48),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(color: p.btn, borderRadius: AppRadius.r, boxShadow: AppShadows.lg),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -120,
                  top: -120,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(color: p.onBtn.withValues(alpha: 0.08), shape: BoxShape.circle),
                  ),
                ),
                Builder(
                  builder: (_) {
                    final copy = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Prêt à simplifier votre gestion ?',
                          style: ts((w * 0.032).clamp(26.0, 36.0), w: FontWeight.w700, c: p.onBtn),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Vous êtes locataire ? Inscrivez-vous en choisissant votre cité : votre bailleur valide votre demande.',
                          style: ts(17, c: p.onBtn.withValues(alpha: 0.9), h: 1.5),
                        ),
                      ],
                    );
                    final buttons = Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _CtaBtn('Je suis bailleur', PI.handshake, filled: true, onTap: () => toAuth('role')),
                        _CtaBtn('Je suis locataire', PI.user, onTap: () => toAuth('code')),
                      ],
                    );
                    return w >= 900
                        ? Row(
                            children: [
                              Expanded(child: copy),
                              const SizedBox(width: 32),
                              buttons,
                            ],
                          )
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 24), buttons]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: MaxWidth(
        max: 1200,
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Logo(size: 28, fontSize: 17),
            Text('© 2026 MaCité · Gestion locative', style: ts(14, c: p.text2)),
            Wrap(
              spacing: 4,
              children: [
                LinkButton('Se connecter', onPressed: () => toAuth('login')),
                LinkButton('Mode sombre', icon: isDarkMode ? PI.sun : PI.moon, onPressed: () => setDarkMode(!isDarkMode)),
                LinkButton(
                  'Haut de page',
                  onPressed: () => scroll.animateTo(0, duration: const Duration(milliseconds: 600), curve: kEase),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool h = false;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return MouseRegion(
      onEnter: (_) => setState(() => h = true),
      onExit: (_) => setState(() => h = false),
      child: Tap(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: h ? p.a100 : Colors.transparent, borderRadius: AppRadius.r),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: ts(15, w: FontWeight.w500, c: h ? p.a800 : p.strong),
          ),
        ),
      ),
    );
  }
}

class _CtaBtn extends StatelessWidget {
  const _CtaBtn(this.label, this.icon, {required this.onTap, this.filled = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Tap(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: filled ? p.onBtn : Colors.transparent,
          borderRadius: AppRadius.r,
          border: Border.all(color: p.onBtn.withValues(alpha: filled ? 1 : 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Ph(icon, color: filled ? p.btn : p.onBtn),
            const SizedBox(width: 8),
            Text(
              label,
              style: ts(16, w: FontWeight.w600, c: filled ? p.btn : p.onBtn),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apparition au défilement : fondu + montée de 28 px quand le bloc entre à l'écran.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, required this.scroll, this.delay = Duration.zero});
  final Widget child;
  final ScrollController scroll;
  final Duration delay;
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool seen = false;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (seen || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final h = MediaQuery.sizeOf(context).height;
    if (top < h * 0.88) {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => seen = true);
      });
      widget.scroll.removeListener(_check);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: seen ? 1 : 0,
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOut,
    child: AnimatedSlide(offset: seen ? Offset.zero : const Offset(0, 0.06), duration: const Duration(milliseconds: 600), curve: kEase, child: widget.child),
  );
}
