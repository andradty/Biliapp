import 'package:cloud_firestore/cloud_firestore.dart';

import 'util.dart';

/// Cermin dokumen `devices/{device_id}/kalibrasi/{kalibrasi_id}`.
/// Dokumen kalibrasi tidak diubah; kalibrasi baru = dokumen baru.
class Kalibrasi {
  final String id;
  final String deviceId;
  final DateTime? tanggal;
  final double koefisienA; // slope arus(mA) -> lux
  final double koefisienB; // intercept
  final double nilaiLux; // I0: lux tanpa cairan
  final double alpha; // koefisien absorbsi
  final double diameter; // cm
  final String sensor; // 'fotodioda'
  final String rumusVersi;
  final String? catatan;
  final String? dibuatOleh;

  const Kalibrasi({
    required this.id,
    required this.deviceId,
    required this.koefisienA,
    required this.koefisienB,
    required this.nilaiLux,
    required this.alpha,
    required this.diameter,
    this.tanggal,
    this.sensor = 'fotodioda',
    this.rumusVersi = 'beer-lambert-v1',
    this.catatan,
    this.dibuatOleh,
  });

  factory Kalibrasi.fromDoc(String deviceId, DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    double n(String k) => ((m[k] ?? 0) as num).toDouble();
    return Kalibrasi(
      id: d.id,
      deviceId: deviceId,
      tanggal: toDate(m['tanggal']),
      koefisienA: n('koefisien_a'),
      koefisienB: n('koefisien_b'),
      nilaiLux: n('nilai_lux'),
      alpha: n('alpha'),
      diameter: n('diameter'),
      sensor: (m['sensor'] ?? 'fotodioda') as String,
      rumusVersi: (m['rumus_versi'] ?? 'beer-lambert-v1') as String,
      catatan: m['catatan'] as String?,
      dibuatOleh: m['dibuat_oleh'] as String?,
    );
  }
}
