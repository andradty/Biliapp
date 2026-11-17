import 'package:flutter/material.dart';

import '../models/agenda.dart';
import '../models/app_user.dart';
import '../models/pasien.dart';
import '../models/pemeriksaan.dart';
import '../screens/hasil_screen.dart';
import '../screens/notifikasi_screen.dart';
import '../services/data_service.dart';
import '../theme.dart';
import 'notif_store.dart';

/// Jumlah notifikasi yang dimuat (sama dengan halaman Notifikasi agar angka sinkron).
const int kBatasNotif = 50;

/// Bell notifikasi: dropdown ringkas (5 terbaru) + tombol ke halaman Notifikasi.
///  - Petugas   : pemeriksaan terbaru di Puskesmas
///  - Orang Tua : hasil pemeriksaan anak + jadwal pemeriksaan
class NotificationBell extends StatefulWidget {
  final AppUser user;
  final DataService svc;
  const NotificationBell({super.key, required this.user, required this.svc});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  static const _ringkas = 5;

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

  Widget _tombol(int belumDibaca) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14)),
        child: Badge(
          isLabelVisible: belumDibaca > 0,
          label: Text('$belumDibaca'),
          child: const Icon(Icons.notifications, color: AppColors.orange1),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pasien>>(
      stream: _pasien,
      builder: (context, ps) => StreamBuilder<List<Pemeriksaan>>(
        stream: _periksa,
        builder: (context, es) => StreamBuilder<List<Agenda>>(
          stream: _agenda,
          builder: (context, ag) {
            final nama = {for (final p in ps.data ?? <Pasien>[]) p.id: p.nama};
            final semua = susunNotif(
              petugas: widget.user.isPetugas,
              nama: nama,
              periksa: es.data ?? <Pemeriksaan>[],
              agenda: ag.data ?? <Agenda>[],
            );
            final ringkas = semua.take(_ringkas).toList();

            return ListenableBuilder(
              listenable: Listenable.merge([NotifStore.dibaca, NotifStore.siap]),
              builder: (context, _) {
                final dibaca = NotifStore.dibaca.value;
                // Sebelum status baca selesai dimuat, jangan tampilkan angka.
                final belum = !NotifStore.siap.value
                    ? 0
                    : semua.where((n) => !dibaca.contains(n.id)).length;

                return PopupMenuButton<Object>(
                  tooltip: 'Notifikasi',
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 8),
                  constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  onSelected: (v) {
                    if (v == 'baca_semua') {
                      NotifStore.tandai(semua.map((n) => n.id));
                    } else if (v == 'lihat_semua') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                NotifikasiScreen(user: widget.user, svc: widget.svc)),
                      );
                    } else if (v is NotifItem) {
                      NotifStore.tandai([v.id]);
                      final p = v.pemeriksaan;
                      if (p != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HasilScreen(
                                  p: p,
                                  namaPasien: v.namaPasien,
                                  svc: widget.user.isPetugas ? widget.svc : null)),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<Object>(
                      enabled: false,
                      height: 44,
                      child: Text('Notifikasi',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ),
                    const PopupMenuDivider(height: 1),
                    if (ringkas.isEmpty)
                      const PopupMenuItem<Object>(
                        enabled: false,
                        height: 110,
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.notifications_none, size: 34, color: AppColors.muted),
                            SizedBox(height: 8),
                            Text('Belum ada notifikasi',
                                style: TextStyle(color: AppColors.muted)),
                          ]),
                        ),
                      )
                    else ...[
                      for (final n in ringkas)
                        PopupMenuItem<Object>(
                          value: n,
                          child: notifBaris(n, dibaca.contains(n.id)),
                        ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<Object>(
                        value: 'baca_semua',
                        enabled: belum > 0,
                        height: 40,
                        child: Center(
                          child: Text('Tandai semua dibaca',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: belum > 0 ? AppColors.teal : AppColors.muted)),
                        ),
                      ),
                      const PopupMenuItem<Object>(
                        value: 'lihat_semua',
                        height: 40,
                        child: Center(
                          child: Text('Lihat semua notifikasi',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal)),
                        ),
                      ),
                    ],
                  ],
                  child: _tombol(belum),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
