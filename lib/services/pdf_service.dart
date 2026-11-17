import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show AlertDialog, BuildContext, Color, Colors, Column, CrossAxisAlignment, FilledButton, FontWeight, Icon, Icons, MainAxisSize, ScaffoldMessenger, SelectableText, SizedBox, SnackBar, Text, TextAlign, TextButton, TextStyle, Navigator, showDialog;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/pasien.dart';
import '../models/pemeriksaan.dart';
import '../widgets/common.dart' show fmtJam, fmtKadar, fmtTanggal;

/// Pembuat PDF hasil pemeriksaan. Hanya memakai karakter ASCII/Latin-1 agar
/// aman dengan font bawaan PDF (tanpa embed font).
class PdfService {
  static const _teal = PdfColor.fromInt(0xFF0B7A93);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _garis = PdfColor.fromInt(0xFFD1D5DB);

  static String _tgl(DateTime d) => '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static String _aman(String s) =>
      s.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

  static const _disclaimer =
      'Hasil ini adalah skrining awal dari alat BiliCheck dalam persen (% jaundice), '
      'bukan hasil laboratorium (mg/dL) dan BUKAN diagnosis medis. Konsultasikan hasil '
      'dengan tenaga kesehatan untuk penilaian dan tindak lanjut.';

  static pw.Widget _header(String judul) => pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(color: _teal, borderRadius: pw.BorderRadius.circular(10)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('BiliCheck',
              style: pw.TextStyle(
                  color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(judul, style: const pw.TextStyle(color: PdfColors.white, fontSize: 12)),
        ]),
      );

