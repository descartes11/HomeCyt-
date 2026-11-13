// Test de fumée : affiche chaque écran en mobile et en ordinateur, en clair et
// en sombre, et échoue sur toute erreur de rendu (débordement, contraintes…).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macite/app_state.dart';
import 'package:macite/features/auth/auth_flow.dart';
import 'package:macite/features/landing/landing_page.dart';
import 'package:macite/features/landlord/landlord_shell.dart';
import 'package:macite/features/landlord/landlord_store.dart';
import 'package:macite/features/landlord/landlord_techs.dart';
import 'package:macite/features/tenant/tenant_shell.dart';
import 'package:macite/features/tenant/tenant_store.dart';
import 'package:macite/theme/app_theme.dart';

const sizes = {
  'petit mobile': Size(360, 740),
  'mobile': Size(400, 860),
  'tablette': Size(900, 1100),
  'petit écran': Size(1100, 760),
  'ordinateur': Size(1440, 900),
};

Future<void> setSize(WidgetTester t, Size s) async {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Widget app(Widget home, {bool dark = false}) => ValueListenableBuilder(
  valueListenable: themeMode,
  builder: (_, _, _) => MaterialApp(theme: appTheme(), darkTheme: appTheme(dark: true), themeMode: dark ? ThemeMode.dark : themeMode.value, home: home),
);

Future<void> settle(WidgetTester t, [int ms = 900]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> finish(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 3));
}

