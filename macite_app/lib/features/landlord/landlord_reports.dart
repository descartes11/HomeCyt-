import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/ui.dart';
import 'landlord_screens.dart';
import 'landlord_store.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen(this.c, {super.key});
  final LCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    const cols = [('new', 'Nouveau'), ('doing', 'En cours'), ('done', 'Résolu')];

    if (c.wide) {
      return LPage(
        wide: true,
        max: 1400,
        children: [
          LHeader('Signalements', wide: true, sub: '${s.pending.length} en attente · dont ${s.urgentCount} urgents'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cols.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      final items = s.reports.where((r) => r.st == cols[i].$1).toList();
                      final st = repStatus[cols[i].$1]!;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: p.chip.withValues(alpha: 0.6), borderRadius: AppRadius.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                              child: Row(
                                children: [
                                  Ph(st.$3, size: 20, color: p.strong),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cols[i].$2,
                                      style: ts(16, w: FontWeight.w700, c: p.text),
                                    ),
                                  ),
                                  StatusBadge('${items.length}', tone: st.$2),
                                ],
                              ),
                            ),
                            for (var j = 0; j < items.length; j++) ...[
                              FadeUp(
                                delay: Duration(milliseconds: j * 50),
                                child: ReportCard(items[j], photo: true, showStatus: false, onTap: () => s.openReport(items[j].id)),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Aucun signalement',
                                  textAlign: TextAlign.center,
                                  style: ts(14, c: p.text2),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    final items = s.reports.where((r) => r.st == s.rTab).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 12), child: ScreenTitle('Signalements')),
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.divider)),
          ),
          child: Row(
            children: [
              for (final t in cols)
                Expanded(
                  child: Tap(
                    onTap: () => s.set(() => s.rTab = t.$1),
                    scale: 1,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 44,
                          child: Center(
                            child: Text(
                              '${t.$2} (${s.reports.where((r) => r.st == t.$1).length})',
                              style: ts(14, w: s.rTab == t.$1 ? FontWeight.w700 : FontWeight.w500, c: s.rTab == t.$1 ? p.a800 : p.text2),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: kEase,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: s.rTab == t.$1 ? p.btn : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ScreenSwitcher(
            child: ListView(
              key: ValueKey(s.rTab),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (items.isEmpty)
                  const EmptyState(
                    icon: PI.tray,
                    title: 'Aucun signalement pour le moment',
                    text: 'Les problèmes déclarés par vos locataires apparaîtront ici.',
                  ),
                for (var i = 0; i < items.length; i++)
                  FadeUp(
                    delay: Duration(milliseconds: i * 40),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: const EdgeInsets.all(10),
                        onTap: () => s.openReport(items[i].id),
                        child: Row(
                          children: [
                            const ImageSlot('Photo', width: 76, height: 76, compact: true, icon: PI.camera),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatusBadge(urgStyle[items[i].u]!.$1, icon: urgStyle[items[i].u]!.$3, tone: urgStyle[items[i].u]!.$2),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Ph(catStyle[items[i].cat]!.$1, size: 18, color: p.text),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          items[i].title,
                                          overflow: TextOverflow.ellipsis,
                                          style: ts(15, w: FontWeight.w700, c: p.text),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${items[i].cat} · ${items[i].room} · ${items[i].when}',
                                    overflow: TextOverflow.ellipsis,
                                    style: ts(13, w: FontWeight.w500, c: p.text2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ReportDetail extends StatefulWidget {
  const ReportDetail(this.c, {super.key, required this.chat});
  final LCtx c;
  final TextEditingController chat;
  @override
  State<ReportDetail> createState() => _ReportDetailState();
}

class _ReportDetailState extends State<ReportDetail> with WidgetsBindingObserver {
  final scroll = ScrollController();
  int _count = 0;
  double _keyboard = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scroll.dispose();
    super.dispose();
  }

  /// Le clavier s'ouvre : on garde le dernier message visible au-dessus du champ.
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final kb = View.of(context).viewInsets.bottom;
    final opening = kb > _keyboard;
    _keyboard = kb;
    if (opening) _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scroll.hasClients) {
      scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: kEase);
    }
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = widget.c;
    final s = c.s;
    final r = s.rep;
    if (r.msgs.length != _count) {
      if (_count != 0) _toBottom();
      _count = r.msgs.length;
    }
    final u = urgStyle[r.u]!;
    final cs = catStyle[r.cat]!;
    final st = repStatus[r.st]!;

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            StatusBadge(u.$1, icon: u.$3, tone: u.$2),
            StatusBadge(r.cat, icon: cs.$1, tone: cs.$2),
            if (c.wide) StatusBadge(st.$1, icon: st.$3, tone: st.$2),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          r.title,
          style: ts(c.wide ? 28 : 24, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 4),
        Text(
          '${r.room} · ${r.tenantName} · ${r.date}',
          style: ts(14, w: FontWeight.w500, c: p.text2),
        ),
        const SizedBox(height: 12),
        Text(r.desc, style: ts(16, c: p.text, h: 1.5)),
      ],
    );
    final photos = SizedBox(
      height: c.wide ? 160 : 120,
      child: const Row(
        children: [
          Expanded(child: ImageSlot('Photo 1', icon: PI.camera)),
          SizedBox(width: 10),
          Expanded(child: ImageSlot('Photo 2', icon: PI.camera)),
        ],
      ),
    );
    final statusPick = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Statut',
          style: ts(16, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (_) {
            Widget b(String k) => Btn(
              repStatus[k]!.$1,
              icon: repStatus[k]!.$3,
              kind: r.st == k ? BtnKind.primary : BtnKind.outline,
              height: 44,
              fontSize: 14,
              padding: 10,
              expand: true,
              onPressed: () => s.setRepStatus(k),
            );
            const keys = ['new', 'doing', 'done'];
            if (c.wide) {
              return Column(
                children: [for (final k in keys) Padding(padding: const EdgeInsets.only(bottom: 8), child: b(k))],
              );
            }
            return Row(
              children: [
                for (final k in keys) ...[if (k != 'new') const SizedBox(width: 8), Expanded(child: b(k))],
              ],
            );
          },
        ),
      ],
    );
    final techPick = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          c.wide ? 'Assigner à un technicien' : 'Technicien',
          style: ts(16, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 10),
        ChipRow(
          wrap: true,
          children: [
            for (final t in techs)
              ChoiceChipX(
                t,
                icon: (r.tech.isEmpty ? 'Non assigné' : r.tech) == t ? PI.check : PI.user,
                selected: (r.tech.isEmpty ? 'Non assigné' : r.tech) == t,
                onTap: () => s.setTech(t),
              ),
          ],
        ),
      ],
    );
    final msgs = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < r.msgs.length; i++)
          FadeUp(
            key: ValueKey('${r.id}-$i'),
            child: _Bubble(m: r.msgs[i], who: r.msgs[i].me ? 'Vous' : r.tenantName),
          ),
      ],
    );

    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          Breadcrumb(backLabel: 'Signalements', onBack: () => s.go('reports'), current: r.title),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [head, const SizedBox(height: 16), photos]),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Discussion avec ${r.tenantName}',
                            style: ts(18, w: FontWeight.w600, c: p.text),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 320),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: p.bg, borderRadius: AppRadius.r),
                            child: SingleChildScrollView(controller: scroll, child: msgs),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: p.card,
                                    borderRadius: AppRadius.r,
                                    border: Border.all(color: p.line),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: TextField(
                                    controller: widget.chat,
                                    onSubmitted: (_) => _send(),
                                    style: ts(15, c: p.text),
                                    decoration: InputDecoration.collapsed(
                                      hintText: 'Écrire au locataire…',
                                      hintStyle: ts(15, c: p.text2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Btn('Envoyer', icon: PI.paperPlaneRight, onPressed: _send),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    AppCard(padding: const EdgeInsets.all(20), child: statusPick),
                    const SizedBox(height: 16),
                    AppCard(padding: const EdgeInsets.all(20), child: techPick),
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
        DetailBar(title: 'Signalement', onBack: () => s.go('reports')),
        Expanded(
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeUp(child: head),
                const SizedBox(height: 16),
                photos,
                const SizedBox(height: 20),
                statusPick,
                const SizedBox(height: 20),
                techPick,
                const SizedBox(height: 24),
                Text(
                  'Discussion avec le locataire',
                  style: ts(16, w: FontWeight.w700, c: p.text),
                ),
                const SizedBox(height: 12),
                msgs,
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _send() {
    widget.c.s.sendChat(widget.chat.text);
    widget.chat.clear();
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m, required this.who});
  final Msg m;
  final String who;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Align(
      alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: m.me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: m.me ? p.btn : p.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(m.me ? 16 : 4),
                    bottomRight: Radius.circular(m.me ? 4 : 16),
                  ),
                ),
                child: Text(m.text, style: ts(15, c: m.me ? p.onBtn : p.text, h: 1.4)),
              ),
              const SizedBox(height: 4),
              Text(
                '$who · ${m.time}',
                style: ts(12, w: FontWeight.w500, c: p.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
