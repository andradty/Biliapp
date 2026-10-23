import 'package:cloud_firestore/cloud_firestore.dart';

import 'util.dart';

/// Cermin dokumen Firestore `pemeriksaan/{sesi_id}`.
///
/// `hasil` (field `hasil_bilirubin`) adalah NILAI UTAMA dengan satuan `satuan`.
/// Nilai mentah fotodioda disimpan di `pengukuran` supaya hasil bisa dihitung
/// ulang bila rumus/satuan resmi berubah.
class Pemeriksaan {
  final String id;
  final String pasienId;
  final String deviceId;
  final String kalibrasiId;
  final String userId;
  final DateTime waktu;
  final double hasil;
  final String satuan; // '%' | 'mg/dL'
  final String status; // normal | waspada | kritis
  final String puskesmasId;
  final String? orangTuaId;
  final Map<String, dynamic> pengukuran; // adc, arus_ma, lux, konsentrasi, jaundice_persen
  final bool pending;
  final bool dibatalkan; // dibatalkan Petugas (void); data asli tetap tersimpan
  final String? alasanBatal;

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
    this.satuan = 'mg/dL',
    this.orangTuaId,
    this.pengukuran = const {},
    this.pending = false,
    this.dibatalkan = false,
    this.alasanBatal,
  });

  /// Skala maksimum gauge pada layar Hasil.
  double get skalaMaks => satuan == '%' ? 100 : 20;

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
      // dokumen lama (mis. ses_001) belum punya `satuan`
      satuan: (m['satuan'] ?? 'mg/dL') as String,
      status: (m['status_hasil'] ?? '') as String,
      puskesmasId: (m['puskesmas_id'] ?? '') as String,
      orangTuaId: m['orang_tua_id'] as String?,
      pengukuran: Map<String, dynamic>.from((m['pengukuran'] ?? {}) as Map),
      pending: d.metadata.hasPendingWrites,
      dibatalkan: m['dibatalkan'] == true,
      alasanBatal: m['alasan_batal'] as String?,
    );
  }

  /// Satu-satunya tempat yang mendefinisikan isi dokumen saat dibuat.
  /// `notif_terkirim` WAJIB boolean false (dipantau relay VPS).
  static Map<String, dynamic> buatMap({
    required String pasienId,
    required String? orangTuaId,
    required String puskesmasId,
    required String deviceId,
    required String kalibrasiId,
    required String userId,
    required double hasil,
    required String satuan,
    required String status,
    required Map<String, dynamic> pengukuran,
    DateTime? waktu,
  }) =>
      {
        'pasien_id': pasienId,
        'orang_tua_id': orangTuaId,
        'puskesmas_id': puskesmasId,
        'device_id': deviceId,
        'kalibrasi_id': kalibrasiId,
        'user_id': userId,
        'waktu_pemeriksaan': Timestamp.fromDate(waktu ?? DateTime.now()),
        'created_at': FieldValue.serverTimestamp(),
        'hasil_bilirubin': hasil,
        'satuan': satuan,
        'status_hasil': status,
        'pengukuran': pengukuran,
        'notif_terkirim': false,
      };
}