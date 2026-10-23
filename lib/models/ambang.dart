/// SEMENTARA: ambang status belum ditetapkan tim medis/dosen.
/// Semua angka ada di sini supaya cukup diubah di satu tempat.
/// Jangan dipakai sebagai dasar keputusan klinis sebelum divalidasi.
class AmbangStatus {
  static const double waspadaMgDl = 12.0; // TODO konfirmasi
  static const double kritisMgDl = 15.0; // TODO konfirmasi
  static const double waspadaPersen = 50.0; // TODO konfirmasi
  static const double kritisPersen = 75.0; // TODO konfirmasi

  /// Mengembalikan 'normal' | 'waspada' | 'kritis' (sesuai statusColor di common.dart).
  static String dari(double nilai, String satuan) {
    final w = satuan == '%' ? waspadaPersen : waspadaMgDl;
    final k = satuan == '%' ? kritisPersen : kritisMgDl;
    if (nilai >= k) return 'kritis';
    if (nilai >= w) return 'waspada';
    return 'normal';
  }

  /// Batas yang sama dengan Firestore rules (0-100 untuk %, selain itu 0-40).
  static double maks(String satuan) => satuan == '%' ? 100 : 40;
}
