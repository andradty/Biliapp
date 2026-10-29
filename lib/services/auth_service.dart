import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'fcm_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authChanges => _auth.authStateChanges();

  Stream<DocumentSnapshot<Map<String, dynamic>>> profil(String uid) =>
      _db.collection('users').doc(uid).snapshots();

  Future<void> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    // Akun harus punya dokumen users/{uid}, kalau tidak role tidak diketahui.
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw const AuthException(
          'Profil pengguna tidak ditemukan. Hubungi petugas Puskesmas.');
    }
  }

  /// Registrasi mandiri: selalu role orang_tua, puskesmas_id null.
  Future<void> register({
    required String nama,
    required String nohp,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = cred.user!;
    try {
      await _db.collection('users').doc(user.uid).set({
        'nama': nama.trim(),
        'email': email.trim(),
        'role': 'orang_tua',
        'puskesmas_id': null,
        'nohp': nohp.trim(),
        'fcm_token': null,
      });
    } catch (e) {
      await user.delete(); // jangan sisakan akun tanpa profil
      rethrow;
    }
  }

  /// Ubah nama dan nomor HP sendiri (rules mengizinkan nama, nohp, fcm_token).
  /// Tidak perlu di-await agar tetap jalan offline.
  Future<void> ubahProfil({required String uid, required String nama, required String nohp}) =>
      _db.collection('users').doc(uid).update({'nama': nama.trim(), 'nohp': nohp.trim()});

  /// Ganti password: verifikasi ulang dengan password lama, lalu perbarui.
  Future<void> gantiPassword({required String lama, required String baru}) async {
    final u = _auth.currentUser;
    if (u == null || u.email == null) {
      throw const AuthException('Sesi login tidak ditemukan. Silakan login ulang.');
    }
    await u.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: u.email!, password: lama));
    await u.updatePassword(baru);
  }

  /// Kirim email reset password. Firebase tidak membocorkan apakah email terdaftar.
  Future<void> kirimResetPassword(String email) async {
    await _auth.setLanguageCode('id');
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// True kalau kegagalan login karena email/password salah.
  static bool salahKredensial(Object e) =>
      e is FirebaseAuthException &&
      (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found');

  Future<void> logout() async {
    await FcmService.instance.lepas();
    await _auth.signOut();
  }

  static String pesanError(Object e) {
    if (e is AuthException) return e.message;
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Email atau password salah.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar.';
        case 'weak-password':
          return 'Password terlalu lemah (minimal 6 karakter).';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
      }
      return 'Autentikasi gagal (${e.code}).';
    }
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Ditolak security rules Firestore. Periksa aturan koleksi users.';
    }
    return 'Terjadi kesalahan: $e';
  }
}