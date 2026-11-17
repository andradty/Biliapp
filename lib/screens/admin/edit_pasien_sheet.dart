import 'package:flutter/material.dart';

import '../../models/pasien.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Petugas: koreksi data pasien dan tautkan ke akun Orang Tua (lewat no. HP).
class EditPasienSheet extends StatefulWidget {
  final DataService svc;
  final Pasien pasien;
  const EditPasienSheet({super.key, required this.svc, required this.pasien});

  @override
  State<EditPasienSheet> createState() => _EditPasienSheetState();
}

class _EditPasienSheetState extends State<EditPasienSheet> {
  final _form = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.pasien.nama);
  late final _berat = TextEditingController(text: '${widget.pasien.beratLahir ?? ''}');
  late final _usia = TextEditingController(text: '${widget.pasien.usiaKehamilan ?? ''}');
  late final _alamat = TextEditingController(text: widget.pasien.alamat);
  final _hp = TextEditingController();
  late DateTime? _lahir = widget.pasien.tanggalLahir;
  late String _jk = widget.pasien.jenisKelamin == 'P' ? 'P' : 'L';
  String? _error;

  late String? _ortuId = widget.pasien.orangTuaId;
  String? _namaOrtu;
  bool _menautkan = false;
  bool _ganti = false; // mode ganti orang tua (sudah tertaut)
  String? _errorTaut;

  @override
  void initState() {
    super.initState();
    if (_ortuId != null) _muatNamaOrtu();
  }

  @override
  void dispose() {
    for (final c in [_nama, _berat, _usia, _alamat, _hp]) {
      c.dispose();
    }
    super.dispose();
  }

  void _muatNamaOrtu() {
    widget.svc.namaOrangTua(_ortuId!).then((n) {
      if (mounted) setState(() => _namaOrtu = n);
    }).catchError((Object _) {});
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final awal = DateTime(now.year - 5);
    var init = _lahir ?? now;
    if (init.isBefore(awal)) init = awal;
    if (init.isAfter(now)) init = now;
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: awal,
      lastDate: now,
    );
    if (d != null) setState(() => _lahir = d);
  }

  void _simpan() {
    if (!_form.currentState!.validate()) return;
    if (_lahir == null) {
      setState(() => _error = 'Tanggal lahir wajib diisi');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    // Tidak di-await: saat offline masuk antrean lokal.
    widget.svc
        .ubahPasien(
      widget.pasien,
      nama: _nama.text,
      lahir: _lahir!,
      jenisKelamin: _jk,
      beratLahir: int.parse(_berat.text.trim()),
      usiaKehamilan: int.parse(_usia.text.trim()),
      alamat: _alamat.text,
    )
        .catchError((Object e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan perubahan: $e')));
    });
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Data pasien diperbarui')));
  }

  Future<bool> _konfirmasi(String judul, String isi, String aksi) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        scrollable: true,
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(aksi)),
        ],
      ),
    );
    return ya == true;
  }

  Future<void> _tautkan() async {
    if (_hp.text.trim().isEmpty) {
      setState(() => _errorTaut = 'Isi no. HP Orang Tua');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (_ortuId != null) {
      final ok = await _konfirmasi(
        'Ganti Orang Tua?',
        'Akses ${_namaOrtu ?? 'orang tua saat ini'} ke riwayat dan jadwal bayi ini akan dicabut '
            'dan dipindahkan ke akun baru, termasuk data lama.',
        'Ganti',
      );
      if (!ok) return;
    }
    setState(() {
      _menautkan = true;
      _errorTaut = null;
    });
    try {
      final r = await widget.svc.tautkanOrangTua(widget.pasien, _hp.text);
      if (!mounted) return;
      if (r == null) {
        setState(() {
          _menautkan = false;
          _errorTaut = 'Orang Tua dengan no. HP itu belum terdaftar. '
              'Minta mereka mendaftar di aplikasi dulu.';
        });
        return;
      }
      final sama = r.id == _ortuId;
      setState(() {
        _menautkan = false;
        _ganti = false;
        _hp.clear();
        _ortuId = r.id;
        _namaOrtu = r.nama;
      });
      messenger.showSnackBar(SnackBar(
          content: Text(sama
              ? 'Pasien sudah tertaut ke ${r.nama}'
              : r.diperbarui == 0
              ? 'Pasien ditautkan ke ${r.nama}'
              : 'Pasien ditautkan ke ${r.nama}. ${r.diperbarui} data lama ikut diperbarui.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menautkan = false;
        _errorTaut = 'Gagal menautkan: $e\nPenautan butuh koneksi internet.';
      });
    }
  }

  Future<void> _lepas() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _konfirmasi(
      'Lepas tautan?',
      '${_namaOrtu ?? 'Orang tua'} tidak akan bisa lagi melihat riwayat dan jadwal bayi ini. '
          'Data pemeriksaan tidak dihapus.',
      'Lepas',
    );
    if (!ok) return;
    setState(() {
      _menautkan = true;
      _errorTaut = null;
    });
    try {
      final n = await widget.svc.lepasTautan(widget.pasien);
      if (!mounted) return;
      setState(() {
        _menautkan = false;
        _ganti = false;
        _ortuId = null;
        _namaOrtu = null;
      });
      messenger.showSnackBar(SnackBar(
          content: Text(n == 0
              ? 'Tautan dilepas'
              : 'Tautan dilepas. $n data lama ikut diperbarui.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menautkan = false;
        _errorTaut = 'Gagal melepas tautan: $e\nButuh koneksi internet.';
      });
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  String? _wajib(String? v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null;
  String? _angka(String? v) => int.tryParse((v ?? '').trim()) == null ? 'Isi angka' : null;

  Widget _formTaut({required String label}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller: _hp,
          keyboardType: TextInputType.phone,
          decoration: _dec('No. HP Orang Tua'),
        ),
        if (_errorTaut != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_errorTaut!,
                style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _menautkan ? null : _tautkan,
          icon: _menautkan
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.link, size: 18),
          label: Text(_menautkan ? 'Memproses...' : label),
        ),
      ]);

  Widget _bagianOrangTua() {
    if (_ortuId == null) return _formTaut(label: 'Tautkan Orang Tua');

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration:
        BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.link, color: AppColors.ok),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_namaOrtu ?? 'Akun Orang Tua',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Text('Tertaut ke akun Orang Tua ini.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      if (_ganti) ...[
        _formTaut(label: 'Tautkan ke akun ini'),
        TextButton(
          onPressed: _menautkan
              ? null
              : () => setState(() {
            _ganti = false;
            _errorTaut = null;
            _hp.clear();
          }),
          child: const Text('Batal'),
        ),
      ] else ...[
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _menautkan ? null : () => setState(() => _ganti = true),
              child: const Text('Ganti'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
              onPressed: _menautkan ? null : _lepas,
              child: Text(_menautkan ? 'Memproses...' : 'Lepas Tautan'),
            ),
          ),
        ]),
        if (_errorTaut != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_errorTaut!,
                style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
          ),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Edit Pasien',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextFormField(controller: _nama, decoration: _dec('Nama bayi'), validator: _wajib),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pilihTanggal,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(_lahir == null ? 'Pilih tanggal lahir' : fmtTanggal(_lahir!)),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'L', label: Text('Laki-laki')),
                  ButtonSegment(value: 'P', label: Text('Perempuan')),
                ],
                selected: {_jk},
                onSelectionChanged: (s) => setState(() => _jk = s.first),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _berat,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Berat lahir (gram)'),
                    validator: _angka,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _usia,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Usia kehamilan (minggu)'),
                    validator: _angka,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _alamat, decoration: _dec('Alamat'), validator: _wajib),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
                ),
              const SizedBox(height: 16),
              GradientButton(label: 'Simpan Perubahan', onPressed: _simpan),
              const SectionLabel('Orang Tua'),
              _bagianOrangTua(),
            ]),
          ),
        ),
      ),
    );
  }
}