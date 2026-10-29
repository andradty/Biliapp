import 'package:flutter/material.dart';

import '../../models/agenda.dart';
import '../../models/app_user.dart';
import '../../models/pasien.dart';
import '../../models/pemeriksaan.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/edukasi_card.dart';
import '../../widgets/notification_bell.dart';
import '../hasil_screen.dart';

class UserHome extends StatefulWidget {
  final AppUser user;
  final DataService svc;
  final VoidCallback onLihatAnak;
  const UserHome({super.key, required this.user, required this.svc, required this.onLihatAnak});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late final Stream<List<Pasien>> _anak = widget.svc.anakSaya();
  late final Stream<List<Pemeriksaan>> _periksa = widget.svc.pemeriksaanAnak();
  late final Stream<List<Agenda>> _agenda = widget.svc.agendaAnak();

  Widget _kartuAnak(Pasien a, List<Pemeriksaan> semua) {
    final terakhir = semua.where((e) => e.pasienId == a.id && !e.dibatalkan).toList();
    final t = terakhir.isEmpty ? null : terakhir.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x120B7A93), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: t == null
              ? null
              : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => HasilScreen(p: t, namaPasien: a.nama))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const BabyAvatar(size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.nama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    t == null
                        ? a.usia
                        : '${a.usia} • periksa ${fmtTanggalPendek(t.waktu)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ]),
              ),
              if (t == null)
                const Text('Belum ada\npemeriksaan',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: AppColors.muted))
              else
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  StatusBadge(t.status),
                  const SizedBox(height: 4),
                  Text('${fmtKadar(t.hasil)} ${t.satuan}',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700, color: statusColor(t.status))),
                ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _agendaBagian(Map<String, String> namaAnak) {
    return StreamBuilder<List<Agenda>>(
      stream: _agenda,
      builder: (context, snap) {
        if (snap.hasError) return ErrorBox(snap.error!);
        final list = snap.data ?? <Agenda>[];
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration:
                BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Row(children: [
              Icon(Icons.event_available, color: AppColors.teal),
              SizedBox(width: 12),
              Expanded(
                child: Text('Belum ada jadwal pemeriksaan dari Puskesmas.',
                    style: TextStyle(color: AppColors.muted)),
              ),
            ]),
          );
        }
        return Column(children: [
          for (final a in list)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.bg1, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text('${a.tanggal.day}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.teal)),
                    Text(fmtTanggalPendek(a.tanggal).split(' ').last,
                        style: const TextStyle(fontSize: 11, color: AppColors.teal)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pemeriksaan ${namaAnak[a.pasienId] ?? 'anak'}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${fmtTanggal(a.tanggal)} • ${a.hariLagiLabel}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.orange2)),
                    if (a.catatan.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(a.catatan,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      ),
                  ]),
                ),
              ]),
            ),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bgGradient,
      child: Column(children: [
        GradientHeader(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Welcome!', style: TextStyle(color: Colors.white70)),
                Text(widget.user.nama,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Text('Orang Tua', style: TextStyle(color: Colors.white)),
              ]),
            ),
            NotificationBell(user: widget.user, svc: widget.svc),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<Pasien>>(
            stream: _anak,
            builder: (context, ps) {
              if (ps.hasError) return SingleChildScrollView(child: ErrorBox(ps.error!));
              if (!ps.hasData) return const Center(child: CircularProgressIndicator());
              final anak = ps.data!;
              final namaAnak = {for (final a in anak) a.id: a.nama};
              return StreamBuilder<List<Pemeriksaan>>(
                stream: _periksa,
                builder: (context, es) {
                  if (es.hasError) return SingleChildScrollView(child: ErrorBox(es.error!));
                  final semua = es.data ?? <Pemeriksaan>[];

                  // Hasil terbaru (tidak dibatalkan) dari semua anak, untuk kartu info.
                  Pemeriksaan? terbaru;
                  for (final e in semua) {
                    if (!e.dibatalkan && namaAnak.containsKey(e.pasienId)) {
                      terbaru = e;
                      break;
                    }
                  }

                  return ListView(padding: const EdgeInsets.all(20), children: [
                    if (anak.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Text(
                          'Belum ada anak yang ditautkan ke akun ini. Minta petugas '
                          'Puskesmas menautkan dengan nomor HP yang terdaftar.',
                          style: TextStyle(color: AppColors.muted, height: 1.5),
                        ),
                      )
                    else ...[
                      const SectionLabel('Anak Saya'),
                      for (final a in anak) _kartuAnak(a, semua),
                      const SizedBox(height: 4),
                      GradientButton(label: 'Lihat Riwayat Anak', onPressed: widget.onLihatAnak),
                    ],
                    const SectionLabel('Jadwal Pemeriksaan'),
                    _agendaBagian(namaAnak),
                    if (terbaru != null) ...[
                      SectionLabel('Info untuk ${namaAnak[terbaru.pasienId]}'),
                      EdukasiCard(status: terbaru.status),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Text(
                        'BiliCheck adalah alat bantu skrining, bukan pengganti diagnosis dokter. '
                        'Hasil yang mengkhawatirkan perlu dikonfirmasi tenaga kesehatan.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5),
                      ),
                    ),
                  ]);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
