import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/ambang.dart';
import '../models/pemeriksaan.dart';
import '../widgets/common.dart'; // fmtTanggal, fmtJam, fmtKadar, statusColor, statusLabel
import '../widgets/edukasi_card.dart'; // edukasiUntuk, tandaBahaya

/// Laporan hasil skrining satu pemeriksaan dalam bentuk PDF (untuk Orang Tua).
/// Sengaja BUKAN sertifikat: tanpa tanda tangan/stempel, dan memuat catatan
/// bahwa hasil adalah skrining awal, bukan diagnosis.
class PdfHasil {
  static final _teal = PdfColor.fromInt(0xFF0B7A93);
  static final _ink = PdfColor.fromInt(0xFF16324A);
  static final _muted = PdfColor.fromInt(0xFF5B6B7A);
  static final _garis = PdfColor.fromInt(0xFFDCE6EC);
  static const _putih = PdfColors.white;

  static PdfColor _warna(String status) =>
      PdfColor.fromInt(statusColor(status).toARGB32());

  /// Campur warna dengan putih (t=0.85 -> latar sangat muda).
  static PdfColor _terang(PdfColor c, double t) => PdfColor(
        c.red + (1 - c.red) * t,
        c.green + (1 - c.green) * t,
        c.blue + (1 - c.blue) * t,
      );

  /// Font bawaan PDF hanya aman untuk karakter Latin dasar.
  static String _b(String s) => s.replaceAll('–', '-').replaceAll('•', '-');

  static Future<Uint8List> bangun({
    required Pemeriksaan p,
    required String namaPasien,
  }) async {
    final warna = _warna(p.status);
    final edu = edukasiUntuk(p.status);
    final sekarang = DateTime.now();

    final doc = pw.Document(
      title: 'Laporan Hasil Skrining BiliCheck - $namaPasien',
      author: 'BiliCheck',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => pw.Column(children: [
          pw.Divider(color: _garis, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(
              'Dibuat dari aplikasi BiliCheck pada ${fmtTanggal(sekarang)} ${fmtJam(sekarang)}',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text('Hal. ${ctx.pageNumber}/${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: _muted)),
          ]),
        ]),
        build: (ctx) => [
          // ---- Kepala ----
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
                color: _teal, borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('BiliCheck',
                  style: pw.TextStyle(
                      color: _putih, fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Laporan Hasil Skrining Bilirubin',
                  style: pw.TextStyle(color: _putih, fontSize: 11)),
            ]),
          ),
          pw.SizedBox(height: 18),

          // ---- Identitas ----
          _baris('Nama bayi', namaPasien),
          _baris('Tanggal pemeriksaan', fmtTanggal(p.waktu)),
          _baris('Waktu', fmtJam(p.waktu)),
          _baris('ID pemeriksaan', p.id),
          pw.SizedBox(height: 14),

          // ---- Hasil ----
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: _terang(warna, 0.88),
              border: pw.Border.all(color: warna, width: 1),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Hasil skrining',
                      style: pw.TextStyle(fontSize: 10, color: _muted)),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(fmtKadar(p.hasil),
                          style: pw.TextStyle(
                              fontSize: 34,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink)),
                      pw.SizedBox(width: 6),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Text(p.satuan,
                            style: pw.TextStyle(fontSize: 12, color: _muted)),
                      ),
                    ],
                  ),
                ]),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                      color: warna, borderRadius: pw.BorderRadius.circular(20)),
                  child: pw.Text(statusLabel(p.status),
                      style: pw.TextStyle(
                          color: _putih, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          ),

          // ---- Skala (hanya untuk satuan persen) ----
          if (p.satuan == '%') ...[
            pw.SizedBox(height: 14),
            _skala(p.hasil),
          ],
          pw.SizedBox(height: 18),

          // ---- Edukasi ----
          if (edu != null) ...[
            pw.Text(_b(edu.judul),
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold, color: warna)),
            pw.SizedBox(height: 6),
            pw.Text(_b(edu.penjelasan),
                style: pw.TextStyle(fontSize: 10.5, height: 1.4, color: _ink)),
            pw.SizedBox(height: 12),
            pw.Text('Yang bisa dilakukan',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 6),
            for (final s in edu.langkah) _butir(s, warna),
            pw.SizedBox(height: 12),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFDECEC),
                  borderRadius: pw.BorderRadius.circular(10)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Segera ke fasilitas kesehatan jika bayi:',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFC62828))),
                pw.SizedBox(height: 6),
                for (final s in tandaBahaya) _butir(s, PdfColor.fromInt(0xFFC62828), size: 10),
              ]),
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Text(
            'Hasil ini adalah skrining awal dan bukan diagnosis. Informasi pada laporan '
            'ini bersifat edukasi dan tidak menggantikan pemeriksaan oleh tenaga kesehatan.',
            style: pw.TextStyle(fontSize: 9, height: 1.4, color: _muted),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Bagikan / simpan PDF lewat share sheet sistem.
  static Future<void> bagikan(Pemeriksaan p, String namaPasien) async {
    final bytes = await bangun(p: p, namaPasien: namaPasien);
    final nama = namaPasien.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final t = p.waktu;
    final tgl = '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}';
    await Printing.sharePdf(bytes: bytes, filename: 'BiliCheck_${nama}_$tgl.pdf');
  }

  // ---------- potongan layout ----------

  static pw.Widget _baris(String label, String nilai) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(
              width: 120,
              child: pw.Text(label, style: pw.TextStyle(fontSize: 10.5, color: _muted))),
          pw.Expanded(
              child: pw.Text(nilai,
                  style: pw.TextStyle(
                      fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _ink))),
        ]),
      );

  static pw.Widget _butir(String s, PdfColor c, {double size = 10.5}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 4,
            height: 4,
            decoration: pw.BoxDecoration(color: c, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(
              child: pw.Text(_b(s),
                  style: pw.TextStyle(fontSize: size, height: 1.35, color: _ink))),
        ]),
      );

  /// Bilah 0-100% dengan tiga zona (normal / warning / kritis) dan penanda hasil.
  static pw.Widget _skala(double hasil) {
    final w = AmbangStatus.waspada.round();
    final k = AmbangStatus.kritis.round();
    final pos = hasil.clamp(0.0, 100.0).round();

    pw.Widget zona(int flex, String status) => pw.Expanded(
          flex: flex,
          child: pw.Container(height: 10, color: _terang(_warna(status), 0.25)),
        );
    pw.Widget label(int flex, String teks) => pw.Expanded(
          flex: flex,
          child: pw.Center(
              child: pw.Text(teks, style: pw.TextStyle(fontSize: 8, color: _muted))),
        );

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Posisi hasil pada skala', style: pw.TextStyle(fontSize: 9, color: _muted)),
      pw.SizedBox(height: 4),
      pw.Row(children: [
        if (pos > 0) pw.Expanded(flex: pos, child: pw.SizedBox()),
        pw.Container(
          width: 6,
          height: 14,
          decoration: pw.BoxDecoration(
              color: _ink, borderRadius: pw.BorderRadius.circular(3)),
        ),
        if (pos < 100) pw.Expanded(flex: 100 - pos, child: pw.SizedBox()),
      ]),
      pw.Row(children: [
        zona(w, 'normal'),
        zona(k - w, 'waspada'),
        zona(100 - k, 'kritis'),
      ]),
      pw.SizedBox(height: 3),
      pw.Row(children: [
        label(w, 'Normal'),
        label(k - w, 'Warning'),
        label(100 - k, 'Kritis'),
      ]),
    ]);
  }
}
