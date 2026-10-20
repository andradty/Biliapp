import 'package:flutter/material.dart';

import '../models/pemeriksaan.dart';
import '../theme.dart';
import 'common.dart';

/// Diagram batang: jumlah pemeriksaan per hari selama [hari] hari terakhir,
/// ditumpuk per status (normal / waspada / kritis).
class BarHarianChart extends StatelessWidget {
  final List<Pemeriksaan> data;
  final int hari;
  const BarHarianChart({super.key, required this.data, this.hari = 30});

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    // tiap elemen: [normal, waspada, kritis]
    final kolom = List.generate(hari, (_) => [0, 0, 0]);
    for (final e in data) {
      final d = DateTime(e.waktu.year, e.waktu.month, e.waktu.day);
      final idx = hari - 1 - hariIni.difference(d).inDays;
      if (idx < 0 || idx >= hari) continue;
      final j = e.status == 'normal' ? 0 : (e.status == 'waspada' ? 1 : (e.status == 'kritis' ? 2 : -1));
      if (j >= 0) kolom[idx][j]++;
    }
    final adaData = kolom.any((k) => k[0] + k[1] + k[2] > 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pemeriksaan per hari',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        const SizedBox(height: 10),
        if (!adaData)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Belum ada pemeriksaan dalam 30 hari terakhir.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
          )
        else ...[
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(painter: _BarPainter(kolom)),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(fmtTanggalPendek(hariIni.subtract(Duration(days: hari - 1))),
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            Text(fmtTanggalPendek(hariIni),
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ],
      ]),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<List<int>> kolom;
  _BarPainter(this.kolom);

  void _teks(Canvas canvas, String t, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width, pos.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padKiri = 26.0;
    final area = Rect.fromLTRB(padKiri, 6, size.width, size.height - 2);
    var maks = 1;
    for (final k in kolom) {
      final t = k[0] + k[1] + k[2];
      if (t > maks) maks = t;
    }

    final grid = Paint()
      ..color = const Color(0xFFE3E8EC)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(area.left, area.bottom), Offset(area.right, area.bottom), grid);
    canvas.drawLine(Offset(area.left, area.top), Offset(area.right, area.top), grid);
    _teks(canvas, '0', Offset(area.left - 6, area.bottom));
    _teks(canvas, '$maks', Offset(area.left - 6, area.top));

    final warna = [statusColor('normal'), statusColor('waspada'), statusColor('kritis')];
    final lebarSlot = area.width / kolom.length;
    final lebarBar = lebarSlot * 0.65;
    final satuanTinggi = area.height / maks;

    for (var i = 0; i < kolom.length; i++) {
      final x = area.left + lebarSlot * i + (lebarSlot - lebarBar) / 2;
      var y = area.bottom;
      for (var j = 0; j < 3; j++) {
        final h = kolom[i][j] * satuanTinggi;
        if (h <= 0) continue;
        canvas.drawRect(Rect.fromLTWH(x, y - h, lebarBar, h), Paint()..color = warna[j]);
        y -= h;
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter o) => o.kolom != kolom;
}
