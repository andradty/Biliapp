/// Satu bacaan dari alat di Realtime Database.
///
/// Dipakai untuk:
///  - `devices/{id}/live`          -> bacaan terus-menerus (ada counter `n`)
///  - `hasil/{id}/{sesi_id}`       -> hasil saat tombol REKAM ditekan (tulis sekali)
///
/// Satuan hasil selalu persen (% jaundice), disimpan sebagai `hasil_bilirubin`.
class BacaanAlat {
  final int urut; // `n` pada live; naik tiap tulis supaya event selalu terpicu
  final double hasil; // % jaundice
  final String? kalibrasiId; // kalibrasi yang dipakai firmware saat menghitung
  final Map<String, dynamic> pengukuran; // adc, arus_ma, lux, konsentrasi
  final String? error; // alat menulis {error: "..."} kalau pembacaan gagal

  const BacaanAlat({
    required this.urut,
    required this.hasil,
    required this.pengukuran,
    this.kalibrasiId,
    this.error,
  });

  static const satuan = '%';
  static const _kunciPengukuran = ['adc', 'arus_ma', 'lux', 'konsentrasi'];

  /// Mengembalikan null kalau node kosong / formatnya tidak dikenali.
  static BacaanAlat? dari(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    double? angka(String k) => m[k] is num ? (m[k] as num).toDouble() : null;

    if (m['error'] != null) {
      return BacaanAlat(urut: 0, hasil: 0, pengukuran: const {}, error: '${m['error']}');
    }
    final hasil = angka('hasil_bilirubin');
    if (hasil == null) return null;

    final p = <String, dynamic>{};
    for (final k in _kunciPengukuran) {
      final v = angka(k);
      if (v != null) p[k] = v;
    }
    return BacaanAlat(
      urut: m['n'] is num ? (m['n'] as num).toInt() : 0,
      hasil: hasil,
      pengukuran: p,
      kalibrasiId: m['kalibrasi_id'] is String ? m['kalibrasi_id'] as String : null,
    );
  }
}