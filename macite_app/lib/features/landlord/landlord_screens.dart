import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/fields.dart';
import '../../widgets/ui.dart';
import 'landlord_store.dart';

class LCtx {
  const LCtx(this.s, this.wide, this.review);
  final LandlordStore s;
  final bool wide;
  final void Function(String id) review;
}

/// Défilement + marges d'écran (16 mobile, 32 ordinateur), apparition en cascade.
class LPage extends StatelessWidget {
  const LPage({super.key, required this.wide, required this.children, this.max = 1200, this.gap = 24, this.bottomPad = 32});
  final bool wide;
  final List<Widget> children;
  final double max, gap, bottomPad;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: wide ? const EdgeInsets.fromLTRB(32, 28, 32, 48) : EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
    child: MaxWidth(
      max: wide ? max : 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            FadeUp(
              delay: Duration(milliseconds: (i * 40).clamp(0, 240)),
              child: children[i],
            ),
          ],
        ],
      ),
    ),
  );
}

/// En-tête d'écran : titre (+ sous-titre) et actions.
class LHeader extends StatelessWidget {
  const LHeader(this.title, {super.key, this.sub, this.actions = const [], this.onBack, this.wide = false});
  final String title;
  final String? sub;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        if (onBack != null)
          Transform.translate(
            offset: const Offset(-12, 0),
            child: IconBtn(PI.arrowLeft, tooltip: 'Retour', onPressed: onBack),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenTitle(title, size: wide ? 32 : 28),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub!,
                  style: ts(14, w: FontWeight.w500, c: p.text2),
                ),
              ],
            ],
          ),
        ),
        for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 8), actions[i]],
      ],
    );
  }
}

/// Ligne de tableau « ordinateur ».
class DRow extends StatelessWidget {
  const DRow({super.key, required this.cells, required this.flex, this.header = false, this.onTap});
  final List<Object> cells;
  final List<int> flex;
  final bool header;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      constraints: BoxConstraints(minHeight: header ? 40 : 60),
      decoration: BoxDecoration(
        color: header ? p.bg : null,
        border: header ? null : Border(top: BorderSide(color: p.divider)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: cells[i] is Widget
                  ? Align(alignment: Alignment.centerLeft, child: cells[i] as Widget)
                  : Text(
                      cells[i] as String,
                      overflow: TextOverflow.ellipsis,
                      style: header ? ts(12, w: FontWeight.w700, c: p.text2, ls: 0.4) : ts(14, w: FontWeight.w500, c: p.strong),
                    ),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return _HoverRow(onTap: onTap!, child: row);
  }
}

class _HoverRow extends StatefulWidget {
  const _HoverRow({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => h = true),
    onExit: (_) => setState(() => h = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: h ? context.pal.a100.withValues(alpha: 0.6) : Colors.transparent,
        child: widget.child,
      ),
    ),
  );
}

