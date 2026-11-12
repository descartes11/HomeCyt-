import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/fields.dart';
import '../../widgets/ui.dart';
import 'tenant_store.dart';

class TenantCtx {
  const TenantCtx(this.s, this.openPay, this.wide);
  final TenantStore s;
  final VoidCallback openPay;
  final bool wide;
}

Widget tenantScreen(TenantCtx c) => switch (c.s.screen) {
  'report' => _Report(c),
  'payments' => _Payments(c),
  'myreports' => _MyReports(c),
  'city' => _MyCity(c),
  'profile' => _Profile(c),
  'notifs' => _Notifs(c),
  'settings' => _Settings(c),
  _ => _Home(c),
};

/// Défilement + marges d'écran (16 mobile, 32 ordinateur).
class _Page extends StatelessWidget {
  const _Page({required this.wide, required this.children, this.max = 1120, this.gap = 24});
  final bool wide;
  final List<Widget> children;
  final double max;
  final double gap;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: wide ? const EdgeInsets.fromLTRB(32, 28, 32, 48) : const EdgeInsets.fromLTRB(16, 12, 16, 32),
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

// ───────────────────────────── Accueil ─────────────────────────────

class _Home extends StatelessWidget {
  const _Home(this.c);
  final TenantCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final r = s.rentStatus;

    final rentCard = AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prochain loyer',
                  style: ts(13, w: FontWeight.w600, c: p.text2),
                ),
              ),
              StatusBadge(r.label, icon: r.icon, tone: r.tone),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '45 000 FCFA',
            style: ts(32, w: FontWeight.w700, c: p.accent, h: 1.1, ls: -0.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Ph(PI.calendarBlank, size: 18, color: p.text2),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.due,
                  style: ts(14, w: FontWeight.w500, c: p.text2),
                ),
              ),
            ],
          ),
          if (r.unpaid || c.wide) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (r.unpaid) Btn('Envoyer un justificatif', icon: PI.uploadSimple, height: c.wide ? 48 : 52, expand: !c.wide, onPressed: c.openPay),
                if (c.wide) Btn('Historique', kind: BtnKind.outline, onPressed: () => s.go('payments')),
              ],
            ),
          ],
        ],
      ),
    );

    final roomCard = AppCard(
      padding: EdgeInsets.zero,
      onTap: () => s.go('city'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageSlot('Photo de la chambre', height: c.wide ? 120 : 112, icon: PI.bed),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ma chambre',
                        style: ts(13, w: FontWeight.w600, c: p.text2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chambre A-102',
                        style: ts(20, w: FontWeight.w700, c: p.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Immeuble A · Les Lauriers · 1er étage',
                        style: ts(13, w: FontWeight.w500, c: p.text2),
                      ),
                    ],
                  ),
                ),
                if (!c.wide) Ph(PI.caretRight, color: p.text2),
              ],
            ),
          ),
        ],
      ),
    );

    final reportCta = Tap(
      onTap: s.startReport,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: p.chip, borderRadius: AppRadius.r),
        child: Row(
          children: [
            IconTile(PI.megaphone, size: 48, bg: p.strong, fg: p.card),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.wide ? 'Un souci dans votre chambre ?' : 'Déclarer un problème',
                    style: ts(17, w: FontWeight.w700, c: p.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.wide ? 'Fuite, panne, serrure… Déclarez-le en moins de 30 secondes.' : 'Fuite, panne, serrure… en 3 étapes',
                    style: ts(13, w: FontWeight.w500, c: p.strong),
                  ),
                  if (c.wide) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Déclarer un problème',
                            style: ts(15, w: FontWeight.w700, c: p.link),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Ph(PI.arrowRight, size: 18, color: p.link),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!c.wide) Ph(PI.arrowRight, color: p.strong),
          ],
        ),
      ),
    );

    final ann = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(c.wide ? 'Dernières annonces de la cité' : 'Annonces de la cité', action: 'Voir tout', onAction: () => s.go('city')),
        const SizedBox(height: 8),
        if (c.wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tenantAnnouncements.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: _AnnCard(tenantAnnouncements[i], vertical: true)),
              ],
            ],
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Separated(children: [for (final a in tenantAnnouncements) _AnnCard(a, flat: true)]),
          ),
      ],
    );

    if (c.wide) {
      return _Page(
        wide: true,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cité Les Jardins · mercredi 4 novembre',
                      style: ts(14, w: FontWeight.w500, c: p.text2),
                    ),
                    const SizedBox(height: 2),
                    const ScreenTitle('Bonjour, Sarah', size: 32),
                  ],
                ),
              ),
              Btn('Déclarer un problème', icon: PI.megaphone, onPressed: s.startReport),
            ],
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: roomCard),
                const SizedBox(width: 16),
                Expanded(child: rentCard),
                const SizedBox(width: 16),
                Expanded(child: reportCta),
              ],
            ),
          ),
          ann,
        ],
      );
    }

    return _Page(
      wide: false,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cité Les Jardins',
                    style: ts(13, w: FontWeight.w500, c: p.text2),
                  ),
                  const SizedBox(height: 2),
                  const ScreenTitle('Bonjour, Sarah'),
                ],
              ),
            ),
            IconBtn(PI.bell, filled: true, dot: s.unread > 0, tooltip: 'Notifications', onPressed: () => s.go('notifs')),
          ],
        ),
        roomCard,
        rentCard,
        reportCta,
        ann,
      ],
    );
  }
}

