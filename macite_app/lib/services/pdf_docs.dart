import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Génération des documents PDF de MaCité (quittances, fiches locataires, bail)
/// et ouverture du menu de partage / enregistrement de l'appareil.

const _accent = PdfColor.fromInt(0xFF006786);
const _accentSoft = PdfColor.fromInt(0xFFE9F8FF);
const _text = PdfColor.fromInt(0xFF201E1D);
const _muted = PdfColor.fromInt(0xFF6B6564);
const _line = PdfColor.fromInt(0xFFD9D4D3);

const kLandlordName = 'Daniel A.';
const kCityName = 'Cité Les Jardins';

/// Une quittance de loyer.
class Quittance {
  const Quittance({
    required this.tenant,
    required this.room,
    required this.building,
    required this.month,
    required this.amount,
    required this.paidOn,
    this.landlord = kLandlordName,
  });
  final String tenant, room, building, month, amount, paidOn, landlord;
}

/// Une fiche locataire.
class FicheLocataire {
  const FicheLocataire({required this.name, required this.rows, required this.status, this.note});
  final String name, status;

  /// Paires libellé / valeur, dans l'ordre d'affichage.
  final List<(String, String)> rows;
  final String? note;
}

/// Les polices PDF standard ne couvrent pas les espaces insécables fines : on les remplace.
String _c(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

pw.ThemeData? _theme;
pw.MemoryImage? _logo;

Future<void> _load() async {
  if (_theme != null) return;
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Montserrat-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Montserrat-Bold.ttf'));
  final italic = pw.Font.ttf(await rootBundle.load('assets/fonts/Montserrat-Italic.ttf'));
  _logo = pw.MemoryImage((await rootBundle.load('assets/images/logo-mark.png')).buffer.asUint8List());
  _theme = pw.ThemeData.withFont(base: regular, bold: bold, italic: italic);
}

pw.TextStyle _s(double size, {bool bold = false, PdfColor color = _text}) =>
    pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color);

pw.Widget _header(String kicker) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Row(
      children: [
        if (_logo != null) pw.Image(_logo!, width: 30, height: 30),
        pw.SizedBox(width: 8),
        pw.Text('MaCité', style: _s(18, bold: true)),
        pw.Spacer(),
        pw.Text(_c(kicker.toUpperCase()), style: _s(10, bold: true, color: _accent).copyWith(letterSpacing: 0.6)),
      ],
    ),
    pw.SizedBox(height: 10),
    pw.Container(height: 2, color: _accent),
    pw.SizedBox(height: 24),
  ],
);

pw.Widget _footer(pw.Context ctx) => pw.Row(
  children: [
    pw.Text(_c('$kCityName · document généré par MaCité'), style: _s(9, color: _muted)),
    pw.Spacer(),
    pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: _s(9, color: _muted)),
  ],
);

pw.Widget _kv(String k, String v) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(vertical: 7),
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 170,
        child: pw.Text(_c(k), style: _s(11, color: _muted)),
      ),
      pw.Expanded(child: pw.Text(_c(v), style: _s(11, bold: true))),
    ],
  ),
);

pw.Widget _quittanceBody(Quittance q) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text('Quittance de loyer', style: _s(26, bold: true)),
    pw.SizedBox(height: 4),
    pw.Text(_c(q.month), style: _s(14, color: _muted)),
    pw.SizedBox(height: 24),
    pw.Container(
      padding: const pw.EdgeInsets.all(16),
      color: _accentSoft,
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text('Montant reçu', style: _s(12, color: _accent)),
          ),
          pw.Text(_c(q.amount), style: _s(20, bold: true, color: _accent)),
        ],
      ),
    ),
    pw.SizedBox(height: 16),
    _kv('Locataire', q.tenant),
    _kv('Logement', 'Chambre ${q.room} · ${q.building}'),
    _kv('Période', q.month),
    _kv('Payé le', q.paidOn),
    _kv('Bailleur', '${q.landlord} · $kCityName'),
    pw.SizedBox(height: 24),
    pw.Text(
      _c(
        'Je soussigné ${q.landlord}, bailleur du logement désigné ci-dessus, déclare avoir reçu de ${q.tenant} '
        'la somme de ${q.amount} au titre du loyer de la période « ${q.month} », et lui en donne quittance, '
        'sous réserve de tous mes droits.',
      ),
      style: _s(11).copyWith(lineSpacing: 3),
    ),
    pw.SizedBox(height: 36),
    pw.Row(
      children: [
        pw.Spacer(),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Le bailleur', style: _s(10, color: _muted)),
            pw.SizedBox(height: 4),
            pw.Text(_c(q.landlord), style: _s(14, bold: true).copyWith(fontStyle: pw.FontStyle.italic)),
          ],
        ),
      ],
    ),
  ],
);

