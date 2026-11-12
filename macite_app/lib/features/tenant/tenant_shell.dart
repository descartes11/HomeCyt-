import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/shell.dart';
import '../../widgets/ui.dart';
import 'payment_proof.dart';
import 'tenant_screens.dart';
import 'tenant_store.dart';

const _mNav = [
  NavItem('home', PI.house, 'Accueil'),
  NavItem('report', PI.megaphone, 'Signaler'),
  NavItem('payments', PI.wallet, 'Paiements'),
  NavItem('city', PI.city, 'Ma cité'),
  NavItem('profile', PI.user, 'Profil'),
];

const _dNav = [
  NavItem('home', PI.house, 'Accueil'),
  NavItem('report', PI.megaphone, 'Signaler un problème'),
  NavItem('myreports', PI.listBullets, 'Mes signalements'),
  NavItem('payments', PI.wallet, 'Paiements'),
  NavItem('city', PI.city, 'Ma cité'),
  NavItem('profile', PI.user, 'Mon profil'),
  NavItem('settings', PI.gear, 'Paramètres'),
];

/// Espace locataire (Sarah M., chambre A-102).
class TenantShell extends StatefulWidget {
  const TenantShell({super.key, this.store});
  final TenantStore? store;
  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  late final s = widget.store ?? TenantStore();

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
    super.dispose();
  }

  void _nav(String k) => k == 'report' ? s.startReport() : s.go(k);

  void openPay() => openPaymentProof(context, s);

  String get _mActive => switch (s.screen) {
    'myreports' => 'report',
    'settings' => 'profile',
    'notifs' => 'home',
    final x => x,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final wide = context.isWide;
        final ctx = TenantCtx(s, openPay, wide);
        final content = s.loading
            ? (wide ? const _DeskSkeleton() : const _MobileSkeleton())
            : KeyedSubtree(key: ValueKey('${s.screen}-${s.screen == 'report' ? s.step : ''}'), child: tenantScreen(ctx));
        return PopScope(
          canPop: s.screen == 'home',
          onPopInvokedWithResult: (did, _) {
            if (did) return;
            if (s.screen == 'report') {
              s.stepBack();
            } else if (s.screen == 'settings') {
              s.go('profile');
            } else {
              s.go('home');
            }
          },
          child: wide ? _desktop(context, content) : _mobile(context, content),
        );
      },
    );
  }

  Widget _mobile(BuildContext context, Widget content) {
    final showBar = s.screen == 'report' && (s.step == 2 || s.step == 3) && !s.loading;
    return Scaffold(
      body: SafeArea(bottom: false, child: ScreenSwitcher(child: content)),
      bottomNavigationBar: s.screen == 'report'
          ? (showBar
                ? BottomActionBar(
                    child: Btn(
                      s.step == 3 ? (s.sending ? 'Envoi…' : 'Envoyer le signalement') : 'Continuer',
                      busy: s.sending,
                      height: 56,
                      expand: true,
                      onPressed: s.next,
                    ),
                  )
                : null)
          : MobileNavBar(items: _mNav, active: _mActive, onTap: _nav),
    );
  }

  Widget _desktop(BuildContext context, Widget content) {
    return Scaffold(
      body: Row(
        children: [
          SideNav(items: _dNav, active: s.screen, onTap: _nav, footerTitle: 'Chambre A-102', footerText: 'Immeuble A · Les Lauriers'),
          Expanded(
            child: Column(
              children: [
                DesktopHeader(
                  initials: 'SM',
                  name: 'Sarah M.',
                  searchHint: 'Rechercher une annonce, un contact…',
                  bellDot: s.unread > 0,
                  onBell: () => s.go('notifs'),
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
        Skeleton(height: 150),
        SizedBox(height: 16),
        Skeleton(height: 160),
        SizedBox(height: 16),
        Skeleton(height: 80),
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
            Expanded(child: Skeleton(height: 200)),
            SizedBox(width: 16),
            Expanded(child: Skeleton(height: 200)),
            SizedBox(width: 16),
            Expanded(child: Skeleton(height: 200)),
          ],
        ),
        SizedBox(height: 24),
        Skeleton(height: 180),
      ],
    ),
  );
}
