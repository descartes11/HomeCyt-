import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/fields.dart';
import '../../widgets/ui.dart';
import 'landlord_screens.dart';
import 'landlord_store.dart';

// ───────────────────────────── Techniciens ─────────────────────────────

/// Liste des techniciens du bailleur : ajout, appel, retrait.
class TechniciansScreen extends StatelessWidget {
  const TechniciansScreen(this.c, {super.key});
  final LCtx c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = c.s;
    final active = s.reports.where((r) => r.tech.isNotEmpty && r.st != 'done').length;
    final sub = '${s.techList.length} technicien${s.techList.length > 1 ? 's' : ''} · $active intervention${active > 1 ? 's' : ''} en cours';

    final list = s.techList.isEmpty
        ? const EmptyState(icon: PI.hardHat, title: 'Aucun technicien', text: 'Ajoutez les artisans et le gardien qui interviennent dans votre cité.')
        : AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Separated(
              children: [
                for (final t in s.techList)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Avatar(t.initials, tone: Tone.neutral, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                overflow: TextOverflow.ellipsis,
                                style: ts(15, w: FontWeight.w700, c: p.text),
                              ),
                              Text(
                                '${t.job} · ${t.phone}',
                                overflow: TextOverflow.ellipsis,
                                style: ts(13, w: FontWeight.w500, c: p.text2),
                              ),
                              if (s.activeJobs(t) > 0) ...[
                                const SizedBox(height: 6),
                                StatusBadge('${s.activeJobs(t)} en cours', icon: PI.wrench, tone: Tone.neutral),
                              ],
                            ],
                          ),
                        ),
                        IconBtn(PI.phone, tooltip: 'Appeler', color: p.link, onPressed: () => s.toast('Appel vers ${t.name} · ${t.phone}…')),
                        IconBtn(PI.trash, tooltip: 'Retirer', color: p.m700, onPressed: () => _confirmRemove(context, s, t)),
                      ],
                    ),
                  ),
              ],
            ),
          );
    const note = InfoNote('Pour confier un problème à un technicien, ouvrez le signalement puis choisissez-le dans « Technicien ».');

    if (c.wide) {
      return LPage(
        wide: true,
        max: 900,
        children: [
          LHeader(
            'Techniciens',
            wide: true,
            sub: sub,
            actions: [Btn('Ajouter un technicien', icon: PI.plus, onPressed: () => openAddTech(context, s))],
          ),
          list,
          note,
        ],
      );
    }
    return LPage(
      wide: false,
      gap: 16,
      bottomPad: 96, // place pour le bouton flottant
      children: [
        LHeader('Techniciens', sub: sub, onBack: () => s.go('more')),
        list,
        note,
      ],
    );
  }
}

Future<void> _confirmRemove(BuildContext context, LandlordStore s, Tech t) {
  final busy = s.activeJobs(t);
  return showDialog(
    context: context,
    barrierColor: context.pal.overlay,
    builder: (ctx) {
      final p = ctx.pal;
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Retirer ${t.name} ?',
                  style: ts(20, w: FontWeight.w700, c: p.text),
                ),
                const SizedBox(height: 8),
                Text(
                  busy > 0
                      ? '${t.name} a $busy intervention${busy > 1 ? 's' : ''} en cours : ${busy > 1 ? 'elles redeviendront' : 'elle redeviendra'} « Non assigné ».'
                      : '${t.name} ne pourra plus être assigné aux signalements.',
                  style: ts(14, c: p.text2, h: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Btn('Annuler', kind: BtnKind.outline, expand: true, onPressed: () => Navigator.pop(ctx)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Btn(
                        'Retirer',
                        kind: BtnKind.danger,
                        expand: true,
                        onPressed: () {
                          Navigator.pop(ctx);
                          s.removeTech(t);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Formulaire « Ajouter un technicien » : feuille du bas (mobile) ou dialogue (ordinateur).
/// Avec [assign], le nouveau technicien est aussi assigné au signalement ouvert.
Future<void> openAddTech(BuildContext context, LandlordStore s, {bool assign = false}) {
  final wide = context.isWide;
  if (wide) {
    return showDialog(
      context: context,
      barrierColor: context.pal.overlay,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _AddTechForm(s: s, assign: assign, wide: true),
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    barrierColor: context.pal.overlay,
    // Le formulaire remonte au-dessus du clavier.
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _AddTechForm(s: s, assign: assign, wide: false),
    ),
  );
}

class _AddTechForm extends StatefulWidget {
  const _AddTechForm({required this.s, required this.assign, required this.wide});
  final LandlordStore s;
  final bool assign, wide;
  @override
  State<_AddTechForm> createState() => _AddTechFormState();
}

class _AddTechFormState extends State<_AddTechForm> {
  final name = TextEditingController();
  final phone = TextEditingController();
  String? job;
  bool tried = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  String? get nameError {
    if (!tried) return null;
    if (name.text.trim().isEmpty) return 'Indiquez le nom du technicien.';
    if (job != null && widget.s.hasTech(name.text, job!)) return 'Ce technicien est déjà dans votre liste.';
    return null;
  }

  String? get jobError => tried && job == null ? 'Choisissez une spécialité.' : null;

  String? get phoneError => tried && phone.text.replaceAll(RegExp(r'\D'), '').length < 8 ? 'Numéro invalide : 8 chiffres minimum.' : null;

  void submit() {
    setState(() => tried = true);
    if (nameError != null || jobError != null || phoneError != null) return;
    Navigator.pop(context);
    widget.s.addTech(name.text, job!, phone.text, assign: widget.assign);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final wide = widget.wide;
    void refresh(String _) {
      if (tried) setState(() {});
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 20, wide ? 24 : 12, wide ? 28 : 20, 24 + (wide ? 0 : MediaQuery.paddingOf(context).bottom)),
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
                      'Ajouter un technicien',
                      style: ts(22, w: FontWeight.w700, c: p.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.assign ? 'Il sera assigné à ce signalement.' : 'Vous pourrez l’assigner à vos signalements.',
                      style: ts(14, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ),
              ),
              if (wide) IconBtn(PI.x, tooltip: 'Fermer', onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          AppField(
            label: 'Nom',
            controller: name,
            icon: PI.user,
            hint: 'Prénom et nom',
            textCapitalization: TextCapitalization.words,
            error: nameError,
            onChanged: refresh,
          ),
          const SizedBox(height: 16),
          AppSelect<String>(
            label: 'Spécialité',
            icon: PI.wrench,
            hint: 'Sélectionnez une spécialité',
            value: job,
            items: [for (final j in techJobs) (j, j)],
            error: jobError,
            onChanged: (v) => setState(() => job = v),
          ),
          const SizedBox(height: 16),
          AppField(
            label: 'Téléphone',
            controller: phone,
            icon: PI.phone,
            hint: '07 12 34 56 78',
            keyboardType: TextInputType.phone,
            inputFormatters: [digitsSpaces],
            error: phoneError,
            onChanged: refresh,
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 24),
          Btn(widget.assign ? 'Ajouter et assigner' : 'Ajouter le technicien', icon: PI.plus, height: 52, expand: true, onPressed: submit),
        ],
      ),
    );
  }
}
