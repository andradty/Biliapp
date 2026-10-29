import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'landing_screen.dart';

/// Alur sebelum login: Landing -> Login/Register.
class GuestFlow extends StatefulWidget {
  const GuestFlow({super.key});

  @override
  State<GuestFlow> createState() => _GuestFlowState();
}

class _GuestFlowState extends State<GuestFlow> {
  bool _showAuth = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showAuth, // tombol back di layar login kembali ke landing
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _showAuth = false);
      },
      child: _showAuth
          ? AuthScreen(onBack: () => setState(() => _showAuth = false))
          : LandingScreen(onStart: () => setState(() => _showAuth = true)),
    );
  }
}
