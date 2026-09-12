// lib/screens/landing_page.dart
import 'package:flutter/material.dart';

/// Landing page pertama yang dilihat petugas Puskesmas saat membuka app.
/// Belum terhubung ke autentikasi apapun — nanti diganti flow Login
/// sebelum masuk ke Dashboard.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const Color _primaryColor = Color(0xFF0B6E4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / ikon placeholder — konsisten dengan gaya icon-box
              // di device_setup_screen.dart (kotak putih, border tipis)
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    size: 40,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'BILINOVA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Skrining Bilirubin Non-Invasif untuk Bayi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Pantau kadar bilirubin bayi tanpa pengambilan sampel darah, '
                'terintegrasi langsung dengan perangkat sensor di Puskesmas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {
                  // Sementara langsung ke Dashboard — ganti ke '/login'
                  // kalau flow autentikasi sudah dibuat.
                  Navigator.of(context).pushReplacementNamed('/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Mulai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Kerja sama dengan Puskesmas • Sekolah Vokasi IPB University',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}