/// Locataire : avatar + nom + sous-titre.
class PersonCell extends StatelessWidget {
  const PersonCell(this.v, {super.key, this.sub, this.size = 40});
  final TView v;
  final String? sub;
  final double size;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        Avatar(v.t.initials, tone: v.t.avatar, size: size),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                v.t.name,
                overflow: TextOverflow.ellipsis,
                style: ts(15, w: FontWeight.w700, c: p.text),
              ),
              if (sub != null)
                Text(
                  sub!,
                  overflow: TextOverflow.ellipsis,
                  style: ts(13, w: FontWeight.w500, c: p.text2),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget badgeOf(TView v) => StatusBadge(v.badge.label, icon: v.badge.icon, tone: v.badge.tone);

// ───────────────────────────── Tableau de bord ─────────────────────────────

class Dashboard extends StatelessWidget {
  const Dashboard(this.c, {super.key});
  final LCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final late = s.late;
    final proofs = s.proofs;

    Widget todo(IconData ic, Color tileBg, String title, String sub, VoidCallback onTap) => AppCard(
      color: p.chip,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          IconTile(ic, bg: tileBg, fg: p.card),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ts(16, w: FontWeight.w700, c: p.text),
                ),
                Text(
                  sub,
                  style: ts(13, w: FontWeight.w500, c: p.strong),
                ),
              ],
            ),
          ),
          Ph(PI.caretRight, color: p.strong),
        ],
      ),
    );
    final todos = [
      if (s.regs.isNotEmpty)
        todo(
          PI.userCheck,
          p.strong,
          '${s.regs.length} inscription${s.regs.length > 1 ? 's' : ''} à valider',
          'Nouveaux locataires inscrits dans votre cité',
          () => s.go('tenants'),
        ),
      if (proofs.isNotEmpty)
        todo(
          PI.listChecks,
          p.text2,
          '${proofs.length} justificatif${proofs.length > 1 ? 's' : ''} à vérifier',
          'Reçus envoyés par vos locataires',
          () => s.go('rents', more: false),
        ),
    ];

    final hero = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: p.btn, borderRadius: AppRadius.r, boxShadow: AppShadows.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Ph(PI.money, size: 18, color: p.onBtn),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Loyers payés · novembre',
                  overflow: TextOverflow.ellipsis,
                  style: ts(13, w: FontWeight.w500, c: p.onBtn),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: s.collected.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: kEase,
            builder: (_, v, _) => Text(
              fmt(v),
              style: ts(32, w: FontWeight.w700, c: p.onBtn, h: 1.1, ls: -0.3),
            ),
          ),
          const SizedBox(height: 10),
          Progress(s.rate, color: p.onBtn, track: p.onBtn.withValues(alpha: 0.25)),
          const SizedBox(height: 8),
          Text(
            '${(s.rate * 100).round()} % de ${fmt(s.expected)} attendus',
            style: ts(13, w: FontWeight.w500, c: p.onBtn),
          ),
        ],
      ),
    );

    Widget kpi(IconData ic, Tone tone, String label, String value, String foot, {Color? footColor, VoidCallback? onTap}) => AppCard(
      onTap: onTap,
      child: c.wide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: ts(13, w: FontWeight.w500, c: p.text2),
                      ),
                    ),
                    IconTile(ic, size: 36, iconSize: 20, tone: tone),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: ts(24, w: FontWeight.w700, c: p.text),
                ),
                const SizedBox(height: 4),
                Text(
                  foot,
                  style: ts(13, w: FontWeight.w500, c: footColor ?? p.text2),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(ic, size: 36, iconSize: 20, tone: tone),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: ts(13, w: FontWeight.w500, c: p.text2),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: ts(20, w: FontWeight.w700, c: p.text),
                ),
                const SizedBox(height: 4),
                Text(
                  foot,
                  style: ts(13, w: FontWeight.w500, c: footColor ?? p.text2),
                ),
              ],
            ),
    );

    final kUnpaid = kpi(
      PI.clock,
      Tone.late,
      'Loyers impayés',
      fmt(s.unpaid),
      late.isEmpty ? 'Aucun retard' : '${late.length} locataire${late.length > 1 ? 's' : ''} concerné${late.length > 1 ? 's' : ''}',
      footColor: p.m700,
      onTap: () => s.go('rents', more: false),
    );
    final kPending = kpi(
      PI.wrench,
      Tone.neutral,
      'Problèmes en attente',
      '${s.pending.length}',
      'dont ${s.urgentCount} urgents',
      footColor: p.strong,
      onTap: () => s.go('reports'),
    );
    final kRooms = kpi(PI.bed, Tone.soft, 'Chambres', '48', '3 immeubles', onTap: () => s.go('buildings'));
    final kOcc = kpi(PI.chartDonut, Tone.paid, c.wide ? 'Occupation' : 'Taux d’occupation', '92 %', '4 chambres libres');

    final lateCard = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Loyers en retard', action: 'Voir tout', onAction: () => s.go('rents', more: false)),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: late.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      Ph(PI.confetti, color: p.a700),
                      const SizedBox(width: 10),
                      Text(
                        'Tous les loyers du mois sont payés.',
                        style: ts(15, w: FontWeight.w600, c: p.text),
                      ),
                    ],
                  ),
                )
              : Separated(
                  children: [
                    for (final v in late)
                      Tap(
                        onTap: () => s.openTenant(v.t.id),
                        scale: 0.99,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(child: PersonCell(v, sub: '${v.t.room} · ${v.detail}')),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    v.dueF,
                                    style: ts(15, w: FontWeight.w700, c: p.text),
                                  ),
                                  const SizedBox(height: 4),
                                  badgeOf(v),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );

    final reps = s.pending.take(4).toList();
    final repsCard = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Derniers signalements', action: c.wide ? 'Voir tout' : null, onAction: () => s.go('reports')),
        const SizedBox(height: 12),
        if (c.wide)
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 48) / 4;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final r in reps)
                    SizedBox(
                      width: w,
                      child: ReportCard(r, onTap: () => s.openReport(r.id), photo: true),
                    ),
                ],
              );
            },
          )
        else
          for (final r in reps.take(3)) ...[
            AppCard(
              onTap: () => s.openReport(r.id),
              child: Row(
                children: [
                  IconTile(catStyle[r.cat]!.$1, tone: catStyle[r.cat]!.$2),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: ts(15, w: FontWeight.w700, c: p.text),
                        ),
                        Text(
                          '${r.room} · ${r.when}',
                          style: ts(13, w: FontWeight.w500, c: p.text2),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(urgStyle[r.u]!.$1, icon: urgStyle[r.u]!.$3, tone: urgStyle[r.u]!.$2),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );

    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          LHeader(
            'Bonjour, Daniel',
            wide: true,
            sub: 'Mercredi 4 novembre 2026',
            actions: [Btn('Ajouter un locataire', icon: PI.userPlus, onPressed: () => s.newTenant())],
          ),
          if (todos.isNotEmpty)
            Row(
              children: [
                for (var i = 0; i < todos.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: todos[i])],
              ],
            ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: hero),
                const SizedBox(width: 16),
                Expanded(child: kUnpaid),
                const SizedBox(width: 16),
                Expanded(child: kPending),
                const SizedBox(width: 16),
                Expanded(child: kRooms),
                const SizedBox(width: 16),
                Expanded(child: kOcc),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: lateCard),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _Chart(s: s)),
            ],
          ),
          repsCard,
        ],
      );
    }

    return LPage(
      wide: false,
      bottomPad: 96,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mercredi 4 novembre',
                    style: ts(13, w: FontWeight.w500, c: p.text2),
                  ),
                  const ScreenTitle('Bonjour, Daniel'),
                ],
              ),
            ),
            IconBtn(PI.bell, filled: true, dot: true, tooltip: 'Notifications', onPressed: () => s.go('reports')),
          ],
        ),
        if (todos.isNotEmpty)
          Column(
            children: [
              for (var i = 0; i < todos.length; i++) ...[if (i > 0) const SizedBox(height: 8), todos[i]],
            ],
          ),
        Column(
          children: [
            hero,
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: kUnpaid),
                  const SizedBox(width: 16),
                  Expanded(child: kPending),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: kRooms),
                  const SizedBox(width: 16),
                  Expanded(child: kOcc),
                ],
              ),
            ),
          ],
        ),
        lateCard,
        repsCard,
      ],
    );
  }
}

