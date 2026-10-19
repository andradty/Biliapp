import 'package:cloud_firestore/cloud_firestore.dart';

import 'util.dart';

class Pemeriksaan {
  final String id;
  final String pasienId;
  final String deviceId;
  final String kalibrasiId;
  final String userId;
  final DateTime waktu;
  final double hasil; // mg/dL
  final String status; // normal | waspada | kritis
  final String puskesmasId;
  final String? orangTuaId;
  final bool pending;

  const Pemeriksaan({
    required this.id,
    required this.pasienId,
    required this.deviceId,
    required this.kalibrasiId,
    required this.userId,
    required this.waktu,
    required this.hasil,
    required this.status,
    required this.puskesmasId,
    this.orangTuaId,
    this.pending = false,
  });

  factory Pemeriksaan.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Pemeriksaan(
      id: d.id,
      pasienId: (m['pasien_id'] ?? '') as String,
      deviceId: (m['device_id'] ?? '') as String,
      kalibrasiId: (m['kalibrasi_id'] ?? '') as String,
      userId: (m['user_id'] ?? '') as String,
      waktu: toDate(m['waktu_pemeriksaan']) ?? DateTime.now(),
      hasil: ((m['hasil_bilirubin'] ?? 0) as num).toDouble(),
      status: (m['status_hasil'] ?? '') as String,
      puskesmasId: (m['puskesmas_id'] ?? '') as String,
      orangTuaId: m['orang_tua_id'] as String?,
      pending: d.metadata.hasPendingWrites,
    );
  }
}
