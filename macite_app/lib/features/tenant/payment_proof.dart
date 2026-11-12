import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import '../../widgets/anim.dart';
import '../../widgets/fields.dart';
import '../../widgets/ui.dart';
import 'tenant_store.dart';

/// Envoi d'un justificatif : bottom sheet sur mobile, dialogue sur ordinateur.
Future<void> openPaymentProof(BuildContext context, TenantStore s) {
  final body = _ProofForm(store: s);
  if (context.isWide) {
    return showDialog(
      context: context,
      barrierColor: context.pal.overlay,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: body),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    barrierColor: context.pal.overlay,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: body,
    ),
  );
}

class _ProofForm extends StatefulWidget {
  const _ProofForm({required this.store});
  final TenantStore store;
  @override
  State<_ProofForm> createState() => _ProofFormState();
}

class _ProofFormState extends State<_ProofForm> {
  final amt = TextEditingController(text: '45 000');
  bool file = false, tried = false, sending = false;

  @override
  void dispose() {
    amt.dispose();
    super.dispose();
  }

  int get value => parseAmount(amt.text);

  void send() {
    if (sending) return;
    if (value == 0 || value > rent || !file) {
      setState(() => tried = true);
      return;
    }
    setState(() => sending = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.store.proofSent(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final wide = context.isWide;
    final amtErr = tried && (value == 0 || value > rent);
    final fileErr = tried && !file;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 20, wide ? 24 : 12, wide ? 28 : 20, 24 + MediaQuery.paddingOf(context).bottom),
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
                      'Envoyer un justificatif',
                      style: ts(22, w: FontWeight.w700, c: p.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Novembre 2026 · Chambre A-102',
                      style: ts(14, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ),
              ),
              if (wide) IconBtn(PI.x, tooltip: 'Fermer', onPressed: sending ? null : () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          AppField(
            label: 'Montant payé',
            controller: amt,
            icon: PI.money,
            suffixText: 'FCFA',
            keyboardType: TextInputType.number,
            inputFormatters: [digitsSpaces],
            onChanged: (_) => setState(() {}),
            error: amtErr ? (value == 0 ? 'Saisissez le montant payé.' : 'Le montant dépasse le loyer dû (45 000 FCFA).') : null,
            helper: 'Loyer de novembre : 45 000 FCFA. Vous pouvez déclarer un paiement partiel.',
          ),
          const SizedBox(height: 20),
          Text(
            'Pièce justificative',
            style: ts(13, w: FontWeight.w600, c: fileErr ? p.m700 : p.text),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: file
                ? Container(
                    key: const ValueKey('file'),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: p.bg, borderRadius: AppRadius.r),
                    child: Row(
                      children: [
                        const ImageSlot('Reçu', width: 64, height: 64, compact: true, icon: PI.receipt),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'recu-novembre.jpg',
                                style: ts(15, w: FontWeight.w600, c: p.text),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Photo ajoutée · 1,2 Mo',
                                style: ts(13, w: FontWeight.w500, c: p.text2),
                              ),
                            ],
                          ),
                        ),
                        IconBtn(PI.trash, tooltip: 'Retirer', color: p.m700, onPressed: () => setState(() => file = false)),
                      ],
                    ),
                  )
                : Tap(
                    key: const ValueKey('nofile'),
                    onTap: () => setState(() => file = true),
                    child: CustomPaint(
                      painter: _Dashed(fileErr ? p.magenta : p.outline),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(color: p.a100.withValues(alpha: 0.5), borderRadius: AppRadius.r),
                        child: Column(
                          children: [
                            Ph(PI.cameraPlus, size: 32, color: p.link),
                            const SizedBox(height: 8),
                            Text(
                              'Prendre une photo ou choisir un fichier',
                              textAlign: TextAlign.center,
                              style: ts(15, w: FontWeight.w600, c: p.link),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reçu, capture d’écran ou bordereau · JPG, PNG ou PDF',
                              textAlign: TextAlign.center,
                              style: ts(13, w: FontWeight.w500, c: p.text2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (fileErr) ...[const SizedBox(height: 8), const ErrorText('Ajoutez la photo de votre reçu.')],
          const SizedBox(height: 20),
          const InfoNote('Votre bailleur vérifie le justificatif. Votre quittance est disponible dès sa validation.'),
          const SizedBox(height: 20),
          FadeUp(
            child: Btn(sending ? 'Envoi…' : 'Envoyer au bailleur', busy: sending, height: 56, expand: true, onPressed: send),
          ),
        ],
      ),
    );
  }
}

class _Dashed extends CustomPainter {
  _Dashed(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.md)));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed o) => o.color != color;
}