class _AnnCard extends StatelessWidget {
  const _AnnCard(this.a, {this.vertical = false, this.flat = false});
  final Announcement a;
  final bool vertical, flat;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          a.title,
          style: ts(16, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 4),
        Text(a.body, style: ts(14, c: p.text2, h: 1.45)),
        const SizedBox(height: 6),
        Text(
          a.when,
          style: ts(12, w: FontWeight.w600, c: p.text2),
        ),
      ],
    );
    if (vertical) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconTile(a.icon), const SizedBox(height: 12), text]),
      );
    }
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: flat ? 12 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(a.icon),
          const SizedBox(width: 12),
          Expanded(child: text),
        ],
      ),
    );
    return flat ? row : AppCard(child: row);
  }
}

// ───────────────────────────── Signalement ─────────────────────────────

class _Report extends StatelessWidget {
  const _Report(this.c);
  final TenantCtx c;

  @override
  Widget build(BuildContext context) {
    final s = c.s;
    final p = context.pal;
    final inForm = s.step < 4;
    final body = switch (s.step) {
      1 => _step1(context),
      2 => _ReportStep2(s),
      3 => _step3(context),
      _ => _success(context),
    };

    if (c.wide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 48),
        child: MaxWidth(
          max: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inForm) ...[
                Row(
                  children: [
                    Transform.translate(
                      offset: const Offset(-12, 0),
                      child: LinkButton(s.step == 1 ? 'Annuler' : 'Étape précédente', icon: PI.arrowLeft, color: p.text2, onPressed: s.stepBack),
                    ),
                    const Spacer(),
                    Text(
                      'Étape ${s.step} sur 3',
                      style: ts(13, w: FontWeight.w600, c: p.text2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StepBar(s.step),
                const SizedBox(height: 28),
              ],
              AppCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeUp(key: ValueKey(s.step), child: body),
                    if (s.step == 2 || s.step == 3) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Btn(s.step == 3 ? (s.sending ? 'Envoi…' : 'Envoyer le signalement') : 'Continuer', busy: s.sending, onPressed: s.next),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (inForm) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
            child: Row(
              children: [
                IconBtn(s.step == 1 ? PI.x : PI.arrowLeft, tooltip: 'Retour', onPressed: s.stepBack),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Déclarer un problème',
                    style: ts(18, w: FontWeight.w600, c: p.text),
                  ),
                ),
                Text(
                  'Étape ${s.step} sur 3',
                  style: ts(13, w: FontWeight.w600, c: p.text2),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: StepBar(s.step)),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: FadeUp(key: ValueKey(s.step), child: body),
          ),
        ),
      ],
    );
  }

