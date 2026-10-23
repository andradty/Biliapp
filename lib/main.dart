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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

/// Splash minimal ~2 detik di atas AuthGate, lalu memudar.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  bool _tampil = true;
  bool _hilang = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _tampil = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const AuthGate(),
      if (!_hilang)
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_tampil,
            child: AnimatedOpacity(
              opacity: _tampil ? 1 : 0,
              duration: const Duration(milliseconds: 450),
              onEnd: () {
                if (!_tampil && mounted) setState(() => _hilang = true);
              },
              child: const SplashScreen(),
            ),
          ),
        ),
    ]);
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
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snap.data;
        if (user == null) return GuestFlow(key: _guestKey);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _svc.profil(user.uid),
          builder: (context, ps) {
            final doc = ps.data;
            if (doc == null || !doc.exists) return GuestFlow(key: _guestKey);
            return HomeScreen(user: AppUser.fromMap(user.uid, doc.data()!));
          },
        );
      },
    );
  }
}
