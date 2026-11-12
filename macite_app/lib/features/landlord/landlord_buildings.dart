import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/fields.dart';
import '../../widgets/ui.dart';
import 'landlord_screens.dart';
import 'landlord_store.dart';

// ───────────────────────────── Immeubles ─────────────────────────────

class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen(this.c, {super.key});
  final LCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final cards = [
      for (final b in const ['A', 'B', 'C'])
        Builder(
          builder: (context) {
            final d = s.building(b);
            return AppCard(
              padding: EdgeInsets.zero,
              onTap: () => s.set(() {
                s.bSel = b;
                s.go('building');
              }),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ImageSlot('Photo de l’immeuble', height: c.wide ? 150 : 120, icon: PI.buildings),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: ts(18, w: FontWeight.w700, c: p.text),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Ph(PI.mapPin, size: 16, color: p.text2),
                            const SizedBox(width: 4),
                            Text(
                              d.addr,
                              style: ts(13, w: FontWeight.w500, c: p.text2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${d.rooms} chambres · ${d.floors} étages',
                                style: ts(13, w: FontWeight.w600, c: p.strong),
                              ),
                            ),
                            Text(
                              '${d.pct} % occupé',
                              style: ts(13, w: FontWeight.w700, c: p.a800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Progress(d.pct / 100),
                        const SizedBox(height: 8),
                        Text(
                          d.late > 0 ? '${d.late} loyer${d.late > 1 ? 's' : ''} en retard' : 'Aucun retard',
                          style: ts(13, w: FontWeight.w600, c: d.late > 0 ? p.m700 : p.a800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    ];
    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          LHeader(
            'Mes immeubles',
            wide: true,
            sub: 'Cité Les Jardins · 3 immeubles · 48 chambres',
            actions: [
              Btn(
                'Ajouter un immeuble',
                icon: PI.plus,
                onPressed: () => s.toast('Formulaire « Ajouter un immeuble » : même structure que celui d’une chambre'),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: cards[i])],
            ],
          ),
        ],
      );
    }
    return LPage(
      wide: false,
      gap: 16,
      bottomPad: 96,
      children: [
        const LHeader('Mes immeubles', sub: 'Cité Les Jardins · 48 chambres'),
        ...cards,
      ],
    );
  }
}

/// Tuile de chambre (plan d'étage).
class RoomTile extends StatelessWidget {
  const RoomTile(this.r, {super.key, required this.onTap, this.showLabel = false, this.delay = 0});
  final RoomInfo r;
  final VoidCallback onTap;
  final bool showLabel;
  final int delay;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final st = r.style;
    final bg = p.dark ? st.darkBg : st.bg;
    final fg = p.dark ? st.darkFg : st.fg;
    return Tooltip(
      message: '${r.id} · ${st.label}',
      child: PopIn(
        delay: Duration(milliseconds: delay),
        child: Tap(
          onTap: onTap,
          scale: 0.94,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.r,
              border: Border.all(color: st.borderOf(p.dark), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Ph(st.icon, size: 20, color: fg),
                const SizedBox(height: 4),
                Text(
                  r.id,
                  style: ts(13, w: FontWeight.w700, c: fg),
                ),
                if (showLabel)
                  Text(
                    st.label,
                    overflow: TextOverflow.ellipsis,
                    style: ts(11, w: FontWeight.w500, c: fg),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BuildingDetail extends StatelessWidget {
  const BuildingDetail(this.c, {super.key});
  final LCtx c;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final b = s.building(s.bSel);
    final rooms = s.allRooms(s.bSel);
    final legend = [
      for (final k in const ['free', 'occ', 'works', 'late'])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: p.dark ? roomStyles[k]!.darkBg : roomStyles[k]!.bg,
                  borderRadius: AppRadius.r,
                  border: Border.all(color: roomStyles[k]!.borderOf(p.dark), width: 2),
                ),
                child: Center(child: Ph(roomStyles[k]!.icon, size: 16, color: p.dark ? roomStyles[k]!.darkFg : roomStyles[k]!.fg)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  roomStyles[k]!.label,
                  style: ts(14, w: FontWeight.w500, c: p.text),
                ),
              ),
              Text(
                '${rooms.where((r) => r.st == k).length}',
                style: ts(15, w: FontWeight.w700, c: p.text),
              ),
            ],
          ),
        ),
    ];
    var n = 0;
    final plan = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in s.floors(s.bSel)) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Kicker(f.$1, color: p.text2),
          ),
          LayoutBuilder(
            builder: (context, box) {
              final cols = c.wide ? (box.maxWidth / 110).floor().clamp(4, 8) : 4;
              final w = (box.maxWidth - (cols - 1) * 8) / cols;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in f.$2)
                    SizedBox(
                      width: w,
                      child: RoomTile(r, showLabel: c.wide, delay: (n++) * 25, onTap: () => s.openRoom(r.id)),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );

    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          Breadcrumb(backLabel: 'Mes immeubles', onBack: () => s.go('buildings'), current: b.name),
          LHeader(
            b.name,
            wide: true,
            sub: '${b.addr} · ${b.rooms} chambres · ${b.pct} % occupé',
            actions: [Btn('Ajouter une chambre', icon: PI.plus, onPressed: s.addRoom)],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Plan des chambres',
                        style: ts(18, w: FontWeight.w600, c: p.text),
                      ),
                      const SizedBox(height: 12),
                      plan,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 280,
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Légende',
                        style: ts(18, w: FontWeight.w600, c: p.text),
                      ),
                      const SizedBox(height: 8),
                      ...legend,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        DetailBar(title: b.name, onBack: () => s.go('buildings')),
        Expanded(
          child: LPage(
            wide: false,
            gap: 16,
            bottomPad: 96,
            children: [
              Text(
                '${b.rooms} chambres · ${b.floors} étages · ${b.pct} % occupé',
                style: ts(14, w: FontWeight.w500, c: p.text2),
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 4.2,
                  crossAxisSpacing: 12,
                  children: legend,
                ),
              ),
              plan,
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Chambre ─────────────────────────────

class RoomDetail extends StatelessWidget {
  const RoomDetail(this.c, {super.key});
  final LCtx c;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final r = s.roomData(s.roomSel);
    final st = r.style;
    final equip = equipByType[r.type]!;
    final h1 = pool[(r.floor * 5 + 2) % pool.length], h2 = pool[(r.floor * 3 + 7) % pool.length];
    final badge = StatusBadge(
      st.label,
      icon: st.icon,
      tone: switch (r.st) {
        'free' => Tone.pale,
        'occ' => Tone.strong,
        'late' => Tone.late,
        _ => Tone.neutral,
      },
    );
    final equipWrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final e in equip) StatusBadge(e, icon: PI.check, tone: Tone.neutral, height: 30, fontSize: 13)],
    );
    void openTenant() => r.tenant != null ? s.openTenant(r.tenant!.id) : s.toast('${r.tenantName} : fiche à compléter');
    final tenantBox = r.hasTenant
        ? AppCard(
            color: p.bg,
            onTap: openTenant,
            child: Row(
              children: [
                const IconTile(PI.user, tone: Tone.strong),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.tenantName,
                        style: ts(15, w: FontWeight.w700, c: p.text),
                      ),
                      Text(
                        c.wide ? 'Voir la fiche locataire' : 'Voir la fiche',
                        style: ts(13, w: FontWeight.w600, c: p.link),
                      ),
                    ],
                  ),
                ),
                Ph(PI.caretRight, color: p.text2),
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.a100, borderRadius: AppRadius.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cette chambre est libre.',
                  style: ts(15, w: FontWeight.w600, c: p.a900),
                ),
                const SizedBox(height: 10),
                Btn(
                  'Attribuer à un locataire',
                  icon: PI.userPlus,
                  onPressed: () => s.newTenant(room: r.id),
                ),
              ],
            ),
          );
    final history = Column(
      children: [
        for (final h in [(h1, 'sept. 2024 – août 2025', '12 mois'), (h2, 'janv. 2023 – juil. 2024', '19 mois')])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Ph(PI.clockCounterClockwise, color: p.text2),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.$1,
                        style: ts(14, w: FontWeight.w700, c: p.text),
                      ),
                      Text(
                        h.$2,
                        style: ts(12, w: FontWeight.w500, c: p.text2),
                      ),
                    ],
                  ),
                ),
                Text(
                  h.$3,
                  style: ts(13, w: FontWeight.w600, c: p.strong),
                ),
              ],
            ),
          ),
      ],
    );
    Widget section(String t, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t,
          style: ts(16, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );

    if (c.wide) {
      return LPage(
        wide: true,
        children: [
          Breadcrumb(backLabel: r.bldName, onBack: () => s.go('building'), current: r.id),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [ScreenTitle('Chambre ${r.id}', size: 32), const SizedBox(width: 12), badge]),
                    const SizedBox(height: 4),
                    Text(
                      '${r.bldName} · ${r.floorLabel}',
                      style: ts(14, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ),
              ),
              Btn('Modifier', icon: PI.pencilSimple, kind: BtnKind.outline, onPressed: s.editRoom),
            ],
          ),
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 2, child: ImageSlot('Photo principale', icon: PI.bed)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: const [
                      Expanded(child: ImageSlot('Photo 2')),
                      SizedBox(height: 12),
                      Expanded(child: ImageSlot('Photo 3')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      section(
                        'Caractéristiques',
                        Column(
                          children: [
                            KV('Numéro', r.id),
                            KV('Étage', r.floorLabel),
                            KV('Type', r.type),
                            KV('Loyer mensuel', r.rentF, valueColor: p.accent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      section('Équipements', equipWrap),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppCard(padding: const EdgeInsets.all(20), child: section('Locataire actuel', tenantBox)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppCard(padding: const EdgeInsets.all(20), child: section('Historique des occupants', history)),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        DetailBar(
          title: 'Chambre ${r.id}',
          onBack: () => s.go('building'),
          actions: [IconBtn(PI.pencilSimple, tooltip: 'Modifier', color: p.link, onPressed: s.editRoom)],
        ),
        Expanded(
          child: LPage(
            wide: false,
            gap: 16,
            children: [
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => SizedBox(width: 260, child: ImageSlot('Photo de la chambre', icon: i == 0 ? PI.bed : PI.image)),
                ),
              ),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.id,
                                style: ts(24, w: FontWeight.w700, c: p.text),
                              ),
                              Text(
                                '${r.bldName} · ${r.floorLabel}',
                                style: ts(13, w: FontWeight.w500, c: p.text2),
                              ),
                            ],
                          ),
                        ),
                        badge,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loyer mensuel',
                                style: ts(13, w: FontWeight.w500, c: p.text2),
                              ),
                              Text(
                                r.rentF,
                                style: ts(18, w: FontWeight.w700, c: p.accent),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Type',
                                style: ts(13, w: FontWeight.w500, c: p.text2),
                              ),
                              Text(
                                r.type,
                                style: ts(18, w: FontWeight.w700, c: p.text),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Hr(),
                    const SizedBox(height: 16),
                    section('Équipements', equipWrap),
                    const SizedBox(height: 20),
                    section('Locataire actuel', tenantBox),
                    const SizedBox(height: 20),
                    section('Historique des occupants', history),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Formulaire chambre ─────────────────────────────

class RoomForm extends StatefulWidget {
  const RoomForm(this.c, {super.key});
  final LCtx c;
  @override
  State<RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<RoomForm> {
  late final num = TextEditingController(text: widget.c.s.rf.num);
  late final rent = TextEditingController(text: widget.c.s.rf.rent);

  @override
  void dispose() {
    num.dispose();
    rent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = widget.c;
    final s = c.s;
    final rf = s.rf;
    final title = rf.editing ? 'Modifier la chambre ${rf.num}' : 'Ajouter une chambre';
    final sub = 'Immeuble ${rf.bld} · ${bNames[rf.bld]}';
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: ts(13, w: FontWeight.w600, c: p.text),
      ),
    );

    final numField = AppField(
      label: 'Numéro de chambre',
      controller: num,
      icon: PI.hash,
      hint: 'Ex. A-107',
      textCapitalization: TextCapitalization.characters,
      onChanged: (v) => s.set(() => rf.num = v.toUpperCase()),
      error: rf.err && rf.num.trim().isEmpty ? 'Indiquez le numéro de la chambre.' : null,
    );
    final rentField = AppField(
      label: 'Loyer mensuel',
      controller: rent,
      icon: PI.money,
      suffixText: 'FCFA',
      keyboardType: TextInputType.number,
      inputFormatters: [digitsSpaces],
      onChanged: (v) => s.set(() => rf.rent = v),
      error: rf.err && parseAmount(rf.rent) == 0 ? 'Le loyer doit être supérieur à 0.' : null,
    );
    final floors = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label('Étage'),
        ChipRow(
          wrap: true,
          children: [
            for (final f in floorsOf[rf.bld]!) ChoiceChipX(f == 1 ? '1er' : '${f}e', selected: rf.floor == '$f', onTap: () => s.set(() => rf.floor = '$f')),
          ],
        ),
      ],
    );
    final types = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label('Type'),
        ChipRow(
          wrap: true,
          children: [
            for (final t in const [('Simple', '35 000'), ('Studio', '45 000'), ('Appartement', '60 000')])
              ChoiceChipX(
                t.$1,
                selected: rf.type == t.$1,
                onTap: () => s.set(() {
                  rf.type = t.$1;
                  if (rf.rent.isEmpty) {
                    rf.rent = t.$2;
                    rent.text = t.$2;
                  }
                }),
              ),
          ],
        ),
      ],
    );
    final equip = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label('Équipements'),
        ChipRow(
          wrap: true,
          children: [
            for (final e in allEquip)
              ChoiceChipX(
                e,
                icon: rf.equip.contains(e) ? PI.check : PI.plus,
                selected: rf.equip.contains(e),
                onTap: () => s.set(() => rf.equip.contains(e) ? rf.equip.remove(e) : rf.equip.add(e)),
              ),
          ],
        ),
      ],
    );
    final status = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label('Statut'),
        ChipRow(
          wrap: true,
          children: [
            ChoiceChipX('Libre', icon: PI.doorOpen, selected: rf.status == 'free', onTap: () => s.set(() => rf.status = 'free')),
            ChoiceChipX('En travaux', icon: PI.trafficCone, selected: rf.status == 'works', onTap: () => s.set(() => rf.status = 'works')),
          ],
        ),
      ],
    );
    final photos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label('Photos'),
        SizedBox(
          height: 96,
          child: Row(
            children: [
              for (var i = 1; i <= (c.wide ? 4 : 3); i++) ...[
                if (i > 1) const SizedBox(width: 10),
                Expanded(child: ImageSlot('Photo $i', icon: PI.cameraPlus)),
              ],
            ],
          ),
        ),
      ],
    );

    if (c.wide) {
      return LPage(
        wide: true,
        max: 860,
        children: [
          Breadcrumb(backLabel: 'Annuler', onBack: s.cancelRoom),
          LHeader(title, wide: true, sub: sub),
          AppCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: numField),
                    const SizedBox(width: 16),
                    Expanded(child: rentField),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: floors),
                    Expanded(child: types),
                  ],
                ),
                const SizedBox(height: 20),
                equip,
                const SizedBox(height: 20),
                status,
                const SizedBox(height: 20),
                photos,
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Btn('Annuler', kind: BtnKind.outline, onPressed: s.cancelRoom),
              const SizedBox(width: 12),
              Btn(rf.editing ? 'Enregistrer les modifications' : 'Ajouter la chambre', onPressed: s.saveRoom),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
          child: Row(
            children: [
              IconBtn(PI.x, tooltip: 'Fermer', onPressed: s.cancelRoom),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: ts(18, w: FontWeight.w600, c: p.text),
                    ),
                    Text(
                      sub,
                      style: ts(13, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: LPage(wide: false, gap: 20, children: [numField, floors, types, rentField, equip, status, photos])),
      ],
    );
  }
}

