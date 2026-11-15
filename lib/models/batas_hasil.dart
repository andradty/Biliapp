/// Hasil pemeriksaan dinyatakan dalam PERSEN (% jaundice) dari sinyal fotodioda.
/// Aplikasi TIDAK mengelompokkan hasil ke kategori (normal/waspada/kritis);
/// interpretasi dilakukan tenaga kesehatan.
class BatasHasil {
  /// Rentang valid nilai persen (sama dengan Firestore rules).
  static const double maks = 100.0;
}
