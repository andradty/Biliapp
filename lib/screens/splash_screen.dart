import 'package:flutter/material.dart';

import '../theme.dart';

/// Opening App Animation:
/// 1. Awalnya ikon bulat tetes anak (logo-bilicheck-one) berada tepat di tengah layar dengan breathing lembut.
/// 2. Ikon bergeser halus ke arah kiri kanvas logo penuh.
/// 3. Logo penuh (logo-bilicheck) fade-in menyatu sempurna menggantikan ikon di posisi tengah kanvas.
/// 4. Indikator loading biru tipis minimalis muncul di bawah logo utuh.
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
    duration: const Duration(milliseconds: 2600),
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

  // Fase 1: Pergeseran ikon dari tengah ke sisi kiri kanvas logo (0.24 -> 0.62)
  late final Animation<double> _slideShift = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.24, 0.62, curve: Curves.easeInOutCubicEmphasized),
  );

  // Fase 2: Cross-fade halus ikon menyatu ke logo penuh (0.40 -> 0.72)
  late final Animation<double> _crossFade = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.40, 0.72, curve: Curves.easeInOutCubic),
  );

  // Fase 3: Munculnya indikator loading bar (0.70 -> 0.82)
  late final Animation<double> _loaderFade = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.70, 0.82, curve: Curves.easeIn),
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
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: bgGradient,
        child: Center(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final shift = _slideShift.value; // 0.0 -> 1.0
              final blend = _crossFade.value;   // 0.0 -> 1.0

              // Dimensi kanvas logo utuh BiliCheck
              const fullLogoWidth = 280.0;
              const fullLogoHeight = 160.0;

              // Ukuran ikon tunggal
              const iconWidth = 104.0;

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
                            // 1. Logo Penuh (Full Logo asli resolusi tajam)
                            Opacity(
                              opacity: blend,
                              child: Image.asset(
                                'assets/logo-bilicheck.png',
                                width: fullLogoWidth,
                                fit: BoxFit.contain,
                              ),
                            ),

                            // 2. Ikon Tunggal (logo-bilicheck-one) bergeser ke kiri lalu menyatu ke logo penuh
                            if (blend < 0.99)
                              Positioned(
                                left: currentIconX,
                                child: Opacity(
                                  opacity: (1.0 - blend).clamp(0.0, 1.0),
                                  child: Image.asset(
                                    'assets/logo-bilicheck-one.png',
                                    width: iconWidth,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 38),

                      // 3. Loading bar biru tipis bersih dan minimalis
                      Opacity(
                        opacity: _loaderFade.value,
                        child: SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: const LinearProgressIndicator(
                              minHeight: 4,
                              color: AppColors.teal2,
                              backgroundColor: Color(0x330B7A93),
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
    );
  }
}