  Widget _step1(BuildContext context) {
    final s = c.s;
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quel est le problème ?',
                style: ts(c.wide ? 26 : 24, w: FontWeight.w700, c: p.text),
              ),
            ),
            if (!c.wide) LinkButton('Mes signalements', icon: PI.listBullets, onPressed: () => s.go('myreports')),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth > 560 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cols == 4 ? 1.05 : 1.25,
              children: [
                for (var i = 0; i < cats.length; i++)
                  PopIn(
                    delay: Duration(milliseconds: i * 40),
                    child: _CatTile(cat: cats[i], selected: s.cat == cats[i].key, onTap: () => s.pickCat(cats[i].key)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _step3(BuildContext context) {
    final s = c.s;
    final p = context.pal;
    final cat = s.selCat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Est-ce urgent ?',
          style: ts(c.wide ? 26 : 24, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 20),
        if (c.wide)
          Row(
            children: [
              for (var i = 0; i < urgencies.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _UrgTile(u: urgencies[i], selected: s.urg == urgencies[i].key, onTap: () => s.setUrg(urgencies[i].key)),
                ),
              ],
            ],
          )
        else
          for (final u in urgencies) ...[
            SelectCard(icon: u.icon, title: u.label, subtitle: u.hint, tone: u.tone, selected: s.urg == u.key, onTap: () => s.setUrg(u.key)),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.wide ? p.bg : p.card, borderRadius: AppRadius.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker('Récapitulatif', color: p.text2),
              const SizedBox(height: 10),
              Row(
                children: [
                  Ph(cat.icon, size: 20, color: p.text),
                  const SizedBox(width: 8),
                  Text(
                    '${cat.label} · Chambre A-102',
                    style: ts(15, w: FontWeight.w700, c: p.text),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(s.desc, style: ts(14, c: p.text2, h: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _success(BuildContext context) {
    final s = c.s;
    final p = context.pal;
    final steps = [('Envoyé', true), ('Pris en charge', false), ('Résolu', false)];
    return Padding(
      padding: EdgeInsets.only(top: c.wide ? 8 : 32),
      child: Column(
        children: [
          const PopIn(child: IconTile(PI.checkCircle, size: 96, iconSize: 52, tone: Tone.paid)),
          const SizedBox(height: 24),
          Text(
            'Signalement envoyé',
            textAlign: TextAlign.center,
            style: ts(28, w: FontWeight.w700, c: p.text),
          ),
          const SizedBox(height: 10),
          Text(
            'Votre bailleur a été prévenu. Vous serez notifié dès qu’il prend en charge le problème.',
            textAlign: TextAlign.center,
            style: ts(16, c: p.text2, h: 1.5),
          ),
          const SizedBox(height: 12),
          StatusBadge('Référence SIG-0142 · ${s.selCat.label} · ${s.selUrg.label}', tone: Tone.neutral, height: 30, fontSize: 13),
          const SizedBox(height: 28),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) Expanded(child: Container(height: 2, color: i == 1 ? p.btn : p.faint)),
                FadeUp(
                  delay: Duration(milliseconds: 200 + i * 150),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: steps[i].$2 ? p.btn : p.chip, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: steps[i].$2
                            ? Ph(PI.check, size: 20, color: p.onBtn)
                            : Text(
                                '${i + 1}',
                                style: ts(14, w: FontWeight.w700, c: p.text2),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i].$1,
                        style: ts(12, w: FontWeight.w600, c: steps[i].$2 ? p.text : p.text2),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          if (c.wide)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Btn('Suivre mon signalement', onPressed: () => s.go('myreports')),
                const SizedBox(width: 12),
                Btn('Retour à l’accueil', kind: BtnKind.outline, onPressed: () => s.go('home')),
              ],
            )
          else ...[
            Btn('Retour à l’accueil', height: 56, expand: true, onPressed: () => s.go('home')),
            const SizedBox(height: 12),
            Btn('Suivre mon signalement', kind: BtnKind.outline, height: 56, expand: true, onPressed: () => s.go('myreports')),
          ],
        ],
      ),
    );
  }
}

class _CatTile extends StatelessWidget {
  const _CatTile({required this.cat, required this.selected, required this.onTap});
  final Cat cat;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Tap(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? p.a100 : p.card,
          borderRadius: AppRadius.r,
          border: Border.all(color: selected ? p.btn : p.line, width: selected ? 2 : 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTile(cat.icon, size: 52, iconSize: 28, tone: cat.tone),
            const SizedBox(height: 10),
            Text(
              cat.label,
              textAlign: TextAlign.center,
              style: ts(15, w: FontWeight.w600, c: p.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgTile extends StatelessWidget {
  const _UrgTile({required this.u, required this.selected, required this.onTap});
  final Urg u;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Tap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? p.a100 : p.card,
          borderRadius: AppRadius.r,
          border: Border.all(color: selected ? p.btn : p.line, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(u.icon, tone: u.tone),
                const Spacer(),
                Ph(selected ? PI.radioButton : PI.circle, color: selected ? p.btn : p.text2),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              u.label,
              style: ts(16, w: FontWeight.w700, c: p.text),
            ),
            const SizedBox(height: 2),
            Text(
              u.hint,
              style: ts(13, w: FontWeight.w500, c: p.text2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStep2 extends StatefulWidget {
  const _ReportStep2(this.s);
  final TenantStore s;
  @override
  State<_ReportStep2> createState() => _ReportStep2State();
}

class _ReportStep2State extends State<_ReportStep2> {
  late final ctrl = TextEditingController(text: widget.s.desc);
  int photos = 0;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final p = context.pal;
    final cat = s.selCat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusBadge(cat.label, icon: cat.icon, tone: cat.tone, height: 30, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Text(
          'Décrivez le problème',
          style: ts(context.isWide ? 26 : 24, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 20),
        AppField(
          label: 'Que se passe-t-il ?',
          controller: ctrl,
          maxLines: 4,
          hint: 'Ex. : l’eau coule sous l’évier depuis ce matin',
          onChanged: s.setDesc,
          error: s.descError ? 'Ajoutez quelques mots pour aider votre bailleur.' : null,
        ),
        const SizedBox(height: 20),
        Text(
          'Photos (facultatif)',
          style: ts(13, w: FontWeight.w600, c: p.text),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: Row(
            children: [
              for (var i = 0; i < 2; i++) ...[
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: i < photos
                        ? ImageSlot('Photo ${i + 1}', key: ValueKey('ph$i'), icon: PI.image)
                        : Container(
                            key: ValueKey('e$i'),
                            decoration: BoxDecoration(color: p.chip.withValues(alpha: 0.5), borderRadius: AppRadius.r),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Tap(
                  onTap: () {
                    if (photos < 2) {
                      setState(() => photos++);
                    } else {
                      showToast(context, '2 photos maximum');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: AppRadius.r,
                      border: Border.all(color: p.outline),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Ph(context.isWide ? PI.image : PI.camera, color: p.link),
                        const SizedBox(height: 4),
                        Text(
                          'Ajouter',
                          style: ts(14, w: FontWeight.w600, c: p.link),
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
    );
  }
}

// ───────────────────────────── Paiements ─────────────────────────────

class _Payments extends StatelessWidget {
  const _Payments(this.c);
  final TenantCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final r = s.rentStatus;
    final balance = AppCard(
      padding: const EdgeInsets.all(20),
      color: c.wide ? null : p.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde restant',
            style: ts(13, w: FontWeight.w600, c: p.text2),
          ),
          const SizedBox(height: 6),
          Text(
            r.balance,
            style: ts(32, w: FontWeight.w700, c: p.accent, ls: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            r.due,
            style: ts(14, w: FontWeight.w500, c: p.text2),
          ),
          if (r.unpaid) ...[const SizedBox(height: 16), Btn('Envoyer un justificatif', icon: PI.uploadSimple, expand: !c.wide, onPressed: c.openPay)],
        ],
      ),
    );

    if (c.wide) {
      Widget stat(String l, String v, Widget foot) => AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l,
              style: ts(13, w: FontWeight.w600, c: p.text2),
            ),
            const SizedBox(height: 6),
            Text(
              v,
              style: ts(28, w: FontWeight.w700, c: p.text),
            ),
            const SizedBox(height: 6),
            foot,
          ],
        ),
      );
      return _Page(
        wide: true,
        children: [
          const ScreenTitle('Mes paiements', size: 32),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: balance),
                const SizedBox(width: 16),
                Expanded(
                  child: stat(
                    'Payé en 2026',
                    s.paidYear,
                    Row(
                      children: [
                        Ph(PI.checkCircle, size: 18, color: p.a800),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Aucun retard cette année',
                            style: ts(14, w: FontWeight.w600, c: p.a800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: stat('Loyer mensuel', '45 000 FCFA', Text('Échéance le 5 de chaque mois', style: ts(14, c: p.text2))),
                ),
              ],
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Historique des loyers',
                    style: ts(20, w: FontWeight.w600, c: p.text),
                  ),
                ),
                _TableRow(header: true, cells: const ['Mois', 'Montant', 'Payé le', 'Justificatif', 'Statut', 'Quittance'], flex: const [3, 2, 2, 2, 2, 2]),
                for (final h in payHistory)
                  _TableRow(
                    flex: const [3, 2, 2, 2, 2, 2],
                    cells: [
                      h.$1,
                      '45 000 FCFA',
                      h.$2,
                      h.$3,
                      const StatusBadge('Payé', icon: PI.checkCircle, tone: Tone.paid),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: LinkButton('PDF', icon: PI.downloadSimple, onPressed: () => s.receipt(h.$1, h.$2)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return _Page(
      wide: false,
      children: [
        const ScreenTitle('Mes paiements'),
        balance,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Historique'),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Separated(
                children: [
                  for (final h in payHistory)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const IconTile(PI.checkCircle, tone: Tone.paid),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.$1,
                                  style: ts(15, w: FontWeight.w700, c: p.text),
                                ),
                                Text(
                                  'Payé le ${h.$2} · ${h.$3}',
                                  style: ts(13, w: FontWeight.w500, c: p.text2),
                                ),
                              ],
                            ),
                          ),
                          IconBtn(PI.downloadSimple, tooltip: 'Télécharger la quittance', color: p.link, onPressed: () => s.receipt(h.$1, h.$2)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ligne de tableau (écrans « ordinateur »).
class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells, required this.flex, this.header = false});
  final List<Object> cells;
  final List<int> flex;
  final bool header;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      constraints: BoxConstraints(minHeight: header ? 40 : 56),
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
                      style: header
                          ? ts(12, w: FontWeight.w700, c: p.text2, ls: 0.4)
                          : ts(14, w: i == 0 ? FontWeight.w600 : FontWeight.w500, c: i == 0 ? p.text : p.strong),
                    ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Mes signalements ─────────────────────────────

class _MyReports extends StatelessWidget {
  const _MyReports(this.c);
  final TenantCtx c;
  @override
  Widget build(BuildContext context) {
    final s = c.s;
    final header = Row(
      children: [
        if (!c.wide)
          Transform.translate(
            offset: const Offset(-12, 0),
            child: IconBtn(PI.arrowLeft, tooltip: 'Retour', onPressed: s.startReport),
          ),
        Expanded(child: ScreenTitle('Mes signalements', size: c.wide ? 32 : 28)),
        StatusBadge('${s.openReports} en cours', tone: Tone.neutral),
        if (c.wide) ...[const SizedBox(width: 16), Btn('Déclarer un problème', icon: PI.plus, onPressed: s.startReport)],
      ],
    );
    final cards = [for (final m in s.myReports) _MyReportCard(m: m, s: s)];
    if (c.wide) {
      return _Page(
        wide: true,
        children: [
          header,
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 32) / 3;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [for (final cd in cards) SizedBox(width: w, child: cd)],
              );
            },
          ),
        ],
      );
    }
    return _Page(wide: false, gap: 16, children: [header, ...cards]);
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({required this.m, required this.s});
  final MyReport m;
  final TenantStore s;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const labels = ['Envoyé', 'Pris en charge', 'Résolu'];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(m.icon, tone: m.tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: ts(16, w: FontWeight.w700, c: p.text),
                    ),
                    Text(
                      '${m.cat} · ${m.date}',
                      style: ts(13, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(labels[m.step - 1], tone: m.step == 3 ? Tone.paid : Tone.neutral),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(color: i < m.step ? p.btn : p.faint, borderRadius: AppRadius.r),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: ts(12, w: i < m.step ? FontWeight.w600 : FontWeight.w500, c: i < m.step ? p.text : p.text2),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(m.note, style: ts(14, c: p.text2, h: 1.45)),
          if (m.step == 3) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              decoration: BoxDecoration(color: p.bg, borderRadius: AppRadius.r),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      m.rated > 0 ? 'Merci ! Votre note : ${m.rated}/5' : 'Notez la résolution',
                      style: ts(14, w: FontWeight.w600, c: p.text),
                    ),
                  ),
                  for (var i = 1; i <= 5; i++)
                    Tap(
                      onTap: () => s.rate(m, i),
                      scale: 0.85,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: i <= m.rated
                            ? Icon(PIFill.star, size: 24, color: p.strong)
                            : Ph(PI.star, size: 24, color: p.dark ? AppColors.n500 : AppColors.n600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Ma cité ─────────────────────────────

class _MyCity extends StatelessWidget {
  const _MyCity(this.c);
  final TenantCtx c;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final building = AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageSlot('Photo de l’immeuble', height: c.wide ? 180 : 140, icon: PI.buildings),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Immeuble A · Les Lauriers',
                  style: ts(20, w: FontWeight.w700, c: p.text),
                ),
                const SizedBox(height: 10),
                for (final l in [
                  (PI.mapPin, 'Rue 12, quartier Centre'),
                  (PI.buildings, c.wide ? '3 étages · 18 chambres' : '3 étages · 18 chambres · Cité Les Jardins'),
                  (PI.wifiHigh, 'Wi-Fi : Jardins-A · code à l’accueil'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Ph(l.$1, size: 18, color: p.text2),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.$2,
                            style: ts(14, w: FontWeight.w500, c: p.strong),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final contactsCard = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Contacts utiles'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Separated(
            children: [
              for (final ct in contacts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Avatar(ct.$3, tone: ct.$4),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ct.$1,
                              style: ts(15, w: FontWeight.w700, c: p.text),
                            ),
                            Text(
                              c.wide ? '${ct.$2} · ${ct.$5}' : ct.$2,
                              style: ts(13, w: FontWeight.w500, c: p.text2),
                            ),
                          ],
                        ),
                      ),
                      IconBtn(PI.phone, tooltip: 'Appeler', color: p.link, bg: p.a100, onPressed: () => s.toast('Appel vers ${ct.$1} · ${ct.$5}')),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    final rulesCard = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Règlement intérieur'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Separated(
            children: [
              for (var i = 0; i < rules.length; i++)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Tap(
                      onTap: () => s.toggleRule(i),
                      scale: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                rules[i].$1,
                                style: ts(15, w: FontWeight.w600, c: p.text),
                              ),
                            ),
                            AnimatedRotation(
                              turns: s.openRule == i ? 0.5 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: Ph(PI.caretDown, size: 20, color: p.text2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: kEase,
                      child: s.openRule == i
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text(rules[i].$2, style: ts(14, c: p.text2, h: 1.5)),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );

    final annCard = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Annonces'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Separated(children: [for (final a in tenantAnnouncements) _AnnCard(a, flat: true)]),
        ),
      ],
    );

    if (c.wide) {
      return _Page(
        wide: true,
        children: [
          const ScreenTitle('Ma cité', size: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: [building, const SizedBox(height: 24), rulesCard])),
              const SizedBox(width: 24),
              Expanded(child: Column(children: [contactsCard, const SizedBox(height: 24), annCard])),
            ],
          ),
        ],
      );
    }
    return _Page(wide: false, children: [const ScreenTitle('Ma cité'), building, contactsCard, rulesCard, annCard]);
  }
}

// ───────────────────────────── Profil ─────────────────────────────

class _Profile extends StatelessWidget {
  const _Profile(this.c);
  final TenantCtx c;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final ps = s.payStatus;
    final id = AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const ImageSlot('Photo', width: 88, height: 88, circle: true, icon: PI.user),
          const SizedBox(height: 12),
          Text(
            'Sarah M.',
            style: ts(22, w: FontWeight.w700, c: p.text),
          ),
          const SizedBox(height: 2),
          Text(
            'Chambre A-102 · Immeuble A · Les Lauriers',
            textAlign: TextAlign.center,
            style: ts(14, w: FontWeight.w500, c: p.text2),
          ),
          const SizedBox(height: 14),
          Btn('Modifier', icon: PI.pencilSimple, kind: BtnKind.outline, height: 44, onPressed: () => s.toast('Modification du profil : bientôt disponible')),
        ],
      ),
    );
    final pay = AppCard(
      onTap: () => s.go('payments'),
      child: Row(
        children: [
          IconTile(ps.icon, size: 48, tone: ps.tone),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut des paiements',
                  style: ts(13, w: FontWeight.w600, c: p.text2),
                ),
                Text(
                  ps.label,
                  style: ts(17, w: FontWeight.w700, c: p.text),
                ),
                Text(
                  ps.text,
                  style: ts(13, w: FontWeight.w500, c: p.text2),
                ),
              ],
            ),
          ),
          Ph(PI.caretRight, color: p.text2),
        ],
      ),
    );
    final lease = _Section(
      'Mon bail',
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: const Column(
          children: [KV('Date d’entrée', '1 sept. 2025'), KV('Durée du bail', '24 mois'), KV('Fin du bail', '31 août 2027'), KV('Loyer', '45 000 FCFA')],
        ),
      ),
    );
    final info = _Section(
      'Informations personnelles',
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: const Separated(
          indent: 38,
          children: [
            InfoRow(icon: PI.phone, label: 'Téléphone', value: '07 12 34 56 02'),
            InfoRow(icon: PI.envelope, label: 'E-mail', value: 'sarah.m@mail.com'),
            InfoRow(icon: PI.firstAid, label: 'Contact d’urgence', value: 'Paul M. (frère) · 07 22 11 00 99'),
          ],
        ),
      ),
    );
    final docs = _Section(
      'Documents',
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Separated(
          children: [
            _DocRow(
              PI.filePdf,
              Tone.late,
              'Contrat de bail',
              Text(
                'PDF · 240 Ko · signé le 28 août 2025',
                style: ts(13, w: FontWeight.w500, c: p.text2),
              ),
              PI.downloadSimple,
              s.lease,
            ),
            _DocRow(
              PI.identificationCard,
              Tone.neutral,
              'Pièce d’identité',
              Row(
                children: [
                  Ph(PI.sealCheck, size: 16, color: p.a800),
                  const SizedBox(width: 4),
                  Text(
                    'Vérifiée',
                    style: ts(13, w: FontWeight.w600, c: p.a800),
                  ),
                ],
              ),
              PI.eye,
              () => s.toast('Pièce d’identité ouverte'),
            ),
          ],
        ),
      ),
    );
    final header = Row(
      children: [
        Expanded(child: ScreenTitle('Mon profil', size: c.wide ? 32 : 28)),
        if (!c.wide) IconBtn(PI.gear, tooltip: 'Paramètres', filled: true, onPressed: () => s.go('settings')),
      ],
    );
    if (c.wide) {
      return _Page(
        wide: true,
        children: [
          header,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: Column(children: [id, const SizedBox(height: 16), pay])),
              const SizedBox(width: 24),
              Expanded(child: Column(children: [lease, const SizedBox(height: 24), info, const SizedBox(height: 24), docs])),
            ],
          ),
        ],
      );
    }
    return _Page(wide: false, children: [header, id, pay, lease, info, docs]);
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SectionHeader(title), const SizedBox(height: 12), child]);
}

class _DocRow extends StatelessWidget {
  const _DocRow(this.icon, this.tone, this.title, this.sub, this.action, this.onTap);
  final IconData icon, action;
  final Tone tone;
  final String title;
  final Widget sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconTile(icon, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ts(15, w: FontWeight.w700, c: p.text),
                ),
                sub,
              ],
            ),
          ),
          IconBtn(action, color: p.link, onPressed: onTap),
        ],
      ),
    );
  }
}

