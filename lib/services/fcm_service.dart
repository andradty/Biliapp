// ignore_for_file: deprecated_member_use
// getToken/onTokenRefresh/deleteToken ditandai deprecated, tapi masih berfungsi dan
// menghasilkan registration token yang dipakai relay VPS (Admin SDK, field `token`).
// API baru (register/onRegistered) mengeluarkan FID, bukan token, jadi belum dipakai.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Registrasi token FCM ke users/{uid}.fcm_token (khusus role orang_tua)
/// dan menampilkan notifikasi saat app sedang dibuka (foreground).
///
/// Notifikasi saat app di background/tertutup ditampilkan sistem Android
/// sendiri, asal pesan dari relay memuat blok `notification` dan
/// `android.notification.channel_id` = 'hasil_pemeriksaan'.
class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  StreamSubscription<String>? _refreshSub;
  String? _uid;

  // ---- Notifikasi foreground ------------------------------------------------

  /// Id channel HARUS sama dengan meta-data
  /// `com.google.firebase.messaging.default_notification_channel_id`
  /// di AndroidManifest dan `channel_id` pada payload relay.
  static const _channel = AndroidNotificationChannel(
    'hasil_pemeriksaan',
    'Hasil Pemeriksaan',
    description: 'Notifikasi hasil pemeriksaan bilirubin',
    importance: Importance.high,
  );

  final _lokal = FlutterLocalNotificationsPlugin();
  bool _lokalSiap = false;
  StreamSubscription<RemoteMessage>? _fgSub;

  /// Buat channel (sekali) dan dengarkan pesan yang masuk saat app dibuka.
  Future<void> _siapkanLokal() async {
    if (!_lokalSiap) {
      await _lokal.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _lokal
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      _lokalSiap = true;
    }

    await _fgSub?.cancel();
    _fgSub = FirebaseMessaging.onMessage.listen(_tampilkan);
  }

  Future<void> _tampilkan(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    try {
      await _lokal.show(
        id: m.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('[FCM] tampilkan notifikasi gagal: $e');
    }
  }

  // ---- Token ------------------------------------------------------------------

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

      await _siapkanLokal();

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
    await _fgSub?.cancel();
    _fgSub = null;
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