void main() {
  setUpAll(() async {
    // Charge les vraies polices pour mesurer les textes comme dans l'app.
    Future<void> load(String family, List<String> files) async {
      final l = FontLoader(family);
      for (final f in files) {
        l.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await l.load();
    }

    await load(kFontFamily, [
      'Montserrat-Regular.ttf',
      'Montserrat-Italic.ttf',
      'Montserrat-Medium.ttf',
      'Montserrat-SemiBold.ttf',
      'Montserrat-Bold.ttf',
      'Montserrat-BoldItalic.ttf',
      'Montserrat-Black.ttf',
    ]);
    await load('PhosphorDuotone', ['Phosphor-Duotone.ttf']);
    await load('PhosphorFill', ['Phosphor-Fill.ttf']);
  });

  for (final e in sizes.entries) {
    for (final dark in [false, true]) {
      final label = '${e.key}${dark ? ' · sombre' : ''}';

      testWidgets('Bailleur · $label', (t) async {
        await setSize(t, e.value);
        final s = LandlordStore();
        await t.pumpWidget(app(LandlordShell(store: s), dark: dark));
        await settle(t, 1200);
        for (final scr in [
          'dashboard',
          'tenants',
          'tenant',
          'rents',
          'more',
          'buildings',
          'building',
          'room',
          'roomForm',
          'reports',
          'report',
          'ann',
          'settings',
        ]) {
          s.go(scr);
          await settle(t);
          expect(t.takeException(), isNull, reason: scr);
        }
        // Fiche d'un locataire avec justificatif, chambre libre, formulaire en édition
        s.openTenant('pn');
        await settle(t);
        s.roomSel = 'A-104';
        s.go('room');
        await settle(t);
        s.editRoom();
        await settle(t);
        s.rf.err = true;
        s.rf.num = '';
        s.refresh();
        await settle(t);
        // Ajout d'un locataire : 3 étapes + succès
        s.newTenant();
        await settle(t);
        s.atNext(); // erreurs
        await settle(t, 300);
        s.at
          ..name = 'Jean K.'
          ..phone = '07 12 34 56 78';
        s.atNext();
        await settle(t, 300);
        s.atNext(); // erreur chambre
        await settle(t, 300);
        s.at.room = 'A-104';
        s.atNext();
        await settle(t, 300);
        // Étape « Bail » : durée en liste + mois offerts
        s.setDur(6);
        s.setFree(2);
        await settle(t, 300);
        expect(t.takeException(), isNull, reason: 'bail');
        s.atNext();
        await settle(t, 300);
        // Actions
        s.approveProof('pn');
        s.rejectProof('ga');
        s.approveReg(s.regs.first);
        s.go('reports');
        await settle(t);
        for (final tab in ['doing', 'done']) {
          s.set(() => s.rTab = tab);
          await settle(t, 400);
        }
        s.openReport('s2');
        await settle(t);
        s.setRepStatus('done');
        s.setTech('Bruno (plombier)');
        // Techniciens : liste + formulaire d'ajout (feuille du bas ou dialogue)
        s.go('techs');
        await settle(t);
        expect(t.takeException(), isNull, reason: 'techniciens');
        openAddTech(t.element(find.byType(TechniciansScreen)), s);
        await settle(t, 500);
        expect(t.takeException(), isNull, reason: 'ajout technicien');
        Navigator.of(t.element(find.byType(TechniciansScreen))).pop();
        await settle(t, 500);
        s.addTech('Moussa', 'Serrurier', '07 11 22 33 44');
        await settle(t, 300);
        s.openReport('s2');
        await settle(t);
        s.sendChat('Bonjour');
        await settle(t, 2000);
        s.set(() => s.query = 'zzz');
        s.go('tenants');
        await settle(t);
        s.set(() {
          s.monthIdx = 1;
          s.rFilter = 'late';
        });
        s.go('rents');
        await settle(t);
        expect(t.takeException(), isNull);
        await finish(t);
      });

      testWidgets('Locataire · $label', (t) async {
        await setSize(t, e.value);
        final s = TenantStore();
        await t.pumpWidget(app(TenantShell(store: s), dark: dark));
        await settle(t, 1200);
        for (final scr in ['home', 'payments', 'myreports', 'city', 'profile', 'notifs', 'settings']) {
          s.go(scr);
          await settle(t);
          expect(t.takeException(), isNull, reason: scr);
        }
        s.startReport();
        await settle(t);
        s.pickCat('sec');
        await settle(t, 600);
        s.next(); // erreur description
        await settle(t, 300);
        s.setDesc('L’eau coule sous l’évier');
        s.next();
        await settle(t, 400);
        s.setUrg('urgent');
        await settle(t, 300);
        s.next();
        await settle(t, 1500);
        expect(s.step, 4);
        s.go('home');
        await settle(t);
        await t.tap(find.text('Envoyer un justificatif').first, warnIfMissed: false);
        await settle(t);
        await t.tap(find.text('Envoyer au bailleur'), warnIfMissed: false);
        await settle(t);
        await t.tapAt(const Offset(5, 5));
        await settle(t);
        s.proofSent(30000);
        await settle(t);
        s.go('myreports');
        await settle(t);
        s.rate(s.myReports.last, 5);
        await settle(t);
        expect(t.takeException(), isNull);
        await finish(t);
      });

      testWidgets('Écrans communs · $label', (t) async {
        await setSize(t, e.value);
        for (final scr in [null, 'home', 'onb', 'login', 'forgot', 'role', 'code', 'info', 'done']) {
          await t.pumpWidget(
            app(
              AuthFlow(key: UniqueKey(), initial: scr),
              dark: dark,
            ),
          );
          await settle(t, 2200);
          expect(t.takeException(), isNull, reason: '$scr');
        }
        // Inscription bailleur (sans CNI ni chambre)
        await t.pumpWidget(
          app(
            AuthFlow(key: UniqueKey(), initial: 'role'),
            dark: dark,
          ),
        );
        await settle(t, 500);
        await t.tap(find.text('Je suis bailleur'));
        await settle(t, 300);
        await t.tap(find.text('Continuer'));
        await settle(t, 600);
        await t.tap(find.text('Créer mon compte').last, warnIfMissed: false);
        await settle(t, 600);
        // Connexion avec erreurs
        await t.pumpWidget(
          app(
            AuthFlow(key: UniqueKey(), initial: 'login'),
            dark: dark,
          ),
        );
        await settle(t, 500);
        await t.tap(find.text('Se connecter').last);
        await settle(t, 600);
        expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
        expect(t.takeException(), isNull);
        await finish(t);
      });

      testWidgets('Accueil public · $label', (t) async {
        await setSize(t, e.value);
        await t.pumpWidget(app(const LandingPage(), dark: dark));
        await settle(t, 1500);
        await t.drag(find.byType(SingleChildScrollView).first, const Offset(0, -2500));
        await settle(t, 1500);
        await t.drag(find.byType(SingleChildScrollView).first, const Offset(0, -3000));
        await settle(t, 9000);
        expect(t.takeException(), isNull);
        await finish(t);
      });
    }
  }
}
