import 'package:cloud_firestore/cloud_firestore.dart';

import 'util.dart';

/// Jadwal pemeriksaan ulang yang dibuat Petugas untuk satu pasien.
class Agenda {
  final String id;
  final String pasienId;
  final String? orangTuaId;
  final DateTime tanggal;
  final String catatan;
  final String status; // 'dijadwalkan' | 'dibatalkan'
  final bool pending;

  const Agenda({
    required this.id,
    required this.pasienId,
    required this.tanggal,
    required this.catatan,
    required this.status,
    this.orangTuaId,
    this.pending = false,
  });

  factory Agenda.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Agenda(
      id: d.id,
      pasienId: (m['pasien_id'] ?? '') as String,
      orangTuaId: m['orang_tua_id'] as String?,
      tanggal: toDate(m['tanggal']) ?? DateTime.now(),
      catatan: (m['catatan'] ?? '') as String,
      status: (m['status'] ?? 'dijadwalkan') as String,
      pending: d.metadata.hasPendingWrites,
    );
  }

  static DateTime get _awalHariIni {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Masih berlaku: tidak dibatalkan dan belum lewat.
  bool get mendatang => status == 'dijadwalkan' && !tanggal.isBefore(_awalHariIni);

  /// Belum dibatalkan tapi tanggalnya sudah lewat (tidak ada pembatalan/penjadwalan ulang).
  bool get terlewat => status == 'dijadwalkan' && tanggal.isBefore(_awalHariIni);

  int get hariTerlewat =>
      _awalHariIni.difference(DateTime(tanggal.year, tanggal.month, tanggal.day)).inDays;

  int get hariLagi =>
      DateTime(tanggal.year, tanggal.month, tanggal.day).difference(_awalHariIni).inDays;

  String get hariLagiLabel {
    final h = hariLagi;
    if (h <= 0) return 'Hari ini';
    if (h == 1) return 'Besok';
    return '$h hari lagi';
  }
}
