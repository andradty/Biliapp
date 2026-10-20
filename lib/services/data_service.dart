import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/device.dart';
import '../models/kalibrasi.dart';
import '../models/pasien.dart';
import '../models/pemeriksaan.dart';

/// Semua query sengaja memuat filter yang diminta security rules
/// (puskesmas_id untuk Petugas, orang_tua_id untuk Orang Tua).
class DataService {
  final AppUser user;
  final _db = FirebaseFirestore.instance;
  DataService(this.user);

  List<Pasien> _pasien(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(Pasien.fromDoc).toList();
  List<Pemeriksaan> _periksa(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(Pemeriksaan.fromDoc).toList();

  // ---------- Petugas ----------
  Stream<DocumentSnapshot<Map<String, dynamic>>> puskesmas() =>
      _db.collection('puskesmas').doc(user.puskesmasId).snapshots();

  Stream<List<Pasien>> pasienPuskesmas() => _db
      .collection('pasien')
      .where('puskesmas_id', isEqualTo: user.puskesmasId)
      .orderBy('nama')
      .snapshots(includeMetadataChanges: true)
      .map(_pasien);

  Stream<List<Pemeriksaan>> pemeriksaanTerakhir({int limit = 20}) => _db
      .collection('pemeriksaan')
      .where('puskesmas_id', isEqualTo: user.puskesmasId)
      .orderBy('waktu_pemeriksaan', descending: true)
      .limit(limit)
      .snapshots(includeMetadataChanges: true)
      .map(_periksa);

  Stream<int> jumlahHariIni() {
    final n = DateTime.now();
    final awal = DateTime(n.year, n.month, n.day);
    return _db
        .collection('pemeriksaan')
        .where('puskesmas_id', isEqualTo: user.puskesmasId)
        .where('waktu_pemeriksaan', isGreaterThanOrEqualTo: Timestamp.fromDate(awal))
        .snapshots()
        .map((s) => s.size);
  }

  Stream<List<Pemeriksaan>> riwayatPasien(String pasienId) => _db
      .collection('pemeriksaan')
      .where('puskesmas_id', isEqualTo: user.puskesmasId)
      .where('pasien_id', isEqualTo: pasienId)
      .orderBy('waktu_pemeriksaan', descending: true)
      .snapshots(includeMetadataChanges: true)
      .map(_periksa);

  /// 30 hari terakhir untuk ringkasan (memakai index puskesmas_id + waktu desc).
  Stream<List<Pemeriksaan>> pemeriksaan30Hari() {
    final awal = DateTime.now().subtract(const Duration(days: 30));
    return _db
        .collection('pemeriksaan')
        .where('puskesmas_id', isEqualTo: user.puskesmasId)
        .where('waktu_pemeriksaan', isGreaterThanOrEqualTo: Timestamp.fromDate(awal))
        .orderBy('waktu_pemeriksaan', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(_periksa);
  }

  /// Alat milik Puskesmas Petugas (1 Puskesmas = 1 alat).
  Stream<DeviceInfo?> deviceSaya() => _db
      .collection('devices')
      .where('puskesmas_id', isEqualTo: user.puskesmasId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : DeviceInfo.fromDoc(s.docs.first));

  Stream<Kalibrasi?> kalibrasiAktif(String deviceId, String kalibrasiId) => _db
      .collection('devices')
      .doc(deviceId)
      .collection('kalibrasi')
      .doc(kalibrasiId)
      .snapshots()
      .map((d) => d.exists ? Kalibrasi.fromDoc(deviceId, d) : null);

  /// Mencari akun Orang Tua lewat nomor HP (untuk menautkan ke pasien).
  Future<String?> cariOrangTua(String nohp) async {
    final q = await _db
        .collection('users')
        .where('role', isEqualTo: 'orang_tua')
        .where('nohp', isEqualTo: nohp.trim())
        .limit(1)
        .get();
    return q.docs.isEmpty ? null : q.docs.first.id;
  }

  /// Tidak perlu di-await agar tetap jalan offline (tersimpan di cache lokal).
  Future<void> tambahPasien({
    required String nama,
    required DateTime lahir,
    required String jenisKelamin,
    required int beratLahir,
    required int usiaKehamilan,
    required String alamat,
    String? orangTuaId,
  }) {
    final ref = _db.collection('pasien').doc();
    return ref.set({
      'nama': nama.trim(),
      'tanggal_lahir': Timestamp.fromDate(lahir),
      'jenis_kelamin': jenisKelamin,
      'puskesmas_id': user.puskesmasId,
      'orang_tua_id': orangTuaId,
      'created_by': user.uid,
      'berat_lahir': beratLahir,
      'usia_kehamilan_minggu': usiaKehamilan,
      'alamat': alamat.trim(),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Orang Tua ----------
  Stream<List<Pasien>> anakSaya() => _db
      .collection('pasien')
      .where('orang_tua_id', isEqualTo: user.uid)
      .snapshots(includeMetadataChanges: true)
      .map((s) => _pasien(s)..sort((a, b) => a.nama.compareTo(b.nama)));

  Stream<List<Pemeriksaan>> pemeriksaanAnak({String? pasienId}) => _db
      .collection('pemeriksaan')
      .where('orang_tua_id', isEqualTo: user.uid)
      .orderBy('waktu_pemeriksaan', descending: true)
      .snapshots(includeMetadataChanges: true)
      .map((s) {
        final l = _periksa(s);
        return pasienId == null ? l : l.where((e) => e.pasienId == pasienId).toList();
      });
}