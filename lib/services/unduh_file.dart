import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Simpan file ke penyimpanan perangkat + modal "berhasil diunduh" (dipakai PDF & CSV).
/// Lokasi file sengaja tidak ditampilkan ke pengguna.
class UnduhFile {
  static Future<String> simpan(Uint8List bytes, String namaFile) async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    } else {
      base = await getDownloadsDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}BiliCheck');
    if (!await dir.exists()) await dir.create(recursive: true);

    var nama = namaFile;
    if (await File('${dir.path}${Platform.pathSeparator}$nama').exists()) {
      final n = DateTime.now();
      String d(int v) => v.toString().padLeft(2, '0');
      final i = namaFile.lastIndexOf('.');
      final tambah = '_${d(n.hour)}${d(n.minute)}${d(n.second)}';
      nama = i < 0
          ? '$namaFile$tambah'
          : '${namaFile.substring(0, i)}$tambah${namaFile.substring(i)}';
    }
    final file = File('${dir.path}${Platform.pathSeparator}$nama');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// [jenis] mis. 'PDF' atau 'CSV'.
  static Future<void> modalBerhasil(
      BuildContext context, String jenis, String namaFile, String path, {String? mimeType}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
        title: Text('$jenis berhasil diunduh', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(namaFile,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('File sudah diunduh dan bisa dibuka.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(ctx);
              final r = await OpenFilex.open(path, type: mimeType);
              if (r.type != ResultType.done) {
                messenger.showSnackBar(SnackBar(
                    content: Text('Tidak ada aplikasi untuk membuka file $jenis di perangkat ini.')));
              }
            },
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }
}