  static pw.Widget _baris(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(
              width: 130, child: pw.Text(k, style: const pw.TextStyle(color: _muted, fontSize: 11))),
          pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 11))),
        ]),
      );

  static List<pw.Widget> _dataPasien(String nama, Pasien? p) => [
        _baris('Nama pasien', nama),
        if (p != null) ...[
          _baris('Jenis kelamin', p.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'),
          if (p.tanggalLahir != null)
            _baris('Tanggal lahir', '${fmtTanggal(p.tanggalLahir!)} (${p.usia})'),
          if (p.usiaKehamilan != null) _baris('Usia kehamilan', '${p.usiaKehamilan} minggu'),
          if (p.beratLahir != null) _baris('Berat lahir', '${p.beratLahir} gram'),
        ],
      ];

  static pw.Widget _footer(pw.Context c) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Dicetak ${fmtTanggal(DateTime.now())} ${fmtJam(DateTime.now())}',
              style: const pw.TextStyle(color: _muted, fontSize: 9)),
          pw.Text('Halaman ${c.pageNumber} / ${c.pagesCount}',
              style: const pw.TextStyle(color: _muted, fontSize: 9)),
        ],
      );

  static pw.Widget _catatan() => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _garis), borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Text(_disclaimer, style: const pw.TextStyle(fontSize: 9.5, color: _muted)),
      );

  // ---------------------------------------------------------------- hasil tunggal
  static Future<Uint8List> hasilBytes(Pemeriksaan p, String namaPasien, {Pasien? pasien}) async {
    final doc = pw.Document(title: 'Hasil Skrining $namaPasien', author: 'BiliCheck');
    final warna = p.dibatalkan ? _muted : _teal;

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: _footer,
      build: (_) => [
        _header('Laporan Hasil Skrining Bilirubin'),
        pw.SizedBox(height: 18),
        pw.Text('DATA PASIEN',
            style: pw.TextStyle(fontSize: 10, color: _teal, fontWeight: pw.FontWeight.bold)),
        pw.Divider(color: _garis),
        ..._dataPasien(namaPasien, pasien),
        pw.SizedBox(height: 14),
        pw.Text('PEMERIKSAAN',
            style: pw.TextStyle(fontSize: 10, color: _teal, fontWeight: pw.FontWeight.bold)),
        pw.Divider(color: _garis),
        _baris('Waktu pemeriksaan', '${fmtTanggal(p.waktu)}, ${fmtJam(p.waktu)}'),
        _baris('ID alat', p.deviceId.isEmpty ? '-' : p.deviceId),
        _baris('ID pemeriksaan', p.id),
        pw.SizedBox(height: 14),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 22),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: warna, width: 1.5),
              borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Column(children: [
            pw.Text('HASIL', style: const pw.TextStyle(fontSize: 10, color: _muted)),
            pw.SizedBox(height: 4),
            pw.Text('${fmtKadar(p.hasil)} ${p.satuan}',
                style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold, color: warna)),
          ]),
        ),
        if (p.dibatalkan) ...[
          pw.SizedBox(height: 10),
          pw.Text(
              'Pemeriksaan ini dibatalkan oleh petugas dan tidak dipakai sebagai acuan.'
              '${(p.alasanBatal ?? '').isEmpty ? '' : ' Alasan: ${p.alasanBatal}'}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFFC62828))),
        ],
        pw.SizedBox(height: 18),
        _catatan(),
      ],
    ));
    return doc.save();
  }

  // ---------------------------------------------------------------- riwayat
  static Future<Uint8List> riwayatBytes(Pasien pasien, List<Pemeriksaan> data) async {
    final doc = pw.Document(title: 'Riwayat ${pasien.nama}', author: 'BiliCheck');
    final sah = data.where((e) => !e.dibatalkan).toList();
    final rata =
        sah.isEmpty ? null : sah.map((e) => e.hasil).reduce((a, b) => a + b) / sah.length;

    final baris = <List<String>>[
      for (var i = 0; i < data.length; i++)
        [
          '${i + 1}',
          fmtTanggal(data[i].waktu),
          fmtJam(data[i].waktu),
          '${fmtKadar(data[i].hasil)} ${data[i].satuan}',
          data[i].dibatalkan
              ? 'Dibatalkan${(data[i].alasanBatal ?? '').isEmpty ? '' : ': ${data[i].alasanBatal}'}'
              : '',
        ],
    ];

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: _footer,
      build: (_) => [
        _header('Riwayat Pemeriksaan Bilirubin'),
        pw.SizedBox(height: 18),
        ..._dataPasien(pasien.nama, pasien),
        pw.SizedBox(height: 8),
        _baris('Jumlah pemeriksaan', '${sah.length}'),
        if (rata != null) _baris('Rata-rata hasil', '${fmtKadar(rata)} %'),
        pw.SizedBox(height: 12),
        if (baris.isEmpty)
          pw.Text('Belum ada pemeriksaan.', style: const pw.TextStyle(color: _muted))
        else
          pw.TableHelper.fromTextArray(
            headers: ['No', 'Tanggal', 'Jam', 'Hasil', 'Keterangan'],
            data: baris,
            headerStyle:
                pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: _teal),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: _garis, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            columnWidths: {
              0: const pw.FixedColumnWidth(26),
              1: const pw.FixedColumnWidth(86),
              2: const pw.FixedColumnWidth(40),
              3: const pw.FixedColumnWidth(60),
              4: const pw.FlexColumnWidth(),
            },
          ),
        pw.SizedBox(height: 18),
        _catatan(),
      ],
    ));
    return doc.save();
  }


  // ---------------------------------------------------------------- unduh / simpan
  static Future<void> unduhHasil(BuildContext context, Pemeriksaan p, String namaPasien,
      {Pasien? pasien}) async {
    await _unduh(
      context,
      () => hasilBytes(p, namaPasien, pasien: pasien),
      'BiliCheck_Hasil_${_aman(namaPasien)}_${_tgl(p.waktu)}.pdf',
    );
  }

  static Future<void> unduhRiwayat(BuildContext context, Pasien pasien, List<Pemeriksaan> data) async {
    await _unduh(
      context,
      () => riwayatBytes(pasien, data),
      'BiliCheck_Riwayat_${_aman(pasien.nama)}_${_tgl(DateTime.now())}.pdf',
    );
  }

  static Future<void> _unduh(
      BuildContext context, Future<Uint8List> Function() buat, String namaFile) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await buat();
      if (kIsWeb) {
        // Browser: unduhan ditangani browser.
        await Printing.sharePdf(bytes: bytes, filename: namaFile);
        return;
      }
      final path = await _simpan(bytes, namaFile);
      if (!context.mounted) return;
      await _modalBerhasil(context, namaFile, path);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal mengunduh PDF: $e')));
    }
  }

  static Future<String> _simpan(Uint8List bytes, String namaFile) async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory(); // .../Android/data/<paket>/files
    } else {
      base = await getDownloadsDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}BiliCheck');
    if (!await dir.exists()) await dir.create(recursive: true);

    var nama = namaFile;
    if (await File('${dir.path}${Platform.pathSeparator}$nama').exists()) {
      final n = DateTime.now();
      String d(int v) => v.toString().padLeft(2, '0');
      nama = namaFile.replaceFirst(RegExp(r'\.pdf$'), '_${d(n.hour)}${d(n.minute)}${d(n.second)}.pdf');
    }
    final file = File('${dir.path}${Platform.pathSeparator}$nama');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> _modalBerhasil(BuildContext context, String namaFile, String path) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
        title: const Text('PDF berhasil diunduh', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tersimpan di penyimpanan perangkat:'),
            const SizedBox(height: 8),
            Text(namaFile, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            SelectableText(path, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          FilledButton(
            onPressed: () {
              OpenFilex.open(path);
            },
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }
}
