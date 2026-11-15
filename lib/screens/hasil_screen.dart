import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pasien.dart';
import '../models/pemeriksaan.dart';
import '../services/pdf_service.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/edukasi_card.dart';

class HasilScreen extends StatelessWidget {
  final Pemeriksaan p;
  final String namaPasien;

  /// Diisi khusus untuk Petugas; tanpa ini tombol Batalkan tidak muncul.
  final DataService? svc;

  /// Opsional; bila ada, PDF memuat data lengkap pasien.
  final Pasien? pasien;
  const HasilScreen(
      {super.key, required this.p, required this.namaPasien, this.svc, this.pasien});

  Future<void> _unduhPdf(BuildContext context) =>
      PdfService.unduhHasil(context, p, namaPasien, pasien: pasien);

  bool get _bisaBatal => svc != null && svc!.user.isPetugas && !p.dibatalkan && !p.pending;

  Future<void> _batalkan(BuildContext context) async {
    final alasan = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogBatal(),
    );
    if (alasan == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Tidak di-await agar tetap jalan offline.
    svc!
        .batalkanPemeriksaan(p.id, alasan)
        .catchError((e) => messenger.showSnackBar(SnackBar(content: Text('Gagal membatalkan: $e'))));
    messenger.showSnackBar(const SnackBar(content: Text('Pemeriksaan dibatalkan.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = p.dibatalkan ? AppColors.muted : AppColors.teal;
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
                        painter: _RingPainter((p.hasil / p.skalaMaks).clamp(0.0, 1.0), c),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(fmtKadar(p.hasil),
                            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
                        Text(p.satuan,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        if (p.dibatalkan) const BadgeDibatalkan(),
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
              const SizedBox(height: 16),
              if (p.dibatalkan)
                _BannerBatal(alasan: p.alasanBatal)
              else
                const EdukasiCard(),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _unduhPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Unduh PDF'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 12),
              GradientButton(label: 'Selesai', onPressed: () => Navigator.maybePop(context)),
              if (_bisaBatal) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _batalkan(context),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Batalkan pemeriksaan ini'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFC62828)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BannerBatal extends StatelessWidget {
  final String? alasan;
  const _BannerBatal({this.alasan});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.block, color: Color(0xFFC62828)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pemeriksaan ini dibatalkan oleh petugas karena kesalahan input dan '
              'tidak dipakai sebagai acuan.'
              '${(alasan ?? '').isEmpty ? '' : '\nAlasan: $alasan'}',
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ]),
      );
}

class _DialogBatal extends StatefulWidget {
  const _DialogBatal();

  @override
  State<_DialogBatal> createState() => _DialogBatalState();
}

class _DialogBatalState extends State<_DialogBatal> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _c.text.trim().length >= 5;
    return AlertDialog(
      title: const Text('Batalkan pemeriksaan?'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
            'Data asli tetap tersimpan sebagai jejak, tetapi tidak dihitung di ringkasan '
            'dan tren. Pembatalan tidak dapat diurungkan; input ulang jika perlu.',
            style: TextStyle(fontSize: 13, height: 1.4)),
        const SizedBox(height: 12),
        TextField(
          controller: _c,
          maxLength: 200,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
              labelText: 'Alasan (min. 5 karakter)', border: OutlineInputBorder()),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
          onPressed: ok ? () => Navigator.pop(context, _c.text.trim()) : null,
          child: const Text('Batalkan'),
        ),
      ],
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