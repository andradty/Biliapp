import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'screens/guest_flow.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // runApp LANGSUNG (tanpa await Firebase) agar frame pertama = splash,
  // bukan layar hitam bawaan sistem selama Firebase menyala.
  runApp(const BiliCheckApp());
}

class BiliCheckApp extends StatelessWidget {
  const BiliCheckApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BiliCheck',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Boot(),
      );
}

/// Splash minimal ~1,8 detik sambil Firebase dinyalakan dan status login dibaca.
/// AuthGate baru dibangun setelah semuanya siap, jadi tidak ada beban build
/// landing page yang menumpuk di bawah animasi splash.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  late Future<void> _siap = _mulai();

  Future<void> _mulai() async {
    final minimal = Future<void>.delayed(const Duration(milliseconds: 5000));
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.authStateChanges().first;
    await minimal;
  }

  void _ulang() => setState(() => _siap = _mulai());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _siap,
      builder: (context, snap) {
        final Widget isi;
        if (snap.hasError) {
          isi = _GagalBoot(key: const ValueKey('gagal'), error: snap.error!, onUlang: _ulang);
        } else if (snap.connectionState == ConnectionState.done) {
          isi = const AuthGate(key: ValueKey('app'));
        } else {
          isi = const SplashScreen(key: ValueKey('splash'));
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: isi,
        );
      },
    );
  }
}

class _GagalBoot extends StatelessWidget {
  final Object error;
  final VoidCallback onUlang;
  const _GagalBoot({super.key, required this.error, required this.onUlang});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.teal),
              const SizedBox(height: 16),
              const Text('Aplikasi gagal dimulai',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('$error',
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 20),
              FilledButton(onPressed: onUlang, child: const Text('Coba lagi')),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Login -> baca users/{uid} -> arahkan sesuai role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // GlobalKey menjaga state GuestFlow/AuthScreen (spinner/pesan error) saat register,
  // ketika akun Auth sudah ada tetapi dokumen users belum tertulis.
  static final _guestKey = GlobalKey();
  static final _svc = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _svc.authChanges,
      // Status login sudah dibaca di _Boot, jadi tidak ada keadaan "menunggu" di sini.
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return GuestFlow(key: _guestKey);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _svc.profil(user.uid),
          builder: (context, ps) {
            final doc = ps.data;
            // Profil belum terbaca: tahan di loading (tanpa kedip landing page).
            if (doc == null && ps.connectionState == ConnectionState.waiting) {
              return const SplashScreen(langsung: true);
            }
            if (doc == null || !doc.exists) return GuestFlow(key: _guestKey);
            return HomeScreen(user: AppUser.fromMap(user.uid, doc.data()!));
          },
        );
      },
    );
  }
}