// ───────────────────────────── Notifications ─────────────────────────────

class _Notifs extends StatelessWidget {
  const _Notifs(this.c);
  final TenantCtx c;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    Widget group(String title, bool today) {
      final list = s.notifs.where((n) => n.today == today).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Kicker(title, color: p.text2),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Separated(
              children: [
                for (final n in list)
                  Tap(
                    onTap: () => s.openNotif(n),
                    scale: 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      color: n.unread ? p.a100.withValues(alpha: 0.6) : Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconTile(n.icon, tone: n.tone),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: ts(15, w: n.unread ? FontWeight.w700 : FontWeight.w600, c: p.text),
                                ),
                                const SizedBox(height: 2),
                                Text(n.body, style: ts(14, c: p.text2, h: 1.45)),
                                const SizedBox(height: 4),
                                Text(
                                  n.when,
                                  style: ts(12, w: FontWeight.w600, c: p.text2),
                                ),
                              ],
                            ),
                          ),
                          if (n.unread)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 6, left: 8),
                              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
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
    }

    return _Page(
      wide: c.wide,
      max: 760,
      children: [
        Row(
          children: [
            if (!c.wide)
              Transform.translate(
                offset: const Offset(-12, 0),
                child: IconBtn(PI.arrowLeft, tooltip: 'Retour', onPressed: () => s.go('home')),
              ),
            Expanded(child: ScreenTitle('Notifications', size: c.wide ? 32 : 28)),
            if (s.unread > 0) LinkButton('Tout lire', onPressed: s.markAll),
          ],
        ),
        group('Aujourd’hui', true),
        group('Cette semaine', false),
      ],
    );
  }
}

