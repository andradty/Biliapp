import 'package:flutter/material.dart';

import '../theme.dart';

/// Splash Screen animasi pembuka sesuai urutan Image 2 -> Image 3 -> Image 4 -> Image 5:
/// 1. Awalnya ikon bulat tetes anak (logo-bilicheck-one) berada tepat di tengah layar dengan breathing lembut.
/// 2. Ikon bergeser halus ke arah kiri kanvas logo penuh.
/// 3. Logo penuh (logo-bilicheck) fade-in menyatu sempurna menggantikan ikon di posisi tengah kanvas.
/// 4. Indikator loading cyan/teal muncul di bawah logo utuh.
class SplashScreen extends StatefulWidget {
  final bool langsung;
  const SplashScreen({super.key, this.langsung = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );

  // Fase 0: Kemunculan awal & scale santai (0.00 -> 0.18)
  late final Animation<double> _initialFade = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
  );
  late final Animation<double> _initialScale = Tween<double>(begin: 0.88, end: 1.0).animate(
    CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOutBack),
    ),
  );

  // Fase 1: Pergeseran ikon dari tengah ke sisi kiri kanvas logo (0.24 -> 0.64)
  late final Animation<double> _slideShift = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.24, 0.64, curve: Curves.easeInOutCubicEmphasized),
  );

  // Fase 2: Cross-fade halus ikon menyatu ke logo penuh (0.42 -> 0.76)
  late final Animation<double> _crossFade = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.42, 0.76, curve: Curves.easeInOutCubic),
  );

  // Fase 3: Munculnya indikator loading bar biru di bawah logo (0.76 -> 1.0)
  late final Animation<double> _loaderFade = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.76, 1.0, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    if (widget.langsung) {
      _anim.value = 1.0;
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _anim.forward();
      });
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(
          children: [
            // Status bar atas sesuai desain figma
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top > 0
                    ? MediaQuery.of(context).padding.top * 0.4
                    : 8,
                bottom: 8,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D7C96), Color(0xFF144B66)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '9:41',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_alt, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Icon(Icons.wifi, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Icon(Icons.battery_full, color: Colors.white, size: 15),
                    ],
                  ),
                ],
              ),
            ),

            // Animasi Logo di tengah
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final shift = _slideShift.value; // 0.0 -> 1.0
                    final blend = _crossFade.value;   // 0.0 -> 1.0

                    // Dimensi kanvas logo utuh BiliCheck
                    const fullLogoWidth = 270.0;
                    const fullLogoHeight = 160.0;

                    // Ukuran ikon tunggal
                    const iconWidth = 100.0;

                    // Jarak awal di tengah kanvas -> jarak akhir di posisi kiri logo
                    const centerOffset = (fullLogoWidth - iconWidth) / 2;
                    const finalIconOffset = 4.0;
                    final currentIconX = centerOffset - (centerOffset - finalIconOffset) * shift;

                    return FadeTransition(
                      opacity: _initialFade,
                      child: ScaleTransition(
                        scale: _initialScale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: fullLogoWidth,
                              height: fullLogoHeight,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 1. Logo Penuh (Full Logo) yang memudar masuk di posisi tengah
                                  Opacity(
                                    opacity: blend,
                                    child: Image.asset(
                                      'assets/logo-bilicheck.png',
                                      width: fullLogoWidth,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),

                                  // 2. Ikon Tunggal yang bergeser ke kiri lalu memudar menyatu ke logo penuh
                                  if (blend < 0.99)
                                    Positioned(
                                      left: currentIconX,
                                      child: Opacity(
                                        opacity: (1.0 - blend).clamp(0.0, 1.0),
                                        child: Image.asset(
                                          'assets/logo-bilicheck-one.png',
                                          width: iconWidth,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(
                                            Icons.water_drop_rounded,
                                            size: 70,
                                            color: AppColors.orange2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 38),

                            // 3. Indikator loading biru muncul di bawah logo utuh
                            Opacity(
                              opacity: _loaderFade.value,
                              child: SizedBox(
                                width: 145,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: const LinearProgressIndicator(
                                    minHeight: 4.5,
                                    color: Color(0xFF16A3C4),
                                    backgroundColor: Color(0x3316A3C4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
