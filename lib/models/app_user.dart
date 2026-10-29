/// Cermin dokumen Firestore `users/{uid}`.
class AppUser {
  final String uid;
  final String nama;
  final String email;
  final String role; // 'petugas' | 'orang_tua'
  final String? puskesmasId; // null untuk orang_tua
  final String nohp;
  final String? fcmToken;

  const AppUser({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    required this.nohp,
    this.puskesmasId,
    this.fcmToken,
  });

  bool get isPetugas => role == 'petugas';

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        nama: (m['nama'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        role: (m['role'] ?? 'orang_tua') as String,
        nohp: (m['nohp'] ?? '') as String,
        puskesmasId: m['puskesmas_id'] as String?,
        fcmToken: m['fcm_token'] as String?,
      );
}