// ───────────────────────────── Paramètres ─────────────────────────────

class _Settings extends StatelessWidget {
  const _Settings(this.c);
  final TenantCtx c;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    const prefs = [
      ('rent', 'Rappels de loyer', '3 jours avant l’échéance'),
      ('reports', 'Réponses aux signalements', 'Quand le statut change'),
      ('ann', 'Annonces de la cité', 'Coupures, réunions, travaux'),
      ('sms', 'Recevoir aussi par SMS', 'Utile sans connexion internet'),
    ];
    Widget row(IconData ic, String label, {Widget? trailing, VoidCallback? onTap, Color? color}) => Tap(
      onTap: onTap,
      scale: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Ph(ic, color: color ?? p.text2),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: ts(15, w: FontWeight.w600, c: color ?? p.text),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
    return _Page(
      wide: c.wide,
      max: 760,
      children: [
        Row(
          children: [
            if (!c.wide)
              Transform.translate(
                offset: const Offset(-12, 0),
                child: IconBtn(PI.arrowLeft, tooltip: 'Retour', onPressed: () => s.go('profile')),
              ),
            Expanded(child: ScreenTitle('Paramètres', size: c.wide ? 32 : 28)),
          ],
        ),
        _Section(
          'Notifications',
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
                        SwitchX(value: s.prefs[pr.$1]!, onChanged: (_) => s.togglePref(pr.$1)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        _Section(
          'Apparence et langue',
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Separated(
              children: [
                row(
                  PI.moon,
                  'Mode sombre',
                  trailing: SwitchX(value: isDarkMode, onChanged: setDarkMode),
                ),
                row(
                  PI.globe,
                  'Langue',
                  trailing: Row(
                    children: [
                      Text(
                        'Français',
                        style: ts(14, w: FontWeight.w500, c: p.text2),
                      ),
                      const SizedBox(width: 6),
                      Ph(PI.caretRight, size: 18, color: p.text2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _Section(
          'Compte',
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Separated(
              children: [
                row(
                  PI.lockKey,
                  'Changer le mot de passe',
                  trailing: Ph(PI.caretRight, size: 18, color: p.text2),
                  onTap: () => s.toast('Un code vous a été envoyé par SMS'),
                ),
                row(
                  PI.question,
                  'Aide et contacts',
                  trailing: Ph(PI.caretRight, size: 18, color: p.text2),
                  onTap: () => s.go('city'),
                ),
                row(
                  PI.signOut,
                  'Se déconnecter',
                  color: p.m700,
                  onTap: () => goRoot(context, Routes.auth, args: 'login'),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Text(
            'MaCité · version 1.0.0',
            style: ts(13, w: FontWeight.w500, c: p.text2),
          ),
        ),
      ],
    );
  }
}
