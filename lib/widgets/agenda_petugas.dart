import 'package:flutter/material.dart';

import '../models/agenda.dart';
import '../models/pasien.dart';
import '../services/data_service.dart';
import '../theme.dart';
import 'common.dart';

/// Bagian "Jadwal Pemeriksaan" di Riwayat Pasien (khusus Petugas).
class AgendaPasienSection extends StatefulWidget {
  final DataService svc;
  final Pasien pasien;
  const AgendaPasienSection({super.key, required this.svc, required this.pasien});

  @override
  State<AgendaPasienSection> createState() => _AgendaPasienSectionState();
}

class _AgendaPasienSectionState extends State<AgendaPasienSection> {
  late final Stream<List<Agenda>> _stream = widget.svc.agendaPasien(widget.pasien.id);

  Future<void> _jadwalkan() async {
    final hasil = await showDialog<({DateTime tanggal, String catatan})>(
      context: context,
      builder: (_) => const _DialogJadwal(),
    );
    if (hasil == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    widget.svc
        .jadwalkan(pasien: widget.pasien, tanggal: hasil.tanggal, catatan: hasil.catatan)
        .catchError((e) =>
            messenger.showSnackBar(SnackBar(content: Text('Gagal menjadwalkan: $e'))));
    messenger.showSnackBar(const SnackBar(content: Text('Jadwal pemeriksaan disimpan.')));
  }

  Future<void> _batalkan(Agenda a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        scrollable: true,
        title: Text(a.terlewat ? 'Hapus jadwal terlewat?' : 'Batalkan jadwal?'),
        content: Text(a.terlewat
            ? 'Jadwal ${fmtTanggal(a.tanggal)} yang terlewat akan dihapus dari daftar.'
            : 'Jadwal ${fmtTanggal(a.tanggal)} akan dibatalkan dan hilang dari aplikasi Orang Tua.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Kembali')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(a.terlewat ? 'Hapus' : 'Batalkan jadwal')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    widget.svc.batalkanAgenda(a.id).catchError(
        (e) => messenger.showSnackBar(SnackBar(content: Text('Gagal membatalkan: $e'))));
  }

  Future<void> _jadwalkanUlang(Agenda lama) async {
    final hasil = await showDialog<({DateTime tanggal, String catatan})>(
      context: context,
      builder: (_) => const _DialogJadwal(),
    );
    if (hasil == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    widget.svc
        .jadwalkan(pasien: widget.pasien, tanggal: hasil.tanggal, catatan: hasil.catatan)
        .then((_) => widget.svc.batalkanAgenda(lama.id))
        .catchError((e) =>
            messenger.showSnackBar(SnackBar(content: Text('Gagal menjadwalkan ulang: $e'))));
    messenger.showSnackBar(const SnackBar(content: Text('Jadwal diganti dengan tanggal baru.')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('JADWAL PEMERIKSAAN'),
      StreamBuilder<List<Agenda>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return ErrorBox(snap.error!);
          final list = snap.data ?? <Agenda>[];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final a in list)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                decoration:
                    BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Icon(a.terlewat ? Icons.event_busy : Icons.event,
                      color: a.terlewat ? Colors.red : AppColors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                          a.terlewat
                              ? '${fmtTanggal(a.tanggal)} • Terlewat ${a.hariTerlewat} hari'
                              : '${fmtTanggal(a.tanggal)} • ${a.hariLagiLabel}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: a.terlewat ? Colors.red : null)),
                      if (a.catatan.isNotEmpty)
                        Text(a.catatan,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                    ]),
                  ),
                  if (a.terlewat)
                    IconButton(
                      tooltip: 'Jadwalkan ulang',
                      icon: const Icon(Icons.event_repeat, size: 20),
                      onPressed: a.pending ? null : () => _jadwalkanUlang(a),
                    ),
                  IconButton(
                    tooltip: a.terlewat ? 'Hapus jadwal terlewat' : 'Batalkan jadwal',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: a.pending ? null : () => _batalkan(a),
                  ),
                ]),
              ),
            if (widget.pasien.orangTuaId == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Pasien ini belum ditautkan ke akun Orang Tua, jadi jadwal belum akan tampil di aplikasi Orang Tua.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _jadwalkan,
              icon: const Icon(Icons.add),
              label: const Text('Jadwalkan pemeriksaan'),
            ),
          ]);
        },
      ),
    ]);
  }
}

class _DialogJadwal extends StatefulWidget {
  const _DialogJadwal();

  @override
  State<_DialogJadwal> createState() => _DialogJadwalState();
}

class _DialogJadwalState extends State<_DialogJadwal> {
  DateTime? _tanggal;
  final _catatan = TextEditingController();

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _pilih() async {
    final n = DateTime.now();
    final t = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? n.add(const Duration(days: 1)),
      firstDate: DateTime(n.year, n.month, n.day),
      lastDate: n.add(const Duration(days: 365)),
    );
    if (t != null) setState(() => _tanggal = t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Jadwalkan pemeriksaan'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        OutlinedButton.icon(
          onPressed: _pilih,
          icon: const Icon(Icons.calendar_month),
          label: Text(_tanggal == null ? 'Pilih tanggal' : fmtTanggal(_tanggal!)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _catatan,
          maxLength: 200,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'mis. Pemeriksaan ulang, bawa buku KIA',
              border: OutlineInputBorder()),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _tanggal == null
              ? null
              : () => Navigator.pop(context, (tanggal: _tanggal!, catatan: _catatan.text.trim())),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
