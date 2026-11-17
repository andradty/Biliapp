import 'package:flutter/material.dart';

import '../models/agenda.dart';
import '../models/app_user.dart';
import '../models/pasien.dart';
import '../models/pemeriksaan.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/notif_store.dart';
import '../widgets/notification_bell.dart' show kBatasNotif;
import 'hasil_screen.dart';

/// Halaman Notifikasi lengkap (seperti inbox): tab Semua / Belum dibaca,
/// dikelompokkan per hari, dengan pagination ringkas.
class NotifikasiScreen extends StatefulWidget {
  final AppUser user;
  final DataService svc;
  const NotifikasiScreen({super.key, required this.user, required this.svc});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  static const _perHal = 5;

  bool _hanyaBelum = false;
  int _hal = 0;

  // Stream di-cache agar daftar tidak berkedip / scroll tidak lompat saat ganti halaman.
  late final Stream<List<Pasien>> _pasien =
      widget.user.isPetugas ? widget.svc.pasienPuskesmas() : widget.svc.anakSaya();
  late final Stream<List<Pemeriksaan>> _periksa = widget.user.isPetugas
      ? widget.svc.pemeriksaanTerakhir(limit: kBatasNotif)
      : widget.svc.pemeriksaanAnak();
  late final Stream<List<Agenda>> _agenda =
      widget.user.isPetugas ? Stream.value(<Agenda>[]) : widget.svc.agendaAnak();

  @override
  void initState() {
    super.initState();
    NotifStore.muat(widget.user.uid);
  }

  Widget _tab(String teks, bool aktif, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: aktif ? AppColors.teal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: aktif ? AppColors.teal : const Color(0xFFDCE4EC)),
          ),
          child: Text(teks,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: aktif ? Colors.white : AppColors.muted)),
        ),
      );

  void _buka(NotifItem n) {
    NotifStore.tandai([n.id]);
    final p = n.pemeriksaan;
    if (p == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => HasilScreen(
              p: p,
              namaPasien: n.namaPasien,
              svc: widget.user.isPetugas ? widget.svc : null)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          const SubHeader(title: 'Notifikasi'),
          Expanded(
            child: StreamBuilder<List<Pasien>>(
              stream: _pasien,
              builder: (context, ps) => StreamBuilder<List<Pemeriksaan>>(
                stream: _periksa,
                builder: (context, es) => StreamBuilder<List<Agenda>>(
                  stream: _agenda,
                  builder: (context, ag) {
                    if (ps.hasError) return SingleChildScrollView(child: ErrorBox(ps.error!));
                    if (es.hasError) return SingleChildScrollView(child: ErrorBox(es.error!));
                    if (!es.hasData || !ps.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final nama = {for (final p in ps.data!) p.id: p.nama};
                    final semua = susunNotif(
                      petugas: widget.user.isPetugas,
                      nama: nama,
                      periksa: es.data!,
                      agenda: ag.data ?? <Agenda>[],
                    );

                    return ListenableBuilder(
                      listenable: Listenable.merge([NotifStore.dibaca, NotifStore.siap]),
                      builder: (context, _) {
                        final dibaca = NotifStore.dibaca.value;
                        final belum = semua.where((n) => !dibaca.contains(n.id)).toList();
                        final daftar = _hanyaBelum ? belum : semua;
                        final total = (daftar.length / _perHal).ceil();
                        final hal = total == 0 ? 0 : _hal.clamp(0, total - 1).toInt();
                        final tampil = daftar.skip(hal * _perHal).take(_perHal).toList();

                        final isi = <Widget>[];
                        String? kelompokSebelum;
                        for (final n in tampil) {
                          final k = labelKelompok(n);
                          if (k != kelompokSebelum) {
                            isi.add(Padding(
                              padding: EdgeInsets.only(top: isi.isEmpty ? 0 : 10, bottom: 8),
                              child: Text(k,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.muted)),
                            ));
                            kelompokSebelum = k;
                          }
                          final sudah = dibaca.contains(n.id);
                          isi.add(Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3))
                              ],
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _buka(n),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: notifBaris(n, sudah),
                                ),
                              ),
                            ),
                          ));
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          children: [
                            Row(children: [
                              Expanded(
                                child: Wrap(spacing: 8, runSpacing: 6, children: [
                                  _tab('Semua', !_hanyaBelum,
                                      () => setState(() {
                                            _hanyaBelum = false;
                                            _hal = 0;
                                          })),
                                  _tab('Belum dibaca (${belum.length})', _hanyaBelum,
                                      () => setState(() {
                                            _hanyaBelum = true;
                                            _hal = 0;
                                          })),
                                ]),
                              ),
                            ]),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: belum.isEmpty
                                    ? null
                                    : () => NotifStore.tandai(semua.map((n) => n.id)),
                                child: const Text('Tandai semua dibaca'),
                              ),
                            ),
                            if (tampil.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(children: [
                                  const Icon(Icons.notifications_none,
                                      size: 40, color: AppColors.muted),
                                  const SizedBox(height: 8),
                                  Text(
                                      _hanyaBelum
                                          ? 'Semua notifikasi sudah dibaca.'
                                          : 'Belum ada notifikasi.',
                                      style: const TextStyle(color: AppColors.muted)),
                                ]),
                              ),
                            ...isi,
                            PaginasiBar(
                                halaman: hal,
                                total: total,
                                onUbah: (h) => setState(() => _hal = h)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
