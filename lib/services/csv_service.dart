import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show BuildContext;
import 'package:share_plus/share_plus.dart';

import '../models/pemeriksaan.dart';
import 'unduh_file.dart';

/// Ekspor pemeriksaan ke CSV. Pemisah ';' + desimal koma cocok untuk Excel
/// berlokal Indonesia; ',' + desimal titik untuk Excel/tool lain.
class CsvService {
  static const kolom = [
    'waktu_pemeriksaan',
    'pasien_id',
    'nama_pasien',
    'hasil',
    'satuan',
    'dibatalkan',
    'alasan_batal',
    'device_id',
    'kalibrasi_id',
    'adc',
    'lux',
    'konsentrasi',
    'jaundice_persen',
  ];

  static String _dua(int n) => n.toString().padLeft(2, '0');
  static String _waktu(DateTime d) =>
      '${d.year}-${_dua(d.month)}-${_dua(d.day)} ${_dua(d.hour)}:${_dua(d.minute)}:${_dua(d.second)}';

  /// Cegah CSV injection: teks bebas yang diawali = + - @ dianggap rumus oleh Excel.
  static String _teks(String s) {
    final t = s.replaceAll('\r', ' ').replaceAll('\n', ' ');
    if (t.isNotEmpty && '=+-@'.contains(t[0])) return "'$t";
    return t;
  }

  static String _angka(dynamic v, String desimal) {
    if (v is! num) return '';
    final s = v.toString();
    return desimal == ',' ? s.replaceAll('.', ',') : s;
  }

  /// Konsentrasi sangat kecil (~1e-6): notasi ilmiah supaya tidak terbaca 0.
  static String _ilmiah(dynamic v, String desimal) {
    if (v is! num) return '';
    final s = v.toStringAsExponential(4);
    return desimal == ',' ? s.replaceAll('.', ',') : s;
  }

  static String _sel(String v, String pemisah) {
    if (v.contains(pemisah) || v.contains('"') || v.contains('\n') || v.contains('\r')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String buat(
      List<Pemeriksaan> data,
      Map<String, String> namaPasien, {
        String pemisah = ';',
        bool sertakanDibatalkan = false,
      }) {
    final desimal = pemisah == ';' ? ',' : '.';
    final buf = StringBuffer('\uFEFF'); // BOM agar Excel membaca UTF-8
    buf.write('${kolom.join(pemisah)}\r\n');
    for (final e in data) {
      if (e.dibatalkan && !sertakanDibatalkan) continue;
      final m = e.pengukuran;
      final baris = <String>[
        _waktu(e.waktu),
        e.pasienId,
        _teks(namaPasien[e.pasienId] ?? ''),
        _angka(e.hasil, desimal),
        e.satuan,
        e.dibatalkan ? 'ya' : 'tidak',
        _teks(e.alasanBatal ?? ''),
        e.deviceId,
        e.kalibrasiId,
        _angka(m['adc'], desimal),
        _angka(m['lux'], desimal),
        _ilmiah(m['konsentrasi'], desimal),
        _angka(m['jaundice_persen'], desimal),
      ];
      buf.write('${baris.map((v) => _sel(v, pemisah)).join(pemisah)}\r\n');
    }
    return buf.toString();
  }

  /// Android/iOS/desktop: simpan ke penyimpanan lalu tampilkan modal berhasil.
  /// Web: unduhan ditangani browser.
  static Future<void> unduh(BuildContext context, String isi, String namaFile) async {
    final bytes = Uint8List.fromList(utf8.encode(isi));
    if (kIsWeb) {
      final file = XFile.fromData(bytes, mimeType: 'text/csv', name: namaFile);
      await SharePlus.instance.share(ShareParams(files: [file], subject: namaFile));
      return;
    }
    final path = await UnduhFile.simpan(bytes, namaFile);
    if (!context.mounted) return;
    await UnduhFile.modalBerhasil(context, 'CSV', namaFile, path, mimeType: 'text/csv');
  }
}