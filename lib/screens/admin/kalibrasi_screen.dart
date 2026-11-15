import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/kalibrasi.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// FR09: daftar kalibrasi alat, catat kalibrasi baru, dan pilih kalibrasi aktif.
class KalibrasiScreen extends StatefulWidget {
  final DataService svc;
  const KalibrasiScreen({super.key, required this.svc});

  @override
  State<KalibrasiScreen> createState() => _KalibrasiScreenState();
}

class _KalibrasiScreenState extends State<KalibrasiScreen> {
  late final Stream<DeviceInfo?> _dev = widget.svc.deviceSaya();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          const SubHeader(title: 'Kalibrasi Alat'),
          Expanded(
            child: StreamBuilder<DeviceInfo?>(
              stream: _dev,
              builder: (context, snap) {
                if (snap.hasError) return SingleChildScrollView(child: ErrorBox(snap.error!));
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final d = snap.data;
                if (d == null) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Belum ada alat terdaftar untuk Puskesmas ini.',
                        style: TextStyle(color: AppColors.muted)),
                  );
                }
                return _DaftarKalibrasi(svc: widget.svc, device: d);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _DaftarKalibrasi extends StatefulWidget {
  final DataService svc;
  final DeviceInfo device;
  const _DaftarKalibrasi({required this.svc, required this.device});

  @override
  State<_DaftarKalibrasi> createState() => _DaftarKalibrasiState();
}

class _DaftarKalibrasiState extends State<_DaftarKalibrasi> {
  late final Stream<List<Kalibrasi>> _daftar = widget.svc.daftarKalibrasi(widget.device.id);

  void _baru() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FormKalibrasi(svc: widget.svc, device: widget.device),
      );

  Future<void> _aktifkan(Kalibrasi k) async {
    final messenger = ScaffoldMessenger.of(context);
    final ya = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Jadikan kalibrasi aktif?'),
        content: Text('Pemeriksaan berikutnya memakai kalibrasi ${k.id}. '
            'Pastikan alat juga memakai koefisien ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Aktifkan')),
        ],
      ),
    );
    if (ya != true) return;
    // Tidak di-await: saat offline masuk antrean lokal.
    widget.svc.aktifkanKalibrasi(widget.device.id, k).catchError(
        (e) => messenger.showSnackBar(SnackBar(content: Text('Gagal mengaktifkan: $e'))));
    messenger.showSnackBar(SnackBar(content: Text('Kalibrasi ${k.id} dijadikan aktif.')));
  }

  static String _n(double v) => v.toString();

  Widget _baris(String label, String nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted))),
          Expanded(
              child: Text(nilai,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _kartu(Kalibrasi k) {
    final aktif = k.id == widget.device.kalibrasiAktifId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: aktif ? Border.all(color: AppColors.ok, width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(k.id,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          if (aktif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.ok.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999)),
              child: Text('Aktif',
                  style: TextStyle(
                      color: AppColors.ok, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 6),
        _baris(
            'Tanggal',
            k.tanggal == null
                ? '-'
                : '${fmtTanggal(k.tanggal!)} ${fmtJam(k.tanggal!)}'),
        _baris('Koefisien a / b', '${_n(k.koefisienA)} / ${_n(k.koefisienB)}'),
        _baris('Intensitas awal (I0)', '${_n(k.nilaiLux)} lux'),
        _baris('Alpha / Diameter', '${_n(k.alpha)} / ${_n(k.diameter)} cm'),
        _baris('Rumus', k.rumusVersi),
        if (k.catatan != null && k.catatan!.isNotEmpty) _baris('Catatan', k.catatan!),
        if (!aktif)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () => _aktifkan(k), child: const Text('Jadikan aktif')),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF1DC), borderRadius: BorderRadius.circular(12)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.orange2),
          SizedBox(width: 8),
          Expanded(
            child: Text(
                'Kalibrasi tidak bisa diubah atau dihapus. Untuk memperbaiki nilai, '
                'catat kalibrasi baru lalu jadikan aktif.',
                style: TextStyle(fontSize: 12.5)),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      GradientButton(label: 'Catat Kalibrasi Baru', onPressed: _baru),
      const SectionLabel('Riwayat Kalibrasi'),
      StreamBuilder<List<Kalibrasi>>(
        stream: _daftar,
        builder: (context, snap) {
          if (snap.hasError) return ErrorBox(snap.error!);
          if (!snap.hasData) {
            return const Padding(
                padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Text('Belum ada kalibrasi. Catat kalibrasi pertama.',
                style: TextStyle(color: AppColors.muted, fontSize: 13));
          }
          return Column(children: [for (final k in list) _kartu(k)]);
        },
      ),
    ]);
  }
}

