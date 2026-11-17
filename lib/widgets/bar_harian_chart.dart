import 'package:flutter/material.dart';

import '../models/pemeriksaan.dart';
import '../theme.dart';
import 'common.dart';

enum _Skala { harian, mingguan, bulanan }

class _Kolom {
  final String label;
  final int jumlah;
  const _Kolom(this.label, this.jumlah);
}

/// Diagram batang jumlah pemeriksaan, dipisah per Hari (14 hari), Minggu
/// (8 minggu, Senin-Minggu) dan Bulan (6 bulan). Setiap batang diberi angka
/// dan label sumbu-X, serta garis bantu di tiap nilai sumbu-Y.
class BarHarianChart extends StatefulWidget {
  final List<Pemeriksaan> data;
  const BarHarianChart({super.key, required this.data});

  @override
  State<BarHarianChart> createState() => _BarHarianChartState();
}

class _BarHarianChartState extends State<BarHarianChart> {
  _Skala _skala = _Skala.harian;

  static DateTime _hari(DateTime d) => DateTime(d.year, d.month, d.day);

  List<_Kolom> _hitung() {
    final hariIni = _hari(DateTime.now());
    switch (_skala) {
      case _Skala.harian:
        final awal = hariIni.subtract(const Duration(days: 13));
        final k = List<int>.filled(14, 0);
        for (final e in widget.data) {
          final i = _hari(e.waktu).difference(awal).inDays;
          if (i >= 0 && i < 14) k[i]++;
        }
        return [
          for (var i = 0; i < 14; i++)
            _Kolom('${awal.add(Duration(days: i)).day}', k[i]),
        ];
      case _Skala.mingguan:
        final senin = hariIni.subtract(Duration(days: hariIni.weekday - 1));
        final awal = senin.subtract(const Duration(days: 7 * 7));
        final k = List<int>.filled(8, 0);
        for (final e in widget.data) {
          final i = _hari(e.waktu).difference(awal).inDays ~/ 7;
          if (!_hari(e.waktu).isBefore(awal) && i >= 0 && i < 8) k[i]++;
        }
        return [
          for (var i = 0; i < 8; i++)
            _Kolom(fmtTanggalPendek(awal.add(Duration(days: 7 * i))), k[i]),
        ];
      case _Skala.bulanan:
        final n = DateTime.now();
        final k = List<int>.filled(6, 0);
        for (final e in widget.data) {
          final i = 5 - ((n.year - e.waktu.year) * 12 + n.month - e.waktu.month);
          if (i >= 0 && i < 6) k[i]++;
        }
        return [
          for (var i = 0; i < 6; i++)
            _Kolom(
                fmtTanggalPendek(DateTime(n.year, n.month - (5 - i), 1)).split(' ').last, k[i]),
        ];
    }
  }

  Widget _chip(_Skala s, String teks) {
    final aktif = _skala == s;
    return GestureDetector(
      onTap: () => setState(() => _skala = s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: aktif ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: aktif ? AppColors.teal : const Color(0xFFDCE4EC)),
        ),
        child: Text(teks,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: aktif ? Colors.white : AppColors.muted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kolom = _hitung();
    final total = kolom.fold<int>(0, (a, b) => a + b.jumlah);
    final ket = switch (_skala) {
      _Skala.harian => '14 hari terakhir',
      _Skala.mingguan => '8 minggu terakhir',
      _Skala.bulanan => '6 bulan terakhir',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Jumlah pemeriksaan',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _chip(_Skala.harian, 'Hari'),
          _chip(_Skala.mingguan, 'Minggu'),
          _chip(_Skala.bulanan, 'Bulan'),
        ]),
        const SizedBox(height: 8),
        Text('$total pemeriksaan • $ket',
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 8),
        if (total == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Belum ada pemeriksaan pada rentang ini.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
          )
        else
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(painter: _BarPainter(kolom)),
          ),
      ]),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<_Kolom> kolom;
  _BarPainter(this.kolom);

  void _teks(Canvas canvas, String t, Offset pos,
      {double ukuran = 10,
      Color warna = AppColors.muted,
      FontWeight berat = FontWeight.w400,
      _Rata rata = _Rata.kanan}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: ukuran, color: warna, fontWeight: berat)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (rata) {
      _Rata.kanan => pos.dx - tp.width,
      _Rata.tengah => pos.dx - tp.width / 2,
    };
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padKiri = 26.0;
    const tinggiLabelX = 16.0;
    const padAtas = 14.0; // ruang untuk angka di atas batang tertinggi
    final area = Rect.fromLTRB(padKiri, padAtas, size.width, size.height - tinggiLabelX);

    var maks = 1;
    for (final k in kolom) {
      if (k.jumlah > maks) maks = k.jumlah;
    }
    // Garis bantu di nilai bulat, maksimal 5 garis.
    final langkah = (maks / 4).ceil().clamp(1, 1000000).toInt();
    final atas = ((maks + langkah - 1) ~/ langkah) * langkah;

    final grid = Paint()
      ..color = const Color(0xFFE3E8EC)
      ..strokeWidth = 1;
    for (var v = 0; v <= atas; v += langkah) {
      final y = area.bottom - area.height * v / atas;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), grid);
      _teks(canvas, '$v', Offset(area.left - 6, y));
    }

    final lebarSlot = area.width / kolom.length;
    final lebarBar = (lebarSlot * 0.58).clamp(4.0, 28.0).toDouble();
    final padat = lebarSlot < 22; // label sumbu-X rapat -> perkecil font

    for (var i = 0; i < kolom.length; i++) {
      final cx = area.left + lebarSlot * i + lebarSlot / 2;
      final h = area.height * kolom[i].jumlah / atas;
      if (h > 0) {
        final r = RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - lebarBar / 2, area.bottom - h, lebarBar, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(r, Paint()..color = AppColors.teal2);
        _teks(canvas, '${kolom[i].jumlah}', Offset(cx, area.bottom - h - 7),
            ukuran: 10.5, warna: AppColors.ink, berat: FontWeight.w700, rata: _Rata.tengah);
      }
      _teks(canvas, kolom[i].label, Offset(cx, size.height - tinggiLabelX / 2 + 1),
          ukuran: padat ? 9 : 10, rata: _Rata.tengah);
    }
  }

  @override
  bool shouldRepaint(_BarPainter o) => o.kolom != kolom;
}

enum _Rata { kanan, tengah }
