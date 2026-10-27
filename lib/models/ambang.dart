/// Ambang status hasil. Hasil dinyatakan dalam PERSEN (% jaundice) karena nilai
/// dihitung dari sinyal fotodioda dan tidak dikorelasikan ke mg/dL.
/// Angka batas masih SEMENTARA sampai ditetapkan tim medis/dosen pembimbing;
/// cukup ubah di sini. Jangan dipakai sebagai dasar keputusan klinis sebelum divalidasi.
class AmbangStatus {
  static const double waspada = 50.0; // TODO konfirmasi
  static const double kritis = 75.0; // TODO konfirmasi

  /// Batas yang sama dengan Firestore rules (0-100 untuk satuan %).
  static const double maks = 100.0;

  /// Mengembalikan 'normal' | 'waspada' | 'kritis' (sesuai statusColor di common.dart).
  static String dari(double persen) {
    if (persen >= kritis) return 'kritis';
    if (persen >= waspada) return 'waspada';
    return 'normal';
  }
}
