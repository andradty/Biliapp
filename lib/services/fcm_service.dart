// ignore_for_file: deprecated_member_use
// getToken/onTokenRefresh/deleteToken ditandai deprecated, tapi masih berfungsi dan
// menghasilkan registration token yang dipakai relay VPS (Admin SDK, field `token`).
// API baru (register/onRegistered) mengeluarkan FID, bukan token, jadi belum dipakai.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registrasi token FCM ke users/{uid}.fcm_token (khusus role orang_tua).
class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  StreamSubscription<String>? _refreshSub;
  String? _uid;

  /// Panggil setelah Orang Tua login.
  Future<void> init(String uid) async {
    if (_uid == uid && _refreshSub != null) return; // sudah aktif
    _uid = uid;

    try {
      // Android 13+ dan iOS: tampilkan dialog izin.
      final settings = await _fcm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] izin notifikasi ditolak');
        return;
      }

      final token = await _fcm.getToken();
      if (token != null) await _simpan(uid, token);

      await _refreshSub?.cancel();
      _refreshSub = _fcm.onTokenRefresh.listen(
        (t) => _simpan(uid, t),
        onError: (e) => debugPrint('[FCM] refresh error: $e'),
      );
    } catch (e) {
      // Jangan sampai gagal FCM mengganggu aplikasi.
      debugPrint('[FCM] init gagal: $e');
    }
  }

  Future<void> _simpan(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcm_token': token});
    debugPrint('[FCM] token tersimpan untuk $uid');
  }

  /// Panggil SEBELUM signOut (Firestore masih butuh auth).
  /// Mencegah HP yang dipakai ganti akun tetap menerima notifikasi akun lama.
  Future<void> lepas() async {
    final uid = _uid;
    await _refreshSub?.cancel();
    _refreshSub = null;
    _uid = null;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({'fcm_token': null});
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('[FCM] lepas gagal: $e');
    }
  }
}