/// Graphique des encaissements (6 derniers mois, en milliers de FCFA).
class _Chart extends StatelessWidget {
  const _Chart({required this.s});
  final LandlordStore s;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final data = [...chartData.map((e) => (e.$1, e.$2, false)), ('Nov.', (s.collected / 1000).round(), true)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Encaissements'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < data.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                formatNumber(data[i].$2),
                                style: ts(11, w: FontWeight.w600, c: data[i].$3 ? p.a800 : p.text2),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: data[i].$2 / 1800),
                                duration: Duration(milliseconds: 600 + i * 80),
                                curve: kEase,
                                builder: (_, v, _) => Container(
                                  height: 170 * v,
                                  decoration: BoxDecoration(
                                    color: data[i].$3 ? p.a200 : p.btn,
                                    borderRadius: AppRadius.r,
                                    border: data[i].$3 ? Border.all(color: p.a500, width: 2) : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data[i].$1,
                                style: ts(12, w: FontWeight.w600, c: p.text2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'En milliers de FCFA · novembre en cours',
                style: ts(12, w: FontWeight.w500, c: p.text2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Carte de signalement (tableau de bord, liste, kanban).
class ReportCard extends StatelessWidget {
  const ReportCard(this.r, {super.key, required this.onTap, this.photo = false, this.showStatus = true});
  final Report r;
  final VoidCallback onTap;
  final bool photo, showStatus;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final u = urgStyle[r.u]!;
    final cs = catStyle[r.cat]!;
    final st = repStatus[r.st]!;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo) const ImageSlot('Photo du problème', height: 110, icon: PI.camera),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusBadge(u.$1, icon: u.$3, tone: u.$2),
                    if (showStatus) StatusBadge(st.$1, tone: st.$2),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Ph(cs.$1, size: 18, color: p.text),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.title,
                        overflow: TextOverflow.ellipsis,
                        style: ts(15, w: FontWeight.w700, c: p.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.cat} · ${r.room} · ${r.when}',
                  overflow: TextOverflow.ellipsis,
                  style: ts(13, w: FontWeight.w500, c: p.text2),
                ),
                if (r.tech.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Ph(PI.hardHat, size: 16, color: p.text2),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          r.tech,
                          overflow: TextOverflow.ellipsis,
                          style: ts(12, w: FontWeight.w600, c: p.text2),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Locataires ─────────────────────────────

class TenantsScreen extends StatelessWidget {
  const TenantsScreen(this.c, {super.key});
  final LCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final list = s.tenantList;
    final regs = s.regs.isEmpty
        ? null
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.chip, borderRadius: AppRadius.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Demandes d’inscription',
                      style: ts(18, w: FontWeight.w700, c: p.text),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge('${s.regs.length}', tone: Tone.solid),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.wide
                      ? 'Ces locataires se sont inscrits en choisissant votre cité. Vérifiez leurs informations avant de valider.'
                      : 'Ces locataires se sont inscrits en choisissant votre cité. Vérifiez leurs informations.',
                  style: ts(14, c: p.strong, h: 1.45),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, box) {
                    final w = c.wide ? (box.maxWidth - 16) / 2 : box.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        for (final g in s.regs)
                          SizedBox(
                            width: w,
                            child: _RegCard(g: g, s: s),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );

    final search = AppField(initialValue: s.query, icon: PI.magnifyingGlass, hint: 'Nom ou chambre', onChanged: (v) => s.set(() => s.query = v));
    final filters = ChipRow(
      wrap: c.wide,
      children: [
        for (final f in const [('all', 'Tous'), ('ok', 'À jour'), ('late', 'En retard')])
          ChoiceChipX(f.$2, selected: s.tFilter == f.$1, onTap: () => s.set(() => s.tFilter = f.$1)),
        if (!c.wide) const SizedBox(width: 4),
        for (final f in const [('all', 'Tous les immeubles'), ('A', 'Immeuble A'), ('B', 'Immeuble B'), ('C', 'Immeuble C')])
          ChoiceChipX(f.$2, selected: s.bFilter == f.$1, onTap: () => s.set(() => s.bFilter = f.$1)),
      ],
    );
    const empty = EmptyState(icon: PI.userFocus, title: 'Aucun locataire trouvé', text: 'Essayez un autre nom ou retirez un filtre.');

    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          LHeader(
            'Mes locataires',
            wide: true,
            sub: '${s.tenants.length} locataires · 3 immeubles',
            actions: [
              Btn('Télécharger tout (PDF)', icon: PI.filePdf, kind: BtnKind.outline, onPressed: s.pdfAll),
              Btn('Ajouter un locataire', icon: PI.userPlus, onPressed: () => s.newTenant()),
            ],
          ),
          ?regs,
          Row(
            children: [
              SizedBox(width: 320, child: search),
              const SizedBox(width: 16),
              Expanded(child: filters),
            ],
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const DRow(header: true, flex: [4, 2, 2, 2, 2, 1], cells: ['Locataire', 'Chambre', 'Immeuble', 'Loyer', 'Paiement', '']),
                for (final v in list)
                  DRow(
                    onTap: () => s.openTenant(v.t.id),
                    flex: const [4, 2, 2, 2, 2, 1],
                    cells: [
                      PersonCell(v, sub: v.t.phone),
                      v.t.room,
                      v.t.bldName,
                      v.t.rentF,
                      badgeOf(v),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Ph(PI.caretRight, color: p.text2),
                      ),
                    ],
                  ),
                if (list.isEmpty) empty,
              ],
            ),
          ),
        ],
      );
    }

    return LPage(
      wide: false,
      gap: 16,
      bottomPad: 96,
      children: [
        Row(
          children: [
            const Expanded(child: ScreenTitle('Mes locataires')),
            Btn('Tout en PDF', icon: PI.filePdf, kind: BtnKind.outline, height: 40, fontSize: 14, padding: 12, onPressed: s.pdfAll),
          ],
        ),
        ?regs,
        search,
        filters,
        if (list.isEmpty)
          empty
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Separated(
              children: [
                for (final v in list)
                  Tap(
                    onTap: () => s.openTenant(v.t.id),
                    scale: 0.99,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: PersonCell(v, sub: 'Chambre ${v.t.room} · ${v.t.bldName}')),
                          badgeOf(v),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RegCard extends StatelessWidget {
  const _RegCard({required this.g, required this.s});
  final Registration g;
  final LandlordStore s;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget line(IconData ic, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Ph(ic, size: 16, color: p.text2),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              t,
              overflow: TextOverflow.ellipsis,
              style: ts(13, w: FontWeight.w500, c: p.strong),
            ),
          ),
        ],
      ),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(g.initials, tone: Tone.neutral),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.name,
                      style: ts(16, w: FontWeight.w700, c: p.text),
                    ),
                    Text(
                      'Chambre demandée : ${g.room} · ${g.date}',
                      style: ts(13, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          line(PI.phone, g.phone),
          line(PI.envelope, g.email),
          line(PI.briefcase, '${g.job} · ${g.org}'),
          line(PI.identificationCard, 'CNI n° ${g.cni}'),
          const SizedBox(height: 8),
          const ImageSlot('Photo de la CNI', height: 110, icon: PI.identificationCard),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Btn('Refuser', icon: PI.x, kind: BtnKind.dangerOutline, height: 44, fontSize: 15, expand: true, onPressed: () => s.rejectReg(g)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Btn('Valider', icon: PI.userCheck, height: 44, fontSize: 15, expand: true, onPressed: () => s.approveReg(g)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Fiche locataire ─────────────────────────────

class TenantDetail extends StatelessWidget {
  const TenantDetail(this.c, {super.key});
  final LCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final v = s.sel;
    final t = v.t;
    final hist = s.historyOf(v);
    final reps = s.reports.where((r) => r.tenantId == t.id).toList();
    void back() => s.go(const ['tenant', 'report', 'soon'].contains(s.prev) ? 'tenants' : s.prev);
    final backLabel = switch (s.prev) {
      'rents' => 'Loyers et paiements',
      'dashboard' => 'Tableau de bord',
      'room' => 'Chambre',
      _ => 'Mes locataires',
    };

    final notes = _Notes(s: s, id: t.id);
    final repList = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Signalements envoyés',
          style: ts(18, w: FontWeight.w600, c: p.text),
        ),
        const SizedBox(height: 10),
        if (reps.isEmpty)
          Row(
            children: [
              Ph(PI.tray, color: p.text2),
              const SizedBox(width: 8),
              Flexible(
                child: Text('Aucun signalement envoyé.', style: ts(14, c: p.text2)),
              ),
            ],
          )
        else
          for (final r in reps)
            Tap(
              onTap: () => s.openReport(r.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    IconTile(catStyle[r.cat]!.$1, tone: catStyle[r.cat]!.$2, size: 36, iconSize: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: ts(14, w: FontWeight.w700, c: p.text),
                          ),
                          Text(
                            r.when,
                            style: ts(12, w: FontWeight.w500, c: p.text2),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(repStatus[r.st]!.$1, tone: repStatus[r.st]!.$2),
                  ],
                ),
              ),
            ),
      ],
    );
    final info = [
      InfoRow(icon: PI.phone, label: 'Téléphone', value: t.phone),
      InfoRow(icon: PI.briefcase, label: 'Fonction', value: '${t.job} · ${t.org}'),
      InfoRow(icon: PI.envelope, label: 'E-mail', value: t.email),
      if (!c.wide) InfoRow(icon: PI.calendarBlank, label: 'Entrée · bail', value: '${t.since} · ${t.lease}'),
      if (!c.wide)
        InfoRow(
          icon: PI.identificationCard,
          label: 'Pièce d’identité',
          value: t.idDoc,
          trailing: Ph(PI.eye, color: p.link),
          onTap: () => s.toast('Pièce d’identité ouverte'),
        ),
      InfoRow(icon: PI.firstAid, label: 'Contact d’urgence', value: t.emergency),
    ];

    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          Breadcrumb(backLabel: backLabel, onBack: back, current: t.name),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, box) {
                final identity = Row(
                  children: [
                    Avatar(t.initials, tone: t.avatar, size: 72),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            style: ts(28, w: FontWeight.w700, c: p.text),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Chambre ${t.room} · ${t.bldName} · depuis le ${t.since}',
                                style: ts(14, w: FontWeight.w500, c: p.text2),
                              ),
                              badgeOf(v),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final actions = [
                  IconBtn(PI.filePdf, tooltip: 'Télécharger la fiche en PDF', color: p.link, onPressed: s.pdfOne),
                  Btn('Appeler', icon: PI.phone, kind: BtnKind.outline, onPressed: () => s.toast('Appel vers ${t.phone}…')),
                  Btn(
                    'Envoyer un message',
                    icon: PI.chatCircle,
                    kind: v.hasProof ? BtnKind.outline : BtnKind.primary,
                    onPressed: () => s.toast('Ouverture de la conversation avec ${t.name}'),
                  ),
                  if (v.hasProof) Btn('Vérifier le justificatif', icon: PI.listChecks, onPressed: () => c.review(t.id)),
                ];
                // Assez de place : actions à droite du nom, sur une ligne (mise en page d'origine).
                if (box.maxWidth >= 900) {
                  return Row(
                    children: [
                      Expanded(child: identity),
                      for (final a in actions) ...[const SizedBox(width: 8), a],
                    ],
                  );
                }
                // Écran plus étroit : actions sous le nom, avec retour à la ligne si besoin.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
                  ],
                );
              },
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 360,
                child: Column(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Coordonnées',
                            style: ts(18, w: FontWeight.w600, c: p.text),
                          ),
                          const SizedBox(height: 4),
                          Separated(indent: 38, children: info),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Bail',
                            style: ts(18, w: FontWeight.w600, c: p.text),
                          ),
                          const SizedBox(height: 4),
                          KV('Chambre', t.room),
                          KV('Loyer mensuel', t.rentF),
                          KV('Date d’entrée', t.since),
                          KV('Durée du bail', t.lease),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pièce d’identité',
                            style: ts(18, w: FontWeight.w600, c: p.text),
                          ),
                          Text(
                            t.idDoc,
                            style: ts(13, w: FontWeight.w500, c: p.text2),
                          ),
                          const SizedBox(height: 10),
                          const ImageSlot('Scan de la pièce d’identité', height: 150, icon: PI.identificationCard),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Historique des paiements',
                                    style: ts(18, w: FontWeight.w600, c: p.text),
                                  ),
                                ),
                                Text(
                                  '6 derniers mois',
                                  style: ts(13, w: FontWeight.w500, c: p.text2),
                                ),
                              ],
                            ),
                          ),
                          const DRow(header: true, flex: [3, 2, 4, 2, 1], cells: ['Mois', 'Montant', 'Détail', 'Statut', '']),
                          for (final h in hist)
                            DRow(
                              flex: const [3, 2, 4, 2, 1],
                              cells: [
                                Text(
                                  h.$1,
                                  style: ts(14, w: FontWeight.w600, c: p.text),
                                ),
                                h.$2,
                                h.$3,
                                StatusBadge(h.$4.label, icon: h.$4.icon, tone: h.$4.tone),
                                h.$5
                                    ? IconBtn(
                                        PI.downloadSimple,
                                        size: 40,
                                        color: p.link,
                                        tooltip: 'Quittance PDF',
                                        onPressed: () => s.receiptFor(s.sel.t, months.indexOf(h.$1)),
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: AppCard(child: repList)),
                        const SizedBox(width: 16),
                        Expanded(child: AppCard(child: notes)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        DetailBar(
          title: 'Fiche locataire',
          onBack: back,
          actions: [IconBtn(PI.filePdf, tooltip: 'Télécharger la fiche en PDF', color: p.link, onPressed: s.pdfOne)],
        ),
        Expanded(
          child: LPage(
            wide: false,
            gap: 16,
            children: [
              Column(
                children: [
                  Avatar(t.initials, tone: t.avatar, size: 72),
                  const SizedBox(height: 10),
                  Text(
                    t.name,
                    style: ts(24, w: FontWeight.w700, c: p.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chambre ${t.room} · ${t.bldName}',
                    style: ts(14, w: FontWeight.w500, c: p.text2),
                  ),
                  const SizedBox(height: 8),
                  badgeOf(v),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Btn('Appeler', icon: PI.phone, kind: BtnKind.outline, expand: true, onPressed: () => s.toast('Appel vers ${t.phone}…')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Btn(
                      'Message',
                      icon: PI.chatCircle,
                      kind: BtnKind.outline,
                      expand: true,
                      onPressed: () => s.toast('Ouverture de la conversation avec ${t.name}'),
                    ),
                  ),
                ],
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loyer de novembre',
                      style: ts(13, w: FontWeight.w600, c: p.text2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          t.rentF,
                          style: ts(24, w: FontWeight.w700, c: p.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            v.detail,
                            textAlign: TextAlign.right,
                            style: ts(13, w: FontWeight.w600, c: v.isPaid ? p.a800 : p.m700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Informations',
                      style: ts(18, w: FontWeight.w600, c: p.text),
                    ),
                    Separated(indent: 38, children: info),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Historique des paiements',
                      style: ts(18, w: FontWeight.w600, c: p.text),
                    ),
                    const SizedBox(height: 4),
                    for (final h in hist.take(4))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.$1,
                                    style: ts(14, w: FontWeight.w700, c: p.text),
                                  ),
                                  Text(
                                    h.$3,
                                    style: ts(12, w: FontWeight.w500, c: p.text2),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(h.$4.label, icon: h.$4.icon, tone: h.$4.tone),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              AppCard(child: repList),
              AppCard(child: notes),
            ],
          ),
        ),
      ],
    );
  }
}

class _Notes extends StatefulWidget {
  const _Notes({required this.s, required this.id});
  final LandlordStore s;
  final String id;
  @override
  State<_Notes> createState() => _NotesState();
}

class _NotesState extends State<_Notes> {
  late final ctrl = TextEditingController(text: widget.s.notes[widget.id] ?? '');
  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Ph(PI.lock, size: 18, color: p.text2),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.isWide ? 'Notes privées' : 'Notes privées (visibles par vous seul)',
                style: ts(14, w: FontWeight.w600, c: p.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppField(
          controller: ctrl,
          maxLines: 3,
          hint: context.isWide ? 'Visible par vous seul…' : 'Ajouter une note…',
          onChanged: (v) => widget.s.notes[widget.id] = v,
        ),
      ],
    );
  }
}