/// Une quittance par page.
Future<Uint8List> buildQuittances(List<Quittance> list) async {
  await _load();
  final doc = pw.Document(theme: _theme, title: 'Quittances de loyer', author: 'MaCité');
  for (final q in list) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => _header('Quittance'),
        footer: _footer,
        build: (_) => [_quittanceBody(q)],
      ),
    );
  }
  return doc.save();
}

/// Une fiche locataire par page.
Future<Uint8List> buildFiches(List<FicheLocataire> list) async {
  await _load();
  final doc = pw.Document(theme: _theme, title: 'Fiches locataires', author: 'MaCité');
  for (final f in list) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => _header('Fiche locataire'),
        footer: _footer,
        build: (_) => [
          pw.Text(_c(f.name), style: _s(26, bold: true)),
          pw.SizedBox(height: 4),
          pw.Text(_c(f.status), style: _s(13, bold: true, color: _accent)),
          pw.SizedBox(height: 20),
          for (final r in f.rows) _kv(r.$1, r.$2),
          if (f.note != null && f.note!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Note du bailleur', style: _s(11, color: _muted)),
            pw.SizedBox(height: 4),
            pw.Text(_c(f.note!), style: _s(11).copyWith(lineSpacing: 3)),
          ],
        ],
      ),
    );
  }
  return doc.save();
}

/// Contrat de bail (résumé des conditions).
Future<Uint8List> buildBail({
  required String tenant,
  required String room,
  required String building,
  required String rent,
  required String start,
  required String duration,
  required String signedOn,
}) async {
  await _load();
  final doc = pw.Document(theme: _theme, title: 'Contrat de bail', author: 'MaCité');
  pw.Widget article(String title, String body) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(_c(title), style: _s(12, bold: true)),
        pw.SizedBox(height: 3),
        pw.Text(_c(body), style: _s(11).copyWith(lineSpacing: 3)),
      ],
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (_) => _header('Contrat de bail'),
      footer: _footer,
      build: (_) => [
        pw.Text('Contrat de bail', style: _s(26, bold: true)),
        pw.SizedBox(height: 4),
        pw.Text(_c('Chambre $room · $building · $kCityName'), style: _s(13, color: _muted)),
        pw.SizedBox(height: 20),
        _kv('Bailleur', kLandlordName),
        _kv('Locataire', tenant),
        _kv('Logement', 'Chambre $room · $building'),
        _kv('Loyer mensuel', rent),
        _kv('Début du bail', start),
        _kv('Durée', duration),
        _kv('Signé le', signedOn),
        pw.SizedBox(height: 22),
        article(
          'Article 1 · Loyer',
          'Le loyer de $rent est payable d’avance, au plus tard le 5 de chaque mois. Le locataire transmet son justificatif de paiement dans l’application ; une quittance lui est remise après validation.',
        ),
        article(
          'Article 2 · Usage des lieux',
          'Le logement est destiné à l’habitation du locataire. Toute sous-location est interdite sans l’accord écrit du bailleur.',
        ),
        article(
          'Article 3 · Entretien',
          'Le locataire entretient le logement et signale sans délai tout problème au bailleur. Les réparations importantes restent à la charge du bailleur.',
        ),
        article(
          'Article 4 · Règlement de la cité',
          'Le locataire respecte le règlement intérieur : calme après 22 h, visites jusqu’à 21 h, parties communes dégagées.',
        ),
        article(
          'Article 5 · Fin du bail',
          'Chaque partie peut mettre fin au bail avec un préavis d’un mois. Un état des lieux est établi à l’entrée et à la sortie.',
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Le bailleur', style: _s(10, color: _muted)),
                  pw.SizedBox(height: 4),
                  pw.Text(kLandlordName, style: _s(14, bold: true).copyWith(fontStyle: pw.FontStyle.italic)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Le locataire', style: _s(10, color: _muted)),
                pw.SizedBox(height: 4),
                pw.Text(_c(tenant), style: _s(14, bold: true).copyWith(fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}

/// Nom de fichier sans accents ni espaces.
String pdfFileName(String base) {
  const from = 'àâäéèêëîïôöùûüçÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ';
  const to = 'aaaeeeeiioouuucAAAEEEEIIOOUUUC';
  final b = StringBuffer();
  for (final ch in _c(base).split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  final clean = b.toString().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return '$clean.pdf';
}

/// Génère le PDF puis ouvre le menu de l'appareil (ouvrir, enregistrer, partager).
/// Renvoie faux si la génération ou l'ouverture a échoué.
Future<bool> sharePdf(String name, Future<Uint8List> Function() build) async {
  try {
    final bytes = await build();
    // Le booléen renvoyé indique seulement si l'utilisateur a été au bout du partage.
    await Printing.sharePdf(bytes: bytes, filename: pdfFileName(name));
    return true;
  } catch (e) {
    debugPrint('PDF : $e');
    return false;
  }
}
