import 'package:cloud_firestore/cloud_firestore.dart';

import 'util.dart';

class Pasien {
  final String id;
  final String nama;
  final String jenisKelamin; // 'L' | 'P'
  final String puskesmasId;
  final String? orangTuaId;
  final DateTime? tanggalLahir;
  final int? beratLahir; // gram
  final int? usiaKehamilan; // minggu
  final String alamat;
  final bool pending; // belum tersinkron ke server

  const Pasien({
    required this.id,
    required this.nama,
    required this.jenisKelamin,
    required this.puskesmasId,
    required this.alamat,
    this.orangTuaId,
    this.tanggalLahir,
    this.beratLahir,
    this.usiaKehamilan,
    this.pending = false,
  });

  factory Pasien.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Pasien(
      id: d.id,
      nama: (m['nama'] ?? '') as String,
      jenisKelamin: (m['jenis_kelamin'] ?? '') as String,
      puskesmasId: (m['puskesmas_id'] ?? '') as String,
      alamat: (m['alamat'] ?? '') as String,
      orangTuaId: m['orang_tua_id'] as String?,
      tanggalLahir: toDate(m['tanggal_lahir']),
      beratLahir: (m['berat_lahir'] as num?)?.toInt(),
      usiaKehamilan: (m['usia_kehamilan_minggu'] as num?)?.toInt(),
      pending: d.metadata.hasPendingWrites,
    );
  }

  String get usia {
    final t = tanggalLahir;
    if (t == null) return '-';
    final hari = DateTime.now().difference(t).inDays;
    if (hari < 60) return '$hari hari';
    return '${(hari / 30).floor()} bulan';
  }
}
