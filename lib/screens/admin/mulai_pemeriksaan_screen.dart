import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/batas_hasil.dart';
import '../../models/bacaan_alat.dart';
import '../../models/device.dart';
import '../../models/pasien.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Input manual sebagai CADANGAN kalau alat tidak mengirim data.
const bool kInputManual = true;

/// false = setelah REKAM ditekan di alat, hasil dibekukan dan Petugas menekan "Simpan".
/// true  = langsung masuk Firestore begitu REKAM ditekan.
const bool kSimpanOtomatis = false;

/// Bacaan live dianggap putus kalau tidak ada update sebanyak ini.
const int kBatasStaleDetik = 10;

const String kSatuan = BacaanAlat.satuan; // '%'

enum _Koneksi { menunggu, ok, putus }

class MulaiPemeriksaanScreen extends StatefulWidget {
  final DataService svc;
  final String pasienId;
  const MulaiPemeriksaanScreen({super.key, required this.svc, required this.pasienId});

  @override
  State<MulaiPemeriksaanScreen> createState() => _MulaiPemeriksaanScreenState();
}

class _MulaiPemeriksaanScreenState extends State<MulaiPemeriksaanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nilaiC = TextEditingController();

  Pasien? _pasien;
  DeviceInfo? _device;
  String? _error;
  bool _loading = true;

  // ---- Alat (RTDB) ----
  StreamSubscription<BacaanAlat?>? _subLive;
  StreamSubscription<BacaanAlat?>? _subHasil;
  Timer? _ticker;
  BacaanAlat? _live;
  DateTime? _liveTerakhir;
  int? _nTerakhir; // `n` terakhir yang terlihat; membedakan nilai lama vs data baru
  String? _sesiId;
  BacaanAlat? _rekam; // hasil REKAM (dibekukan)
  String? _errorAlat;

  bool _manual = false;
  bool _menyimpan = false;
  bool _tersimpan = false;

  @override
  void initState() {
    super.initState();
    _nilaiC.addListener(() => setState(() {}));
    _muat();
  }

  @override
  void dispose() {
    _subLive?.cancel();
    _subHasil?.cancel();
    _ticker?.cancel();
    // Layar ditutup tanpa menyimpan: beri tahu alat bahwa sesi ini batal.
    if (!_tersimpan && _sesiId != null && _device != null) {
      widget.svc.batalSesi(_device!.id).catchError((_) {});
    }
    _nilaiC.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final daftar = await widget.svc.pasienPuskesmas().first;
      final dev = await widget.svc.deviceSaya().first;
      final p = daftar.where((e) => e.id == widget.pasienId).toList();
      if (!mounted) return;
      setState(() {
        _pasien = p.isEmpty ? null : p.first;
        _device = dev;
        _loading = false;
      });
      if (_hambatan == null) _mulaiDengar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _mulaiDengar() {
    _subLive = widget.svc.bacaanLive(_device!.id).listen((b) {
      if (!mounted) return;
      setState(() {
        if (b == null) {
          // node live kosong / null
          _live = null;
          _liveTerakhir = null;
          _nTerakhir = null;
          return;
        }
        // Event pertama = nilai lama yang tersimpan di RTDB.
        // Dianggap segar hanya kalau `n` berubah dari yang terakhir terlihat.
        if (_nTerakhir != null && b.urut != _nTerakhir) _liveTerakhir = DateTime.now();
        _nTerakhir = b.urut;
        _live = b;
      });
    }, onError: (e) {
      if (mounted) setState(() => _errorAlat = '$e');
    });

    // RTDB hanya memicu event saat data berubah; ticker ini untuk mendeteksi "diam".
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _bukaSesi();
  }

  /// Membuat sesi baru di alat lalu menunggu hasil REKAM untuk sesi itu saja.
  /// Hasil REKAM lama (sesi sebelumnya) otomatis tidak ikut terbaca.
  Future<void> _bukaSesi() async {
    await _subHasil?.cancel();
    _subHasil = null;
    try {
      final sid = await widget.svc
          .mulaiSesi(_device!.id)
          .timeout(const Duration(seconds: 8));
      if (!mounted) {
        widget.svc.batalSesi(_device!.id).catchError((_) {});
        return;
      }
      setState(() {
        _sesiId = sid;
        _rekam = null;
        _errorAlat = null;
      });
      _subHasil = widget.svc.hasilSesi(_device!.id, sid).listen((b) {
        if (!mounted || b == null) return;
        if (b.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Alat gagal membaca: ${b.error}. Ulangi pengukuran.')));
          _bukaSesi();
          return;
        }
        setState(() => _rekam = b);
        if (kSimpanOtomatis) _simpanAlat(konfirmasi: false);
      }, onError: (e) {
        if (mounted) setState(() => _errorAlat = '$e');
      });
    } catch (e) {
      if (mounted) setState(() => _errorAlat = 'Gagal membuka sesi di alat: $e');
    }
  }

  _Koneksi get _koneksi {
    if (_live == null || _liveTerakhir == null) return _Koneksi.menunggu;
    final selisih = DateTime.now().difference(_liveTerakhir!).inSeconds;
    return selisih > kBatasStaleDetik ? _Koneksi.putus : _Koneksi.ok;
  }

  /// Alasan pemeriksaan tidak bisa disimpan (null = siap).
  String? get _hambatan {
    if (_pasien == null) return 'Pasien tidak ditemukan.';
    final d = _device;
    if (d == null) return 'Belum ada alat terdaftar untuk Puskesmas ini.';
    if (d.kalibrasiAktifId == null) {
      return 'Alat belum punya kalibrasi aktif. Pilih kalibrasi di tab Alat.';
    }
    return null;
  }

  // ---------------- Simpan ----------------

  Future<bool> _konfirmasi(double nilai) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Simpan pemeriksaan?'),
        content: Text('Hasil ${fmtKadar(nilai)} $kSatuan untuk ${_pasien!.nama} tidak dapat '
            'diubah setelah disimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Simpan')),
        ],
      ),
    );
    return ok == true && mounted;
  }

  void _kirim(double nilai, Map<String, dynamic> pengukuran, {String? sesiId}) {
    final messenger = ScaffoldMessenger.of(context);
    _tersimpan = true;
    // Tidak di-await: saat offline Firestore menaruhnya di antrean lokal.
    widget.svc
        .tambahPemeriksaan(
          pasien: _pasien!,
          device: _device!,
          hasil: nilai,
          satuan: kSatuan,
          pengukuran: pengukuran,
          sesiId: sesiId,
        )
        .catchError((e) => messenger
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan pemeriksaan: $e'))));
    messenger.showSnackBar(const SnackBar(
        content: Text('Pemeriksaan disimpan. Akan tersinkron otomatis saat online.')));
    Navigator.pop(context);
  }

  /// Simpan hasil yang direkam dari tombol di alat.
  Future<void> _simpanAlat({bool konfirmasi = true}) async {
    final r = _rekam;
    if (r == null || _menyimpan) return;
    if (r.hasil < 0 || r.hasil > BatasHasil.maks) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nilai dari alat di luar rentang 0 - 100 %. Ulangi pengukuran.')));
      _bukaSesi();
      return;
    }
    // Hasil harus dihitung dengan kalibrasi yang sama dengan yang tercatat di dokumen.
    if (r.kalibrasiId != null && r.kalibrasiId != _device!.kalibrasiAktifId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Kalibrasi di alat (${r.kalibrasiId}) beda dengan kalibrasi aktif '
              '(${_device!.kalibrasiAktifId}). Sinkronkan dulu lalu ulangi pengukuran.')));
      _bukaSesi();
      return;
    }
    if (konfirmasi && !await _konfirmasi(r.hasil)) return;
    if (!mounted) return;
    _menyimpan = true;
    _kirim(r.hasil, {...r.pengukuran, 'sumber': 'alat', 'sesi_id': _sesiId}, sesiId: _sesiId);
  }

  /// Simpan dari input manual (cadangan).
  Future<void> _simpanManual() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _konfirmasi(_nilai!)) return;
    if (!mounted) return;
    _kirim(_nilai!, {'sumber': 'manual'});
  }

  double? get _nilai => double.tryParse(_nilaiC.text.trim().replaceAll(',', '.'));

  String? _validasi(String? v) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Masukkan angka';
    if (n < 0 || n > BatasHasil.maks) return 'Rentang 0 - 100 $kSatuan';
    return null;
  }

  // ---------------- UI ----------------

  Widget _kartu(List<Widget> anak) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: anak),
      );

  Widget _baris(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110,
              child: Text(l, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );

  /// Tiga nilai pendukung seperti di dashboard web: ADC, lux, konsentrasi.
  Widget _metrik(Map<String, dynamic>? p) {
    String f(String k, int d) {
      final v = p?[k];
      return v is num ? v.toStringAsFixed(d) : '-';
    }

    Widget sel(String label, String nilai) => Expanded(
          child: Column(children: [
            Text(nilai,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ]),
        );

    return Row(children: [
      sel('Nilai ADC', f('adc', 0)),
      sel('Intensitas (lux)', f('lux', 0)),
      sel('Konsentrasi', f('konsentrasi', 6)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          const SubHeader(title: 'Mulai Pemeriksaan'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? SingleChildScrollView(child: ErrorBox(_error!))
                    : _isi(),
          ),
        ]),
      ),
    );
  }

  Widget _isi() {
    final hambatan = _hambatan;
    return ListView(padding: const EdgeInsets.all(20), children: [
      _kartu([
        _baris('Pasien', _pasien?.nama ?? '-'),
        _baris('Alat', _device?.id ?? '-'),
        _baris('Kalibrasi aktif', _device?.kalibrasiAktifId ?? 'belum ada'),
      ]),
      const SizedBox(height: 12),
      if (hambatan != null)
        _kartu([
          Row(children: [
            const Icon(Icons.error_outline, color: Color(0xFFC62828)),
            const SizedBox(width: 10),
            Expanded(child: Text(hambatan)),
          ]),
        ])
      else ...[
        if (_errorAlat != null) ErrorBox(_errorAlat!),
        if (_rekam != null) _kartuRekam(_rekam!) else _kartuLive(),
        if (kInputManual) ..._bagianManual(),
      ],
    ]);
  }

  // ---- Bacaan realtime ----
  Widget _kartuLive() {
    final k = _koneksi;
    final (warna, teks) = switch (k) {
      _Koneksi.ok => (const Color(0xFF2E7D32), 'Alat terhubung'),
      _Koneksi.putus => (const Color(0xFFC62828), 'Alat tidak mengirim data'),
      _Koneksi.menunggu => (AppColors.muted, 'Menunggu data dari alat...'),
    };
    final b = _live;
    final tampil = k == _Koneksi.ok && b != null;

    return _kartu([
      Row(children: [
        Icon(Icons.circle, size: 10, color: warna),
        const SizedBox(width: 8),
        Text(teks, style: TextStyle(fontSize: 13, color: warna, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),
      Center(
        child: Column(children: [
          const Text('% Jaundice', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          Text(
            tampil ? '${fmtKadar(b.hasil)}%' : '--',
            style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: tampil ? AppColors.ink : AppColors.muted),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      _metrik(tampil ? b.pengukuran : null),
      const SizedBox(height: 14),
      const Text(
        'Nilai ini berubah-ubah selama alat membaca. Tekan tombol REKAM di alat '
        'saat angka sudah stabil untuk mengambil hasil.',
        style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.muted),
      ),
    ]);
  }

  // ---- Hasil yang sudah direkam ----
  Widget _kartuRekam(BacaanAlat r) {
    return _kartu([
      const Row(children: [
        Icon(Icons.check_circle, size: 18, color: Color(0xFF2E7D32)),
        SizedBox(width: 8),
        Text('Hasil terekam dari alat',
            style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),
      Center(
        child: Column(children: [
          const Text('% Jaundice', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          Text('${fmtKadar(r.hasil)}%',
              style: const TextStyle(
                  fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ]),
      ),
      const SizedBox(height: 16),
      _metrik(r.pengukuran),
      const SizedBox(height: 18),
      GradientButton(label: 'Simpan Pemeriksaan', onPressed: _simpanAlat),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: _bukaSesi, // sesi baru: hasil lama tidak terbawa
          child: const Text('Ulangi pengukuran'),
        ),
      ),
    ]);
  }

  // ---- Input manual (cadangan) ----
  List<Widget> _bagianManual() {
    if (_rekam != null) return const []; // sedang menunggu keputusan simpan/ulangi
    if (!_manual) {
      return [
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _manual = true),
            child: const Text('Alat bermasalah? Input manual'),
          ),
        ),
      ];
    }

    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(14)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.edit_note, color: AppColors.orange2),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode input manual: nilai dari alat diketik sendiri. '
              'Data ditandai sumber "manual".',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Form(
        key: _formKey,
        child: _kartu([
          TextFormField(
            controller: _nilaiC,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '% Jaundice',
              suffixText: kSatuan,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: _validasi,
          ),
        ]),
      ),
      const SizedBox(height: 18),
      GradientButton(label: 'Simpan Pemeriksaan', onPressed: _simpanManual),
    ];
  }
}