// ───────────────────────────── Ajouter un locataire ─────────────────────────────

class AddTenant extends StatefulWidget {
  const AddTenant(this.c, {super.key});
  final LCtx c;
  @override
  State<AddTenant> createState() => _AddTenantState();
}

class _AddTenantState extends State<AddTenant> {
  late final at = widget.c.s.at;
  late final name = TextEditingController(text: at.name);
  late final phone = TextEditingController(text: at.phone);
  late final idn = TextEditingController(text: at.idn);

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    idn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = widget.c;
    final s = c.s;
    final at = s.at;
    final room = at.room.isEmpty ? null : s.roomData(at.room);
    final firstName = at.name.trim().isEmpty ? 'le locataire' : at.name.trim().split(' ').first;
    final phoneShow = at.phone.isEmpty ? '07 00 00 00 00' : at.phone;

    final step1 = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!c.wide) ...[
          Text(
            'Informations',
            style: ts(20, w: FontWeight.w600, c: p.text),
          ),
          const SizedBox(height: 16),
        ],
        AppField(
          label: 'Nom complet',
          controller: name,
          icon: PI.user,
          hint: 'Prénom et nom',
          onChanged: (v) => at.name = v,
          error: at.err && at.name.trim().isEmpty ? 'Ce champ est obligatoire.' : null,
        ),
        const SizedBox(height: 16),
        AppField(
          label: 'Téléphone',
          controller: phone,
          icon: PI.phone,
          hint: '07 12 34 56 78',
          keyboardType: TextInputType.phone,
          onChanged: (v) => at.phone = v,
          error: at.err && at.phone.replaceAll(RegExp(r'\D'), '').length < 8 ? 'Numéro invalide : 8 chiffres minimum.' : null,
        ),
        const SizedBox(height: 16),
        AppField(
          label: 'Pièce d’identité (facultatif)',
          controller: idn,
          icon: PI.identificationCard,
          hint: 'N° CNI ou passeport',
          onChanged: (v) => at.idn = v,
        ),
      ],
    );

    final step2 = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choisir une chambre libre',
          style: ts(20, w: FontWeight.w600, c: p.text),
        ),
        const SizedBox(height: 12),
        if (at.err) ...[const ErrorText('Sélectionnez une chambre.'), const SizedBox(height: 12)],
        for (final id in freeRooms)
          Builder(
            builder: (_) {
              final r = s.roomData(id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SelectCard(
                  icon: PI.doorOpen,
                  tone: Tone.pale,
                  title: '$id · ${r.type}',
                  subtitle: 'Immeuble ${r.bld} · ${r.floorLabel} · ${r.rentF}',
                  selected: at.room == id,
                  onTap: () => s.set(() {
                    at.room = id;
                    at.err = false;
                  }),
                ),
              );
            },
          ),
      ],
    );

    final step3 = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!c.wide) ...[
          Text(
            'Bail',
            style: ts(20, w: FontWeight.w600, c: p.text),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Date d’entrée',
          style: ts(13, w: FontWeight.w600, c: p.text),
        ),
        const SizedBox(height: 8),
        Tap(
          onTap: () => s.toast('Sélecteur de date : 1 décembre 2026'),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: AppRadius.r,
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Ph(PI.calendarBlank, color: p.text2),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('1 décembre 2026', style: ts(16, c: p.text)),
                ),
                Ph(PI.caretDown, size: 20, color: p.text2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Durée du bail',
          style: ts(13, w: FontWeight.w600, c: p.text),
        ),
        const SizedBox(height: 8),
        ChipRow(
          wrap: true,
          children: [
            for (final d in const [6, 12, 24]) ChoiceChipX('$d mois', selected: at.dur == d, onTap: () => s.set(() => at.dur = d)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.wide ? p.bg : p.card, borderRadius: AppRadius.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker('Récapitulatif', color: p.text2),
              const SizedBox(height: 10),
              Text(
                c.wide ? '${at.name} · $phoneShow' : at.name,
                style: ts(16, w: FontWeight.w700, c: p.text),
              ),
              const SizedBox(height: 4),
              Text(
                'Chambre ${room == null ? '—' : '${room.id} · ${room.type} · ${room.rentF}'}',
                style: ts(14, w: FontWeight.w500, c: p.strong),
              ),
              const SizedBox(height: 4),
              Text(
                'Caution : 1 mois de loyer (${room?.rentF ?? '—'})',
                style: ts(14, w: FontWeight.w500, c: p.text2),
              ),
              Text(
                'Durée : ${at.dur} mois',
                style: ts(14, w: FontWeight.w500, c: p.text2),
              ),
            ],
          ),
        ),
      ],
    );

    final success = Column(
      children: [
        const SizedBox(height: 24),
        const PopIn(child: IconTile(PI.checkCircle, size: 96, iconSize: 52, tone: Tone.paid)),
        const SizedBox(height: 24),
        Text(
          'Locataire ajouté',
          style: ts(28, w: FontWeight.w700, c: p.text),
        ),
        const SizedBox(height: 10),
        Text(
          'La chambre ${at.room} est attribuée à $firstName. Un SMS l’invite à installer MaCité et à se connecter avec son numéro $phoneShow.',
          textAlign: TextAlign.center,
          style: ts(16, c: p.text2, h: 1.5),
        ),
        const SizedBox(height: 32),
        Btn('Terminer', height: 56, expand: !c.wide, onPressed: () => s.go('tenants')),
      ],
    );

    final body = switch (at.step) {
      1 => step1,
      2 => step2,
      3 => step3,
      _ => success,
    };

    if (c.wide) {
      return LPage(
        wide: true,
        max: 760,
        children: [
          if (at.step < 4) ...[
            Row(
              children: [
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: LinkButton('Retour', icon: PI.arrowLeft, color: p.text2, onPressed: s.atBack),
                ),
                const Spacer(),
                Text(
                  'Étape ${at.step} sur 3',
                  style: ts(13, w: FontWeight.w600, c: p.text2),
                ),
              ],
            ),
            const LHeader('Ajouter un locataire', wide: true),
            StepBar(at.step, labels: const ['1. Informations', '2. Chambre', '3. Bail']),
          ],
          AppCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeUp(key: ValueKey(at.step), child: body),
                if (at.step < 4) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Btn(at.step == 3 ? 'Ajouter le locataire' : 'Continuer', onPressed: s.atNext),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (at.step < 4) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
            child: Row(
              children: [
                IconBtn(PI.arrowLeft, tooltip: 'Retour', onPressed: s.atBack),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ajouter un locataire',
                    style: ts(18, w: FontWeight.w600, c: p.text),
                  ),
                ),
                Text(
                  'Étape ${at.step} sur 3',
                  style: ts(13, w: FontWeight.w600, c: p.text2),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: StepBar(at.step)),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: FadeUp(key: ValueKey(at.step), child: body),
          ),
        ),
      ],
    );
  }
}