// ───────────────────────────── Loyers ─────────────────────────────

class RentsScreen extends StatelessWidget {
  const RentsScreen(this.c, {super.key});
  final LCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final list = s.rentList;
    final proofs = s.proofs;
    final month = AppSelect<int>(
      icon: PI.calendar,
      value: s.monthIdx,
      items: const [(0, 'Novembre 2026'), (1, 'Octobre 2026'), (2, 'Septembre 2026')],
      onChanged: (v) => s.set(() => s.monthIdx = v ?? 0),
    );
    final pct = s.rExpected == 0 ? 0.0 : s.rPaid / s.rExpected;

    final proofBox = proofs.isEmpty
        ? null
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.chip, borderRadius: AppRadius.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Justificatifs à vérifier',
                      style: ts(18, w: FontWeight.w700, c: p.text),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge('${proofs.length}', tone: Tone.solid),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, box) {
                    final w = c.wide ? (box.maxWidth - 16) / 2 : box.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        for (final v in proofs)
                          SizedBox(
                            width: w,
                            child: AppCard(
                              padding: const EdgeInsets.all(10),
                              onTap: () => c.review(v.t.id),
                              child: Row(
                                children: [
                                  const ImageSlot('Reçu', width: 56, height: 56, compact: true, icon: PI.receipt),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.t.name,
                                          style: ts(15, w: FontWeight.w700, c: p.text),
                                        ),
                                        Text(
                                          '${v.t.room} · envoyé le ${v.t.proof!.date}',
                                          style: ts(12, w: FontWeight.w500, c: p.text2),
                                        ),
                                        Text(
                                          fmt(v.t.proof!.amount),
                                          style: ts(15, w: FontWeight.w700, c: p.accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge('Vérifier', icon: PI.listChecks, tone: Tone.strong, height: 32),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );

    final rf = ChipRow(
      wrap: c.wide,
      children: [
        for (final f in [
          ('all', 'Tous (${s.rentsAll.length})'),
          ('paid', 'Payé (${s.rentCount('paid')})'),
          ('partial', 'Partiel (${s.rentCount('partial')})'),
          ('late', 'En retard (${s.rentCount('late')})'),
        ])
          ChoiceChipX(f.$2, selected: s.rFilter == f.$1, onTap: () => s.set(() => s.rFilter = f.$1)),
      ],
    );
    final bf = ChipRow(
      wrap: c.wide,
      children: [
        for (final f in const [('all', 'Tous les immeubles'), ('A', 'Immeuble A'), ('B', 'Immeuble B'), ('C', 'Immeuble C')])
          ChoiceChipX(f.$2, selected: s.bFilter == f.$1, onTap: () => s.set(() => s.bFilter = f.$1)),
      ],
    );
    const empty = EmptyState(icon: PI.checkCircle, title: 'Rien à afficher', text: 'Aucun loyer ne correspond à ce filtre.');

    List<Widget> actions(TView v) => [
      if (v.hasProof) Btn('Vérifier', icon: PI.listChecks, height: 40, fontSize: 14, padding: 12, onPressed: () => c.review(v.t.id)),
      if (v.canRemind) Btn('Relancer', icon: PI.bellRinging, kind: BtnKind.outline, height: 40, fontSize: 14, padding: 12, onPressed: () => s.remind(v)),
      if (v.isPaid) Btn('Quittance', icon: PI.filePdf, kind: BtnKind.ghost, height: 40, fontSize: 14, padding: 12, onPressed: () => s.receipt(v)),
    ];

    if (c.wide) {
      Widget sum(String l, String v, {Widget? extra, Color? color}) => AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l,
              style: ts(13, w: FontWeight.w500, c: p.text2),
            ),
            const SizedBox(height: 6),
            Text(
              v,
              style: ts(24, w: FontWeight.w700, c: color ?? p.text),
            ),
            if (extra != null) ...[const SizedBox(height: 10), extra],
          ],
        ),
      );
      return LPage(
        wide: true,
        children: [
          LHeader(
            'Loyers et paiements',
            wide: true,
            sub: 'Échéance le 5 de chaque mois',
            actions: [
              SizedBox(width: 220, child: month),
              Btn('Quittances du mois', icon: PI.filePdf, kind: BtnKind.outline, onPressed: s.receiptsOfMonth),
            ],
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: sum('Attendu', fmt(s.rExpected))),
                const SizedBox(width: 16),
                Expanded(child: sum('Payé', fmt(s.rPaid), color: p.accent)),
                const SizedBox(width: 16),
                Expanded(child: sum('Reste à payer', fmt(s.rExpected - s.rPaid), color: p.m700)),
                const SizedBox(width: 16),
                Expanded(child: sum('Taux de recouvrement', '${(pct * 100).round()} %', extra: Progress(pct))),
              ],
            ),
          ),
          ?proofBox,
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [rf, const SizedBox(height: 10), bf]),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const DRow(header: true, flex: [4, 1, 2, 2, 2, 2, 3], cells: ['Locataire', 'Chambre', 'Loyer', 'Payé', 'Statut', 'Justificatif', 'Action']),
                for (final v in list)
                  DRow(
                    flex: const [4, 1, 2, 2, 2, 2, 3],
                    cells: [
                      Tap(
                        onTap: () => s.openTenant(v.t.id),
                        child: PersonCell(v, sub: v.detail),
                      ),
                      v.t.room,
                      v.t.rentF,
                      v.paidF,
                      badgeOf(v),
                      v.method,
                      Wrap(spacing: 6, children: actions(v)),
                    ],
                  ),
                if (list.isEmpty) empty,
              ],
            ),
          ),
        ],
      );
    }

    return LPage(
      wide: false,
      gap: 16,
      children: [
        LHeader('Loyers', onBack: s.fromMore ? () => s.go('more') : null),
        month,
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Payé',
                      style: ts(13, w: FontWeight.w600, c: p.text2),
                    ),
                  ),
                  Text(
                    'sur ${fmt(s.rExpected)}',
                    style: ts(13, w: FontWeight.w500, c: p.text2),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                fmt(s.rPaid),
                style: ts(32, w: FontWeight.w700, c: p.accent, ls: -0.3),
              ),
              const SizedBox(height: 10),
              Progress(pct),
              const SizedBox(height: 8),
              Text(
                'Reste à payer : ${fmt(s.rExpected - s.rPaid)}',
                style: ts(13, w: FontWeight.w600, c: p.m700),
              ),
            ],
          ),
        ),
        ?proofBox,
        rf,
        bf,
        if (list.isEmpty) empty,
        for (final v in list)
          AppCard(
            child: Column(
              children: [
                Tap(
                  onTap: () => s.openTenant(v.t.id),
                  child: Row(
                    children: [
                      Expanded(child: PersonCell(v, sub: '${v.t.room} · ${v.detail}')),
                      badgeOf(v),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Hr(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: v.paidF,
                              style: ts(16, w: FontWeight.w700, c: p.text),
                            ),
                            TextSpan(
                              text: '  sur ${v.t.rentF}',
                              style: ts(13, w: FontWeight.w500, c: p.text2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...actions(v),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────── Plus ─────────────────────────────

class MoreScreen extends StatelessWidget {
  const MoreScreen(this.c, {super.key});
  final LCtx c;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    Widget item(IconData ic, String l, VoidCallback onTap) => Tap(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Ph(ic, color: p.text2),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l,
                style: ts(16, w: FontWeight.w600, c: p.text),
              ),
            ),
            Ph(PI.caretRight, color: p.text2),
          ],
        ),
      ),
    );
    return LPage(
      wide: false,
      children: [
        const ScreenTitle('Plus'),
        AppCard(
          child: Row(
            children: [
              const Avatar('DA', size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daniel A.',
                      style: ts(18, w: FontWeight.w700, c: p.text),
                    ),
                    Text(
                      'Propriétaire · 3 immeubles',
                      style: ts(14, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Separated(
            indent: 38,
            children: [
              item(PI.money, 'Loyers et paiements', () => s.go('rents', more: true)),
              item(PI.megaphone, 'Annonces', () => s.go('ann')),
              item(PI.hardHat, 'Techniciens', () => s.go('techs')),
              item(PI.gear, 'Profil et paramètres', () => s.go('settings')),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Annonces ─────────────────────────────

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen(this.c, {super.key});
  final LCtx c;
  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final title = TextEditingController();
  final body = TextEditingController();
  bool err = false;

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = widget.c;
    final s = c.s;
    final form = AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            c.wide ? 'Rédiger une annonce' : 'Nouvelle annonce',
            style: ts(18, w: FontWeight.w700, c: p.text),
          ),
          const SizedBox(height: 16),
          Text(
            'Destinataires',
            style: ts(13, w: FontWeight.w600, c: p.text),
          ),
          const SizedBox(height: 8),
          ChipRow(
            wrap: true,
            children: [
              for (final t in const [('all', 'Toute la cité'), ('A', 'Immeuble A'), ('B', 'Immeuble B'), ('C', 'Immeuble C')])
                ChoiceChipX(t.$2, selected: s.annTarget == t.$1, onTap: () => s.set(() => s.annTarget = t.$1)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Type',
            style: ts(13, w: FontWeight.w600, c: p.text),
          ),
          const SizedBox(height: 8),
          ChipRow(
            wrap: true,
            children: [
              for (final t in annTypes)
                ChoiceChipX(
                  t.$2,
                  icon: t.$3,
                  selected: s.annType == t.$1,
                  onTap: () {
                    if (title.text.isEmpty && t.$1 != 'other') title.text = t.$2;
                    s.set(() => s.annType = t.$1);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppField(
            label: 'Titre',
            controller: title,
            hint: 'Ex. Coupure d’eau jeudi',
            error: err ? 'Ajoutez un titre.' : null,
            onChanged: (_) => err ? setState(() => err = false) : null,
          ),
          const SizedBox(height: 16),
          AppField(label: 'Message', controller: body, maxLines: c.wide ? 4 : 3, hint: 'Date, heure, consignes…'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Ph(PI.users, size: 18, color: p.text2),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Sera envoyée à ${s.targetCount} locataires (notification + SMS)',
                      style: ts(13, w: FontWeight.w500, c: p.text2),
                    ),
                  ),
                ],
              ),
              Btn(
                'Publier l’annonce',
                icon: PI.paperPlaneRight,
                expand: !c.wide,
                onPressed: () {
                  if (s.sendAnn(title.text, body.text)) {
                    title.clear();
                    body.clear();
                    setState(() => err = false);
                  } else {
                    setState(() => err = true);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
    final sent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Envoyées'),
        const SizedBox(height: 12),
        for (final a in s.anns) ...[
          FadeUp(
            key: ValueKey(a),
            child: AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(a.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: ts(16, w: FontWeight.w700, c: p.text),
                        ),
                        const SizedBox(height: 2),
                        Text(a.body, style: ts(14, c: p.text2, h: 1.45)),
                        const SizedBox(height: 6),
                        Text(
                          '${a.when} · ${a.target} · ${a.reads}',
                          style: ts(12, w: FontWeight.w600, c: p.text2),
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
      ],
    );
    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          const LHeader('Annonces', wide: true),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: form),
              const SizedBox(width: 24),
              Expanded(child: sent),
            ],
          ),
        ],
      );
    }
    return LPage(
      wide: false,
      children: [
        LHeader('Annonces', onBack: () => s.go('more')),
        form,
        sent,
      ],
    );
  }
}

// ───────────────────────────── Paramètres ─────────────────────────────

class LandlordSettings extends StatelessWidget {
  const LandlordSettings(this.c, {super.key});
  final LCtx c;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    const prefs = [
      ('auto', 'Relance automatique', 'SMS 3 jours après l’échéance'),
      ('j3', 'Rappel avant échéance', 'Les locataires sont prévenus 3 jours avant'),
      ('rep', 'Alertes de signalements', 'Notification à chaque nouveau signalement'),
      ('sms', 'Copie par SMS', 'Pour les alertes urgentes'),
    ];
    final profile = AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Avatar('DA', size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daniel A.',
                      style: ts(18, w: FontWeight.w700, c: p.text),
                    ),
                    Text(
                      c.wide ? 'Propriétaire · Cité Les Jardins' : '07 12 00 00 01 · daniel.a@mail.com',
                      style: ts(13, w: FontWeight.w500, c: p.text2),
                    ),
                    if (!c.wide)
                      Text(
                        'Cité Les Jardins · 3 immeubles',
                        style: ts(13, w: FontWeight.w500, c: p.text2),
                      ),
                  ],
                ),
              ),
              if (!c.wide)
                IconBtn(PI.pencilSimple, tooltip: 'Modifier', color: p.link, onPressed: () => s.toast('Modification du profil : bientôt disponible')),
            ],
          ),
          if (c.wide) ...[
            const SizedBox(height: 12),
            const InfoRow(icon: PI.phone, label: 'Téléphone', value: '07 12 00 00 01'),
            const InfoRow(icon: PI.envelope, label: 'E-mail', value: 'daniel.a@mail.com'),
            const SizedBox(height: 12),
            Btn('Modifier le profil', icon: PI.pencilSimple, kind: BtnKind.outline, onPressed: () => s.toast('Modification du profil : bientôt disponible')),
          ],
        ],
      ),
    );
    final alerts = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Rappels et alertes'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Separated(
            children: [
              for (final pr in prefs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pr.$2,
                              style: ts(15, w: FontWeight.w600, c: p.text),
                            ),
                            Text(
                              pr.$3,
                              style: ts(13, w: FontWeight.w500, c: p.text2),
                            ),
                          ],
                        ),
                      ),
                      SwitchX(value: s.bp[pr.$1]!, onChanged: (_) => s.set(() => s.bp[pr.$1] = !s.bp[pr.$1]!)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final appearance = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Apparence'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Separated(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Ph(PI.moon, color: p.text2),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Mode sombre',
                        style: ts(15, w: FontWeight.w600, c: p.text),
                      ),
                    ),
                    SwitchX(value: isDarkMode, onChanged: setDarkMode),
                  ],
                ),
              ),
              if (c.wide)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Ph(PI.globe, color: p.text2),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Langue',
                          style: ts(15, w: FontWeight.w600, c: p.text),
                        ),
                      ),
                      Text(
                        'Français',
                        style: ts(14, w: FontWeight.w500, c: p.text2),
                      ),
                    ],
                  ),
                ),
              Tap(
                onTap: () => goRoot(context, Routes.auth, args: 'login'),
                scale: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Ph(PI.signOut, color: p.m700),
                      const SizedBox(width: 14),
                      Text(
                        'Se déconnecter',
                        style: ts(15, w: FontWeight.w600, c: p.m700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          const LHeader('Profil et paramètres', wide: true),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 380, child: profile),
              const SizedBox(width: 24),
              Expanded(child: Column(children: [alerts, const SizedBox(height: 24), appearance])),
            ],
          ),
        ],
      );
    }
    return LPage(
      wide: false,
      children: [
        LHeader('Profil et paramètres', onBack: () => s.go('more')),
        profile,
        alerts,
        appearance,
      ],
    );
  }
}
