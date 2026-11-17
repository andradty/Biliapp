import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agenda.dart';
import '../models/pemeriksaan.dart';
import '../theme.dart';
import 'common.dart';

/// Id notifikasi yang sudah dibaca, disimpan permanen per akun di perangkat
/// (bertahan setelah app ditutup atau logout/login lagi). Dipakai bersama oleh
/// bel notifikasi dan halaman Notifikasi supaya angkanya selalu sinkron.
class NotifStore {
  static final ValueNotifier<Set<String>> dibaca = ValueNotifier(<String>{});
  static final ValueNotifier<bool> siap = ValueNotifier(false);
  static String? _uid;

  static String _kunci(String uid) => 'notif_dibaca_$uid';

  static Future<void> muat(String uid) async {
    if (_uid == uid && siap.value) return;
    _uid = uid;
    siap.value = false;
    dibaca.value = <String>{};
    try {
      final p = await SharedPreferences.getInstance();
      if (_uid != uid) return; // akun berganti saat memuat
      dibaca.value = (p.getStringList(_kunci(uid)) ?? <String>[]).toSet();
    } catch (_) {}
    if (_uid == uid) siap.value = true;
  }

  static Future<void> tandai(Iterable<String> ids) async {
    final uid = _uid;
    if (uid == null) return;
    final daftar = <String>{...dibaca.value, ...ids}.toList();
    // Batasi ukuran: simpan 300 id terakhir saja.
    final simpan = daftar.length > 300 ? daftar.sublist(daftar.length - 300) : daftar;
    dibaca.value = simpan.toSet();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_kunci(uid), simpan);
    } catch (_) {}
  }
}

enum NotifJenis { jadwal, hasil, dibatalkan }

class NotifItem {
  final String id;
  final NotifJenis jenis;
  final DateTime waktu;
  final String judul;
  final String detail;
  final String? catatan;
  final Pemeriksaan? pemeriksaan;
  final String namaPasien;
  const NotifItem({
    required this.id,
    required this.jenis,
    required this.waktu,
    required this.judul,
    required this.detail,
    required this.namaPasien,
    this.catatan,
    this.pemeriksaan,
  });
}

/// Jadwal mendatang di urutan atas, disusul pemeriksaan (terbaru dulu).
List<NotifItem> susunNotif({
  required bool petugas,
  required Map<String, String> nama,
  required List<Pemeriksaan> periksa,
  required List<Agenda> agenda,
}) {
  final hasil = <NotifItem>[];
  for (final e in periksa) {
    if (petugas && e.dibatalkan) continue;
    final n = nama[e.pasienId];
    hasil.add(NotifItem(
      id: e.id,
      jenis: e.dibatalkan ? NotifJenis.dibatalkan : NotifJenis.hasil,
      waktu: e.waktu,
      namaPasien: n ?? (petugas ? 'Pasien' : 'Anak'),
      judul: petugas
          ? 'Pemeriksaan ${n ?? 'pasien'}'
          : e.dibatalkan
              ? 'Hasil ${n ?? 'anak'} dibatalkan'
              : 'Hasil skrining ${n ?? 'anak'}',
      detail: e.dibatalkan
          ? 'Dikoreksi petugas, abaikan hasil sebelumnya'
          : '${fmtKadar(e.hasil)} ${e.satuan}',
      pemeriksaan: e,
    ));
  }
  final jadwal = [...agenda]..sort((a, b) => a.tanggal.compareTo(b.tanggal));
  return [
    for (final a in jadwal)
      NotifItem(
        id: 'agenda_${a.id}',
        jenis: NotifJenis.jadwal,
        waktu: a.tanggal,
        namaPasien: nama[a.pasienId] ?? 'Anak',
        judul: 'Jadwal pemeriksaan ${nama[a.pasienId] ?? 'anak'}',
        detail: '${fmtTanggal(a.tanggal)} • ${a.hariLagiLabel}',
        catatan: a.catatan.isEmpty ? null : a.catatan,
      ),
    ...hasil,
  ];
}

String waktuRelatif(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  if (d.inDays < 7) return '${d.inDays} hari lalu';
  return fmtTanggalPendek(t);
}

/// Label kelompok untuk halaman Notifikasi.
String labelKelompok(NotifItem n) {
  if (n.jenis == NotifJenis.jadwal) return 'Jadwal mendatang';
  final now = DateTime.now();
  final hariIni = DateTime(now.year, now.month, now.day);
  final hari = DateTime(n.waktu.year, n.waktu.month, n.waktu.day);
  final selisih = hariIni.difference(hari).inDays;
  if (selisih <= 0) return 'Hari ini';
  if (selisih == 1) return 'Kemarin';
  if (selisih < 7) return 'Minggu ini';
  return 'Lebih lama';
}

/// Isi satu baris notifikasi (dipakai di dropdown bel dan halaman Notifikasi).
Widget notifBaris(NotifItem n, bool sudahDibaca) {
  final (ikon, warna) = switch (n.jenis) {
    NotifJenis.jadwal => (Icons.event, AppColors.orange2),
    NotifJenis.hasil => (Icons.monitor_heart_outlined, AppColors.teal),
    NotifJenis.dibatalkan => (Icons.block, AppColors.muted),
  };
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(ikon, size: 18, color: warna),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(n.judul,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 13.5,
                fontWeight: sudahDibaca ? FontWeight.w500 : FontWeight.w700)),
        Text(n.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                color: n.jenis == NotifJenis.dibatalkan ? AppColors.muted : warna)),
        if (n.catatan != null)
          Text(n.catatan!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        if (n.jenis != NotifJenis.jadwal)
          Text(waktuRelatif(n.waktu),
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ]),
    ),
    if (!sudahDibaca)
      const Padding(
        padding: EdgeInsets.only(left: 8, top: 4),
        child: CircleAvatar(radius: 4, backgroundColor: AppColors.teal),
      ),
  ]);
}
