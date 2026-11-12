import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macite/features/landlord/landlord_shell.dart';
import 'package:macite/features/landlord/landlord_store.dart';
import 'package:macite/services/accounts.dart';
import 'package:macite/services/pdf_docs.dart';
import 'package:macite/features/tenant/tenant_store.dart';
import 'package:macite/theme/app_theme.dart';
import 'package:macite/widgets/anim.dart';

void main() {
  test('formatFcfa formate les montants en FCFA', () {
    expect(formatFcfa(45000), '45 000 FCFA');
    expect(formatFcfa(1260000), '1 260 000 FCFA');
    expect(parseAmount('45 000'), 45000);
  });

  testWidgets('FloatY flotte réellement (la phase initiale ne fige pas l’animation)', (t) async {
    const k = Key('carte');
    await t.pumpWidget(
      const Center(
        child: FloatY(phase: 0.5, child: SizedBox(key: k, width: 10, height: 10)),
      ),
    );
    final y0 = t.getTopLeft(find.byKey(k)).dy;
    await t.pump(const Duration(milliseconds: 1200));
    expect(t.getTopLeft(find.byKey(k)).dy, isNot(y0));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Les actions différées des stores sont ignorées après dispose()', (t) async {
    final tenant = TenantStore()..pickCat('plumb');
    final landlord = LandlordStore()..sendChat('Bonjour');
    final n = landlord.rep.msgs.length;
    tenant.dispose();
    landlord.dispose();
    await t.pump(const Duration(seconds: 3));
    expect(tenant.step, 1);
    expect(landlord.rep.msgs.length, n);
    expect(t.takeException(), isNull);
  });

  test('Les PDF sont réellement générés (quittances, fiches, bail)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const q = Quittance(tenant: 'Sarah M.', room: 'A-102', building: 'Immeuble A', month: 'Octobre 2026', amount: '45 000 FCFA', paidOn: '3 oct. 2026');
    const f = FicheLocataire(name: 'David K.', status: 'En retard', rows: [('Chambre', 'B-204'), ('Pièce d’identité', 'CNI n° 0000')], note: 'Note');
    final docs = [
      await buildQuittances([q, q]),
      await buildFiches([f]),
      await buildBail(
        tenant: 'Sarah M.',
        room: 'A-102',
        building: 'Immeuble A',
        rent: '45 000 FCFA',
        start: '1 sept. 2025',
        duration: '24 mois',
        signedOn: '28 août 2025',
      ),
    ];
    for (final d in docs) {
      expect(String.fromCharCodes(d.take(4)), '%PDF');
      expect(d.length, greaterThan(5000));
    }
    expect(pdfFileName('Quittance Sarah M. Août 2026'), 'Quittance-Sarah-M-Aout-2026.pdf');
  });

  test('Le profil choisi à l’inscription est retrouvé à la connexion', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Accounts.save(phone: '07 55 44 33 22', email: 'Awa@Mail.com', role: 'tenant');
    expect(await Accounts.roleOf('0755443322'), 'tenant');
    expect(await Accounts.roleOf(' awa@mail.com '), 'tenant');
    expect(await Accounts.roleOf('07 00 00 00 00'), isNull);
  });

  testWidgets('Le champ du chat remonte au-dessus du clavier', (t) async {
    t.view.physicalSize = const Size(400, 860);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final s = LandlordStore();
    await t.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: LandlordShell(store: s),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    s.openReport('s1');
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(t.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(860));
    t.view.viewInsets = const FakeViewPadding(bottom: 320); // clavier ouvert
    await t.pump(const Duration(milliseconds: 500));
    expect(t.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(860 - 320));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 3));
  });
}
