import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pemeriksaan.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HasilScreen extends StatelessWidget {
  final Pemeriksaan p;
  final String namaPasien;
  const HasilScreen({super.key, required this.p, required this.namaPasien});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(p.status);
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          const SubHeader(title: 'Hasil Skrining'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x140B7A93), blurRadius: 18, offset: Offset(0, 8))
                  ],
                ),
                child: Column(children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: Stack(alignment: Alignment.center, children: [
                      CustomPaint(
                        size: const Size(210, 210),
                        painter: _RingPainter((p.hasil / 20).clamp(0.0, 1.0), c),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(fmtKadar(p.hasil),
                            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
                        const Text('mg/dL',
                            style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        StatusBadge(p.status),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text(namaPasien,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${fmtTanggal(p.waktu)} • ${fmtJam(p.waktu)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 24),
              GradientButton(label: 'Selesai', onPressed: () => Navigator.maybePop(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _RingPainter(this.fraction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 18.0;
    final rect = Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = const Color(0xFFDDDDDD);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.fraction != fraction || o.color != color;
}
