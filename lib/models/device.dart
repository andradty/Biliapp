import 'package:cloud_firestore/cloud_firestore.dart';

/// Cermin dokumen `devices/{device_id}`.
class DeviceInfo {
  final String id;
  final String puskesmasId;
  final String status; // aktif | nonaktif | kalibrasi
  final String? kalibrasiAktifId;
  final String? sensorUtama;

  const DeviceInfo({
    required this.id,
    required this.puskesmasId,
    required this.status,
    this.kalibrasiAktifId,
    this.sensorUtama,
  });

  factory DeviceInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    String? kosongJadiNull(dynamic v) {
      final s = v as String?;
      return (s == null || s.trim().isEmpty) ? null : s;
    }

    return DeviceInfo(
      id: d.id,
      puskesmasId: (m['puskesmas_id'] ?? '') as String,
      status: (m['status'] ?? '') as String,
      kalibrasiAktifId: kosongJadiNull(m['kalibrasi_aktif_id']),
      sensorUtama: kosongJadiNull(m['sensor_utama']),
    );
  }
}
