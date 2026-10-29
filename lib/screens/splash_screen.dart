import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// Layar pembuka: logo BiliCheck berdenyut pelan dengan loader di bawahnya.
///
/// Ringan untuk HP lama: animasi dibungkus RepaintBoundary supaya logo vektor
/// tidak digambar ulang tiap frame, dan hanya memakai transform/opacity.
/// [langsung] = true melewati fade-in awal (dipakai saat splash dipanggil ulang
/// di tengah aplikasi agar tidak berkedip).
class SplashScreen extends StatefulWidget {
  final bool langsung;
  const SplashScreen({super.key, this.langsung = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _denyut =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
        ..repeat(reverse: true);
  late final Animation<double> _scale = Tween(begin: 0.96, end: 1.04)
      .animate(CurvedAnimation(parent: _denyut, curve: Curves.easeInOut));

  late final AnimationController _muncul = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: widget.langsung ? 1 : 0,
  )..forward();

  @override
  void dispose() {
    _denyut.dispose();
    _muncul.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Center(
          child: FadeTransition(
            opacity: _muncul,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              RepaintBoundary(
                child: ScaleTransition(
                  scale: _scale,
                  child: SvgPicture.asset('assets/logo.svg', height: 120),
                ),
              ),
              const SizedBox(height: 40),
              RepaintBoundary(
                child: SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: const LinearProgressIndicator(
                      minHeight: 5,
                      color: AppColors.teal2,
                      backgroundColor: Color(0x55FFFFFF),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
