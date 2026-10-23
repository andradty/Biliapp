import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/agenda.dart';
import '../models/bacaan_alat.dart';
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
  final _rtdb = FirebaseDatabase.instance; // databaseURL dari firebase_options.dart
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
        .map((s) => s.docs.where((d) => d.data()['dibatalkan'] != true).length);
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
        .map((s) => _periksa(s).where((e) => !e.dibatalkan).toList());
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

  // ---------- Alat (Realtime Database) ----------
  /// Bacaan terus-menerus dari alat. Hanya untuk tampilan, TIDAK disimpan.
  Stream<BacaanAlat?> bacaanLive(String deviceId) => _rtdb
      .ref('devices/$deviceId/live')
      .onValue
      .map((e) => BacaanAlat.dari(e.snapshot.value));

  /// Membuka sesi baru di alat. Alat menulis hasil REKAM ke `hasil/{device}/{sesi_id}`.
  /// `sesi_id` yang sama dipakai sebagai ID dokumen Firestore `pemeriksaan`.
  Future<String> mulaiSesi(String deviceId) async {
    final id = 'ses_${DateTime.now().millisecondsSinceEpoch}';
    await _rtdb.ref('devices/$deviceId/sesi').set({
      'sesi_id': id,
      'status': 'menunggu',
      'waktu_mulai': ServerValue.timestamp,
    });
    return id;
  }

  /// Dipanggil kalau layar ditutup sebelum hasil disimpan.
  Future<void> batalSesi(String deviceId) =>
      _rtdb.ref('devices/$deviceId/sesi/status').set('batal');

  /// Hasil yang ditulis alat saat tombol REKAM ditekan (null sampai ditekan).
  Stream<BacaanAlat?> hasilSesi(String deviceId, String sesiId) => _rtdb
      .ref('hasil/$deviceId/$sesiId')
      .onValue
      .map((e) => BacaanAlat.dari(e.snapshot.value));

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

  /// Pemeriksaan bersifat immutable (hanya create). Tidak perlu di-await agar
  /// tetap jalan offline.
  Future<void> tambahPemeriksaan({
    required Pasien pasien,
    required DeviceInfo device,
    required double hasil,
    required String satuan,
    required String status,
    Map<String, dynamic> pengukuran = const {},
    String? sesiId,
  }) {
    final ref = _db
        .collection('pemeriksaan')
        .doc(sesiId ?? 'ses_${DateTime.now().millisecondsSinceEpoch}');
    return ref.set(Pemeriksaan.buatMap(
      pasienId: pasien.id,
      orangTuaId: pasien.orangTuaId,
      puskesmasId: user.puskesmasId!,
      deviceId: device.id,
      kalibrasiId: device.kalibrasiAktifId!,
      userId: user.uid,
      hasil: hasil,
      satuan: satuan,
      status: status,
      pengukuran: pengukuran,
    ));
  }

  /// Koreksi = batalkan (void), bukan edit/hapus. Data asli tetap ada sebagai
  /// jejak audit. Hanya boleh sekali; alasan 5-200 karakter (diatur Firestore rules).
  Future<void> batalkanPemeriksaan(String id, String alasan) =>
      _db.collection('pemeriksaan').doc(id).update({
        'dibatalkan': true,
        'alasan_batal': alasan.trim(),
        'dibatalkan_oleh': user.uid,
        'dibatalkan_pada': FieldValue.serverTimestamp(),
      });

  // ---------- Agenda / jadwal pemeriksaan ----------
  List<Agenda> _agenda(QuerySnapshot<Map<String, dynamic>> s) =>
      (s.docs.map(Agenda.fromDoc).where((a) => a.mendatang).toList()
        ..sort((a, b) => a.tanggal.compareTo(b.tanggal)));

  /// Petugas: jadwal mendatang satu pasien.
  Stream<List<Agenda>> agendaPasien(String pasienId) => _db
      .collection('agenda')
      .where('puskesmas_id', isEqualTo: user.puskesmasId)
      .where('pasien_id', isEqualTo: pasienId)
      .snapshots(includeMetadataChanges: true)
      .map(_agenda);

  /// Orang Tua: jadwal mendatang semua anaknya.
  Stream<List<Agenda>> agendaAnak() => _db
      .collection('agenda')
      .where('orang_tua_id', isEqualTo: user.uid)
      .snapshots(includeMetadataChanges: true)
      .map(_agenda);

  Future<void> jadwalkan({
    required Pasien pasien,
    required DateTime tanggal,
    String catatan = '',
  }) {
    final t = DateTime(tanggal.year, tanggal.month, tanggal.day);
    return _db.collection('agenda').doc().set({
      'pasien_id': pasien.id,
      'orang_tua_id': pasien.orangTuaId,
      'puskesmas_id': user.puskesmasId,
      'tanggal': Timestamp.fromDate(t),
      'catatan': catatan.trim(),
      'status': 'dijadwalkan',
      'dibuat_oleh': user.uid,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> batalkanAgenda(String id) =>
      _db.collection('agenda').doc(id).update({'status': 'dibatalkan'});

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