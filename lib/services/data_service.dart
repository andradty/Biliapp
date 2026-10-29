import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/agenda.dart';
import '../models/bacaan_alat.dart';
import '../models/app_user.dart';
import '../models/device.dart';
import '../models/kalibrasi.dart';
import '../models/pasien.dart';
import '../models/pemeriksaan.dart';
import '../models/status_alat.dart';

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
        .orderBy('waktu_pemeriksaan', descending: true)
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

  /// Semua kalibrasi sebuah alat, terbaru di atas.
  Stream<List<Kalibrasi>> daftarKalibrasi(String deviceId) => _db
      .collection('devices')
      .doc(deviceId)
      .collection('kalibrasi')
      .orderBy('tanggal', descending: true)
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map((d) => Kalibrasi.fromDoc(deviceId, d)).toList());

  /// Kalibrasi tidak pernah diubah: kalibrasi baru = dokumen baru (FR09).
  /// Tidak perlu di-await agar tetap jalan offline.
  Future<void> tambahKalibrasi({
    required String deviceId,
    required String id,
    required double nilaiLux,
    required double koefisienA,
    required double koefisienB,
    required double alpha,
    required double diameter,
    String? catatan,
  }) =>
      _db.collection('devices').doc(deviceId).collection('kalibrasi').doc(id).set({
        'tanggal': FieldValue.serverTimestamp(),
        'koefisien_a': koefisienA,
        'koefisien_b': koefisienB,
        'nilai_lux': nilaiLux,
        'alpha': alpha,
        'diameter': diameter,
        'sensor': 'fotodioda',
        'rumus_versi': 'beer-lambert-v1',
        if (catatan != null && catatan.trim().isNotEmpty) 'catatan': catatan.trim(),
        'dibuat_oleh': user.uid,
      });

  /// Menjadikan sebuah kalibrasi aktif: Firestore (`kalibrasi_aktif_id`, dibaca app
  /// saat simpan pemeriksaan) dan RTDB `kalibrasi_aktif` (koefisien yang dibaca alat).
  Future<void> aktifkanKalibrasi(String deviceId, Kalibrasi k) async {
    final firestore =
        _db.collection('devices').doc(deviceId).update({'kalibrasi_aktif_id': k.id});
    final rtdb = _rtdb.ref('devices/$deviceId/kalibrasi_aktif').set({
      'kalibrasi_id': k.id,
      'koefisien_a': k.koefisienA,
      'koefisien_b': k.koefisienB,
      'nilai_lux': k.nilaiLux,
      'alpha': k.alpha,
      'diameter': k.diameter,
    });
    await Future.wait([firestore, rtdb]);
  }

  // ---------- Alat (Realtime Database) ----------
  /// Bacaan terus-menerus dari alat. Hanya untuk tampilan, TIDAK disimpan.
  Stream<BacaanAlat?> bacaanLive(String deviceId) => _rtdb
      .ref('devices/$deviceId/live')
      .onValue
      .map((e) => BacaanAlat.dari(e.snapshot.value));

  /// Info yang ditulis alat berkala (firmware, sinyal WiFi, terakhir terlihat).
  Stream<StatusAlat?> statusAlat(String deviceId) => _rtdb
      .ref('devices/$deviceId/status')
      .onValue
      .map((e) => StatusAlat.dari(e.snapshot.value));

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
  /// Nama akun Orang Tua (Petugas boleh membaca users ber-role orang_tua).
  Future<String?> namaOrangTua(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return d.data()?['nama'] as String?;
  }

  /// Koreksi data pasien. Hanya field yang berubah yang dikirim (sesuai rules pasien update).
  /// Tidak perlu di-await agar tetap jalan offline.
  Future<void> ubahPasien(
      Pasien p, {
        required String nama,
        required DateTime lahir,
        required String jenisKelamin,
        required int beratLahir,
        required int usiaKehamilan,
        required String alamat,
      }) {
    final t = p.tanggalLahir;
    final lahirSama =
        t != null && t.year == lahir.year && t.month == lahir.month && t.day == lahir.day;
    final u = <String, dynamic>{
      if (nama.trim() != p.nama) 'nama': nama.trim(),
      if (!lahirSama) 'tanggal_lahir': Timestamp.fromDate(lahir),
      if (jenisKelamin != p.jenisKelamin) 'jenis_kelamin': jenisKelamin,
      if (beratLahir != p.beratLahir) 'berat_lahir': beratLahir,
      if (usiaKehamilan != p.usiaKehamilan) 'usia_kehamilan_minggu': usiaKehamilan,
      if (alamat.trim() != p.alamat) 'alamat': alamat.trim(),
    };
    if (u.isEmpty) return Future.value();
    return _db.collection('pasien').doc(p.id).update(u);
  }

  /// Menyamakan orang_tua_id pada pemeriksaan & agenda pasien dengan [ortuId]
  /// (null = tautan dilepas). Mengembalikan jumlah dokumen yang diperbarui.
  Future<int> _selaraskanOrangTua(Pasien p, String? ortuId) async {
    final pem = await _db
        .collection('pemeriksaan')
        .where('puskesmas_id', isEqualTo: user.puskesmasId)
        .where('pasien_id', isEqualTo: p.id)
        .orderBy('waktu_pemeriksaan', descending: true) // memakai index yang sudah ada
        .get();
    final ag = await _db
        .collection('agenda')
        .where('puskesmas_id', isEqualTo: user.puskesmasId)
        .where('pasien_id', isEqualTo: p.id)
        .get();
    final beda = [...pem.docs, ...ag.docs]
        .where((d) => d.data()['orang_tua_id'] != ortuId)
        .map((d) => d.reference)
        .toList();
    for (var i = 0; i < beda.length; i += 100) {
      final batch = _db.batch();
      for (final r in beda.skip(i).take(100)) {
        batch.update(r, {'orang_tua_id': ortuId});
      }
      await batch.commit();
    }
    return beda.length;
  }

  /// Menautkan atau mengganti Orang Tua lewat no. HP. Null kalau no. HP belum terdaftar.
  /// Butuh internet. Pasien di-update dulu (di-await): rules pemeriksaan/agenda membaca
  /// pasien.orang_tua_id lewat get(), yang melihat kondisi SEBELUM batch.
  Future<({String id, String nama, int diperbarui})?> tautkanOrangTua(
      Pasien p, String nohp) async {
    final ortuId = await cariOrangTua(nohp);
    if (ortuId == null) return null;
    final nama = await namaOrangTua(ortuId) ?? 'Orang Tua';
    await _db.collection('pasien').doc(p.id).update({'orang_tua_id': ortuId});
    final n = await _selaraskanOrangTua(p, ortuId);
    return (id: ortuId, nama: nama, diperbarui: n);
  }

  /// Melepas tautan: orang_tua_id jadi null di pasien, pemeriksaan, dan agenda.
  Future<int> lepasTautan(Pasien p) async {
    await _db.collection('pasien').doc(p.id).update({'orang_tua_id': null});
    return _selaraskanOrangTua(p, null);
  }

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

  /// Petugas: semua jadwal aktif (termasuk yang terlewat) agar bisa dijadwalkan ulang.
  List<Agenda> _agendaPetugas(QuerySnapshot<Map<String, dynamic>> s) =>
      (s.docs.map(Agenda.fromDoc).where((a) => a.status == 'dijadwalkan').toList()
        ..sort((a, b) => a.tanggal.compareTo(b.tanggal)));

  /// Petugas: jadwal aktif satu pasien (mendatang + terlewat).
  Stream<List<Agenda>> agendaPasien(String pasienId) => _db
      .collection('agenda')
      .where('puskesmas_id', isEqualTo: user.puskesmasId)
      .where('pasien_id', isEqualTo: pasienId)
      .snapshots(includeMetadataChanges: true)
      .map(_agendaPetugas);

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