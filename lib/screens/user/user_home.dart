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
  final VoidCallback onMulaiSkrining;
  const UserHome({
    super.key,
    required this.user,
    required this.svc,
    required this.onLihatAnak,
    required this.onMulaiSkrining,
  });

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late final Stream<List<Pasien>> _anak = widget.svc.anakSaya();
  late final Stream<List<Pemeriksaan>> _periksa = widget.svc.pemeriksaanAnak();
  late final Stream<List<Agenda>> _agenda = widget.svc.agendaAnak();

  Widget _kartuStatusArham(List<Pasien> anak, List<Pemeriksaan> semua) {
    String nama = anak.isNotEmpty ? anak.first.nama : 'Arham';
    if (nama.toLowerCase().startsWith('bayi ')) {
      nama = nama.substring(5);
    }
    String status = 'normal';
    for (final e in semua) {
      if (!e.dibatalkan) {
        status = e.status;
        break;
      }
    }
    final isNormal = status == 'normal';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE4EC)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Status $nama',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: isNormal ? const Color(0xFFDCFCE7) : const Color(0xFFFDEACC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: isNormal ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                ),
                const SizedBox(width: 5),
                Text(
                  isNormal ? 'Sehat (Normal)' : 'Warning',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isNormal ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          // Kartu agenda puskesmas bawaan seperti Image 10
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('📅', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Text(
                      'Sabtu, 17 Okt 2026',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Text('🕓', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Text(
                      '09:00–12:00 • Puskesmas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7B8794),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        // Header gradien teal dengan dekorasi lingkaran hijau persis Image 7 & 10
        GradientHeader(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Welcome!',
                  style: TextStyle(fontSize: 15.5, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.user.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Puskesmas',
                  style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
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

                  Pemeriksaan? terbaru;
                  for (final e in semua) {
                    if (!e.dibatalkan && namaAnak.containsKey(e.pasienId)) {
                      terbaru = e;
                      break;
                    }
                  }

                  return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 90), children: [
                    // 1. Kartu Status Arham (persis Image 10)
                    _kartuStatusArham(anak, semua),

                    // 2. Tombol Besar Oranye Mulai Skrining (persis Image 10)
                    GestureDetector(
                      onTap: widget.onMulaiSkrining,
                      child: Container(
                        width: double.infinity,
                        height: 78,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFFFEA21B), Color(0xFFDF8B19)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFEA21B).withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Mulai Skrining',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 3. Agenda Puskesmas (persis Image 10)
                    const Text(
                      'Agenda Puskesmas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _agendaBagian(namaAnak),

                    if (anak.isNotEmpty) ...[
                      const SectionLabel('Anak Saya'),
                      for (final a in anak) _kartuAnak(a, semua),
                      const SizedBox(height: 4),
                      GradientButton(label: 'Lihat Riwayat Anak', onPressed: widget.onLihatAnak),
                    ],
                    if (terbaru != null) ...[
                      SectionLabel('Info untuk ${namaAnak[terbaru.pasienId]}'),
                      EdukasiCard(status: terbaru.status),
                    ],
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