class _FormKalibrasi extends StatefulWidget {
  final DataService svc;
  final DeviceInfo device;
  const _FormKalibrasi({required this.svc, required this.device});

  @override
  State<_FormKalibrasi> createState() => _FormKalibrasiState();
}

class _FormKalibrasiState extends State<_FormKalibrasi> {
  final _form = GlobalKey<FormState>();
  final _i0 = TextEditingController();
  final _a = TextEditingController();
  final _b = TextEditingController();
  final _alpha = TextEditingController();
  final _diameter = TextEditingController();
  final _catatan = TextEditingController();
  bool _aktifkan = true;

  @override
  void dispose() {
    for (final c in [_i0, _a, _b, _alpha, _diameter, _catatan]) {
      c.dispose();
    }
    super.dispose();
  }

  static double? _baca(String? v) =>
      double.tryParse((v ?? '').trim().replaceAll(',', '.'));

  String? _angka(String? v, {bool positif = false}) {
    final n = _baca(v);
    if (n == null) return 'Isi dengan angka';
    if (positif && n <= 0) return 'Harus lebih dari 0';
    return null;
  }

  void _simpan() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final id = 'kal_${DateTime.now().millisecondsSinceEpoch}';
    final k = Kalibrasi(
      id: id,
      deviceId: widget.device.id,
      nilaiLux: _baca(_i0.text)!,
      koefisienA: _baca(_a.text)!,
      koefisienB: _baca(_b.text)!,
      alpha: _baca(_alpha.text)!,
      diameter: _baca(_diameter.text)!,
    );
    void gagal(Object e) =>
        messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan kalibrasi: $e')));

    // Tidak di-await: saat offline masuk antrean lokal.
    widget.svc
        .tambahKalibrasi(
          deviceId: widget.device.id,
          id: id,
          nilaiLux: k.nilaiLux,
          koefisienA: k.koefisienA,
          koefisienB: k.koefisienB,
          alpha: k.alpha,
          diameter: k.diameter,
          catatan: _catatan.text,
        )
        .catchError(gagal);
    if (_aktifkan) {
      widget.svc.aktifkanKalibrasi(widget.device.id, k).catchError(gagal);
    }
    messenger.showSnackBar(SnackBar(
        content: Text(_aktifkan
            ? 'Kalibrasi $id disimpan dan dijadikan aktif.'
            : 'Kalibrasi $id disimpan.')));
    Navigator.pop(context);
  }

  Widget _field(String label, TextEditingController c,
          {String? suffix, bool positif = false, bool signed = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: signed),
          decoration: InputDecoration(
              labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
          validator: (v) => _angka(v, positif: positif),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Catat Kalibrasi Baru',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 4),
              Text('Alat ${widget.device.id} • sensor fotodioda • rumus beer-lambert-v1',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 16),
              _field('Intensitas awal (I0)', _i0, suffix: 'lux', positif: true),
              _field('Koefisien a (slope)', _a, signed: true),
              _field('Koefisien b (intercept)', _b, signed: true),
              _field('Alpha (koefisien absorbsi)', _alpha, positif: true),
              _field('Diameter', _diameter, suffix: 'cm', positif: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: _catatan,
                  maxLength: 200,
                  decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)', border: OutlineInputBorder()),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _aktifkan,
                onChanged: (v) => setState(() => _aktifkan = v),
                title: const Text('Jadikan kalibrasi aktif'),
              ),
              const SizedBox(height: 8),
              GradientButton(label: 'Simpan Kalibrasi', onPressed: _simpan),
            ]),
          ),
        ),
      ),
    );
  }
}
