import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/pasien.dart';
import '../models/pemeriksaan.dart';
import '../screens/hasil_screen.dart';
import '../services/data_service.dart';
import '../theme.dart';
import 'common.dart';

/// Id pemeriksaan yang sudah dibuka. Disimpan di memori (hilang saat app ditutup).
final Set<String> _notifDibaca = <String>{};

String _waktuRelatif(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  if (d.inDays < 7) return '${d.inDays} hari lalu';
  return fmtTanggalPendek(t);
}

/// Bell notifikasi dengan dropdown. Selalu bisa diklik; kalau kosong
/// menampilkan "Belum ada notifikasi".
///  - Petugas   : pemeriksaan terbaru di Puskesmas
///  - Orang Tua : hasil pemeriksaan terbaru anaknya
class NotificationBell extends StatefulWidget {
  final AppUser user;
  final DataService svc;
  const NotificationBell({super.key, required this.user, required this.svc});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final Stream<List<Pasien>> _pasien =
      widget.user.isPetugas ? widget.svc.pasienPuskesmas() : widget.svc.anakSaya();
  late final Stream<List<Pemeriksaan>> _periksa = widget.user.isPetugas
      ? widget.svc.pemeriksaanTerakhir(limit: 30)
      : widget.svc.pemeriksaanAnak();

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
        builder: (context, es) {
          final nama = {for (final p in ps.data ?? <Pasien>[]) p.id: p.nama};
          var items = es.data ?? <Pemeriksaan>[];
          if (widget.user.isPetugas) {
            items = items
                .where((e) => !e.dibatalkan)
                .toList();
          }
          items = items.take(10).toList();
          final belum = items.where((e) => !_notifDibaca.contains(e.id)).length;

          return PopupMenuButton<Object>(
            tooltip: 'Notifikasi',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            onSelected: (v) {
              if (v == 'baca_semua') {
                setState(() => _notifDibaca.addAll(items.map((e) => e.id)));
              } else if (v is Pemeriksaan) {
                setState(() => _notifDibaca.add(v.id));
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          HasilScreen(
                          p: v,
                          namaPasien: nama[v.pasienId] ?? 'Pasien',
                          svc: widget.user.isPetugas ? widget.svc : null)),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<Object>(
                enabled: false,
                height: 44,
                child: Text(
                  widget.user.isPetugas ? 'Pemeriksaan Terbaru' : 'Notifikasi',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              const PopupMenuDivider(height: 1),
              if (items.isEmpty)
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
                for (final e in items)
                  PopupMenuItem<Object>(
                    value: e,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 10),
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: _notifDibaca.contains(e.id)
                              ? Colors.transparent
                              : (e.dibatalkan ? AppColors.muted : AppColors.teal),
                        ),
                      ),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            widget.user.isPetugas
                                ? 'Pemeriksaan ${nama[e.pasienId] ?? 'pasien'}'
                                : e.dibatalkan
                                    ? 'Hasil ${nama[e.pasienId] ?? 'anak'} dibatalkan'
                                    : 'Hasil skrining ${nama[e.pasienId] ?? 'anak'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: _notifDibaca.contains(e.id)
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                          Text(
                            e.dibatalkan
                                ? 'Dikoreksi petugas, abaikan hasil sebelumnya'
                                : '${fmtKadar(e.hasil)} ${e.satuan}',
                            style: TextStyle(
                                fontSize: 12,
                                color: e.dibatalkan ? AppColors.muted : AppColors.teal),
                          ),
                          Text(_waktuRelatif(e.waktu),
                              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ]),
                      ),
                    ]),
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
              ],
            ],
            child: _tombol(belum),
          );
        },
      ),
    );
  }
}
