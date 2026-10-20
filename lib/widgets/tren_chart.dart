import 'package:flutter/material.dart';

import '../models/pemeriksaan.dart';
import '../theme.dart';
import 'common.dart';

/// Grafik garis hasil pemeriksaan selama [hari] hari terakhir (digambar sendiri,
/// tanpa paket tambahan). Titik diberi warna sesuai status hasil.
class TrenChart extends StatelessWidget {
  final List<Pemeriksaan> data;
  final int hari;
  const TrenChart({super.key, required this.data, this.hari = 30});

  @override
  Widget build(BuildContext context) {
    final sekarang = DateTime.now();
    final awal = sekarang.subtract(Duration(days: hari));
    var pts = data.where((e) => !e.waktu.isBefore(awal)).toList()
      ..sort((a, b) => a.waktu.compareTo(b.waktu));
    if (pts.isEmpty) return const SizedBox.shrink();

    // Satuan bisa berbeda antar dokumen; pakai satuan pemeriksaan terbaru saja.
    final satuan = pts.last.satuan;
    pts = pts.where((e) => e.satuan == satuan).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tren $hari hari terakhir',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        const SizedBox(height: 2),
        Text('${pts.length} pemeriksaan • satuan $satuan',
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(painter: _TrenPainter(pts, awal, sekarang, satuan)),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(fmtTanggalPendek(awal),
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          Text(fmtTanggalPendek(sekarang),
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      ]),
    );
  }
}

class _TrenPainter extends CustomPainter {
  final List<Pemeriksaan> pts;
  final DateTime awal;
  final DateTime akhir;
  final String satuan;
  _TrenPainter(this.pts, this.awal, this.akhir, this.satuan);

  static const _padKiri = 34.0;
  static const _padAtas = 6.0;
  static const _padBawah = 6.0;

  void _teks(Canvas canvas, String t, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width, pos.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTRB(_padKiri, _padAtas, size.width - 6, size.height - _padBawah);
    final skala = satuan == '%' ? 100.0 : 20.0;
    final maks = pts.map((e) => e.hasil).fold<double>(skala, (a, b) => b > a ? b : a);

    final grid = Paint()
      ..color = const Color(0xFFE3E8EC)
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = area.bottom - area.height * f;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), grid);
      _teks(canvas, (maks * f).toStringAsFixed(0), Offset(area.left - 6, y));
    }

    final totalMs = akhir.difference(awal).inMilliseconds.toDouble();
    Offset titik(Pemeriksaan e) {
      final fx = totalMs <= 0
          ? 1.0
          : (e.waktu.difference(awal).inMilliseconds / totalMs).clamp(0.0, 1.0);
      final fy = (e.hasil / maks).clamp(0.0, 1.0);
      return Offset(area.left + area.width * fx, area.bottom - area.height * fy);
    }

    final garis = Paint()
      ..color = AppColors.teal2
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = titik(pts[i]);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    if (pts.length > 1) canvas.drawPath(path, garis);

    for (final e in pts) {
      final o = titik(e);
      canvas.drawCircle(o, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(o, 4, Paint()..color = statusColor(e.status));
    }
  }

  @override
  bool shouldRepaint(_TrenPainter o) =>
      o.pts != pts || o.awal != awal || o.akhir != akhir || o.satuan != satuan;
}
