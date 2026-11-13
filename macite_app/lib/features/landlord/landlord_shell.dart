import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/shell.dart';
import '../../widgets/ui.dart';
import 'landlord_buildings.dart';
import 'landlord_reports.dart';
import 'landlord_screens.dart';
import 'landlord_store.dart';
import 'landlord_techs.dart';

/// Espace bailleur (Daniel A., Cité Les Jardins).
class LandlordShell extends StatefulWidget {
  const LandlordShell({super.key, this.store});
  final LandlordStore? store;
  @override
  State<LandlordShell> createState() => _LandlordShellState();
}

class _LandlordShellState extends State<LandlordShell> {
  late final s = widget.store ?? LandlordStore();
  final _chat = TextEditingController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    s.toaster = (m) {
      if (mounted) showToast(context, m);
    };
  }

  @override
  void dispose() {
    s.dispose();
    _chat.dispose();
    _search.dispose();
    super.dispose();
  }

  void review(String id) => openProofReview(context, s, id);

  String get _mActive => switch (s.screen) {
    'tenant' => 'tenants',
    'rents' || 'ann' || 'settings' || 'techs' => 'more',
    'buildings' || 'building' || 'room' || 'roomForm' => 'buildings',
    'reports' || 'report' => 'reports',
    final x => x,
  };

  String get _dActive => switch (s.screen) {
    'tenant' || 'addTenant' => 'tenants',
    'building' || 'room' || 'roomForm' => 'buildings',
    'report' => 'reports',
    'more' => 'dashboard',
    final x => x,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final wide = context.isWide;
        if (wide && s.screen == 'more') s.screen = 'dashboard';
        final c = LCtx(s, wide, review);
        final content = s.loading ? (wide ? const _DeskSkeleton() : const _MobileSkeleton()) : KeyedSubtree(key: ValueKey(s.screen), child: _screen(c));
        return PopScope(
          canPop: s.screen == 'dashboard',
          onPopInvokedWithResult: (did, _) {
            if (did) return;
            switch (s.screen) {
              case 'tenant':
                s.go(const ['tenant', 'report', 'soon'].contains(s.prev) ? 'tenants' : s.prev);
              case 'building':
                s.go('buildings');
              case 'room':
                s.go('building');
              case 'roomForm':
                s.cancelRoom();
              case 'addTenant':
                s.atBack();
              case 'report':
                s.go('reports');
              case 'rents' || 'ann' || 'settings' || 'techs':
                s.go(wide ? 'dashboard' : 'more');
              default:
                s.go('dashboard');
            }
          },
          child: wide ? _desktop(content) : _mobile(content),
        );
      },
    );
  }

  Widget _screen(LCtx c) => switch (s.screen) {
    'tenants' => TenantsScreen(c),
    'tenant' => TenantDetail(c),
    'rents' => RentsScreen(c),
    'more' => MoreScreen(c),
    'buildings' => BuildingsScreen(c),
    'building' => BuildingDetail(c),
    'room' => RoomDetail(c),
    'roomForm' => RoomForm(c),
    'addTenant' => AddTenant(c),
    'reports' => ReportsScreen(c),
    'report' => ReportDetail(c, chat: _chat),
    'ann' => AnnouncementsScreen(c),
    'techs' => TechniciansScreen(c),
    'settings' => LandlordSettings(c),
    _ => Dashboard(c),
  };

  // ─── Mobile ───
  Widget _mobile(Widget content) {
    const noNav = ['tenant', 'room', 'roomForm', 'addTenant', 'report'];
    final fab = switch (s.screen) {
      'dashboard' || 'tenants' => ('Ajouter un locataire', () => s.newTenant()),
      'techs' => ('Ajouter un technicien', () => openAddTech(context, s)),
      'buildings' => ('Ajouter un immeuble', () => s.toast('Formulaire « Ajouter un immeuble » : même structure que celui d’une chambre')),
      'building' => ('Ajouter une chambre', s.addRoom),
      _ => null,
    };
    Widget? bottom;
    if (!s.loading) {
      if (s.screen == 'tenant' && s.sel.hasProof) {
        bottom = BottomActionBar(
          child: Btn('Vérifier le justificatif', icon: PI.listChecks, height: 56, expand: true, onPressed: () => review(s.sel.t.id)),
        );
      } else if (s.screen == 'roomForm') {
        bottom = BottomActionBar(
          child: Btn(s.rf.editing ? 'Enregistrer les modifications' : 'Ajouter la chambre', height: 56, expand: true, onPressed: s.saveRoom),
        );
      } else if (s.screen == 'addTenant' && s.at.step < 4) {
        bottom = BottomActionBar(child: Btn(s.at.step == 3 ? 'Ajouter le locataire' : 'Continuer', height: 56, expand: true, onPressed: s.atNext));
      } else if (s.screen == 'report') {
        bottom = _ChatBar(
          controller: _chat,
          onSend: () {
            s.sendChat(_chat.text);
            _chat.clear();
          },
        );
      }
    }
    return Scaffold(
      body: SafeArea(bottom: false, child: ScreenSwitcher(child: content)),
      floatingActionButton: fab != null && !s.loading
          ? PopIn(
              key: ValueKey(s.screen),
              child: Tooltip(
                message: fab.$1,
                child: Tap(
                  onTap: fab.$2,
                  scale: 0.92,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: context.pal.btn, borderRadius: AppRadius.r, boxShadow: AppShadows.md),
                    child: Center(child: Ph(PI.plus, size: 28, color: context.pal.onBtn)),
                  ),
                ),
              ),
            )
          : null,
      bottomNavigationBar: noNav.contains(s.screen)
          ? bottom
          : MobileNavBar(
              items: const [
                NavItem('dashboard', PI.house, 'Accueil'),
                NavItem('buildings', PI.buildings, 'Immeubles'),
                NavItem('tenants', PI.users, 'Locataires'),
                NavItem('reports', PI.wrench, 'Signalements'),
                NavItem('more', PI.list, 'Plus'),
              ],
              active: _mActive,
              onTap: (k) => s.go(k),
            ),
    );
  }

  // ─── Ordinateur ───
  Widget _desktop(Widget content) {
    return Scaffold(
      body: Row(
        children: [
          SideNav(
            items: [
              const NavItem('dashboard', PI.squaresFour, 'Tableau de bord'),
              const NavItem('buildings', PI.buildings, 'Immeubles'),
              const NavItem('tenants', PI.users, 'Locataires'),
              const NavItem('rents', PI.money, 'Loyers et paiements'),
              NavItem('reports', PI.wrench, 'Signalements', count: s.pending.length),
              const NavItem('techs', PI.hardHat, 'Techniciens'),
              const NavItem('ann', PI.megaphone, 'Annonces'),
              const NavItem('settings', PI.gear, 'Paramètres'),
            ],
            active: _dActive,
            onTap: (k) => s.go(k, more: false),
            footerTitle: 'Cité Les Jardins',
            footerText: '3 immeubles · 48 chambres',
          ),
          Expanded(
            child: Column(
              children: [
                DesktopHeader(
                  initials: 'DA',
                  name: 'Daniel A.',
                  searchHint: 'Rechercher un locataire, une chambre…',
                  searchController: _search,
                  onSearch: (v) {
                    s.query = v;
                    if (s.screen != 'tenants') {
                      s.go('tenants');
                    } else {
                      s.refresh();
                    }
                  },
                  onBell: () => s.go('reports'),
                ),
                Expanded(child: ScreenSwitcher(child: content)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBar extends StatelessWidget {
  const _ChatBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return BottomActionBar(
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: AppRadius.r,
                border: Border.all(color: p.line),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: ts(15, c: p.text),
                decoration: InputDecoration.collapsed(
                  hintText: 'Écrire au locataire…',
                  hintStyle: ts(15, c: p.text2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tap(
            onTap: onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: p.btn, borderRadius: AppRadius.r),
              child: Center(child: Ph(PI.paperPlaneRight, color: p.onBtn)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vérification d'un justificatif : bottom sheet (mobile) ou dialogue (ordinateur).
Future<void> openProofReview(BuildContext context, LandlordStore s, String id) {
  final t = s.tenants.firstWhere((x) => x.id == id);
  final v = TView(t, past: false);
  if (t.proof == null) return Future.value();
  final wide = context.isWide;
  Widget body(BuildContext ctx) {
    final p = ctx.pal;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 20, wide ? 24 : 12, wide ? 28 : 20, 24 + MediaQuery.paddingOf(ctx).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!wide)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: p.faint, borderRadius: AppRadius.r),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vérifier le justificatif',
                      style: ts(22, w: FontWeight.w700, c: p.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.name} · Chambre ${t.room} · envoyé le ${t.proof!.date}',
                      style: ts(14, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ),
              ),
              if (wide) IconBtn(PI.x, tooltip: 'Fermer', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
          const SizedBox(height: 16),
          ImageSlot('Photo du reçu envoyée par le locataire', height: wide ? 260 : 200, icon: PI.receipt),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: p.bg, borderRadius: AppRadius.r),
            child: Column(
              children: [
                KV('Montant déclaré', fmt(t.proof!.amount), valueColor: p.accent),
                const Hr(),
                KV('Reste dû avant validation', v.dueF),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const InfoNote('Vérifiez que le montant et la date du reçu correspondent avant de valider. Le locataire est prévenu dans les deux cas.'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Btn(
                  'Refuser',
                  icon: PI.x,
                  kind: BtnKind.dangerOutline,
                  height: 52,
                  expand: true,
                  onPressed: () {
                    Navigator.pop(ctx);
                    s.rejectProof(id);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Btn(
                  wide ? 'Valider le paiement' : 'Valider',
                  icon: PI.check,
                  height: 52,
                  expand: true,
                  onPressed: () {
                    Navigator.pop(ctx);
                    s.approveProof(id);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  if (wide) {
    return showDialog(
      context: context,
      barrierColor: context.pal.overlay,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: body(ctx)),
      ),
    );
  }
  return showModalBottomSheet(context: context, isScrollControlled: true, barrierColor: context.pal.overlay, builder: body);
}

class _MobileSkeleton extends StatelessWidget {
  const _MobileSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(height: 44, width: 220),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Skeleton(height: 120)),
            SizedBox(width: 16),
            Expanded(child: Skeleton(height: 120)),
          ],
        ),
        SizedBox(height: 16),
        Skeleton(height: 140),
        SizedBox(height: 16),
        Skeleton(height: 64),
        SizedBox(height: 10),
        Skeleton(height: 64),
      ],
    ),
  );
}

class _DeskSkeleton extends StatelessWidget {
  const _DeskSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(height: 48, width: 320),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(flex: 2, child: Skeleton(height: 150)),
            SizedBox(width: 16),
            Expanded(child: Skeleton(height: 150)),
            SizedBox(width: 16),
            Expanded(child: Skeleton(height: 150)),
            SizedBox(width: 16),
            Expanded(child: Skeleton(height: 150)),
          ],
        ),
        SizedBox(height: 24),
        Skeleton(height: 260),
      ],
    ),
  );
}
