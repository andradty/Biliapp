import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../widgets/common.dart';

const String kEmailTim = 'agrion.official@gmail.com';
const String kWhatsAppTim = '081387421753';
const String kInstagramTim = '@agrion.official';
const String kInstagramUrl = 'https://www.instagram.com/agrion.official';
const String kAlamatTim = 'Sekolah Vokasi IPB University, Bogor';

/// Membuka profil Instagram tim di aplikasi Instagram / browser.
Future<void> bukaInstagram(BuildContext context) async {
  final m = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(Uri.parse(kInstagramUrl), mode: LaunchMode.externalApplication);
    if (!ok) m.showSnackBar(const SnackBar(content: Text('Tidak dapat membuka Instagram.')));
  } catch (_) {
    m.showSnackBar(const SnackBar(content: Text('Tidak dapat membuka Instagram.')));
  }
}

class KontakScreen extends StatelessWidget {
  const KontakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final item = <(IconData, String, String)>[
      if (kEmailTim.isNotEmpty) (Icons.email_outlined, 'Email', kEmailTim),
      if (kWhatsAppTim.isNotEmpty) (Icons.chat_outlined, 'WhatsApp', kWhatsAppTim),
      if (kInstagramTim.isNotEmpty) (Icons.camera_alt_outlined, 'Instagram', kInstagramTim),
      if (kAlamatTim.isNotEmpty) (Icons.location_on_outlined, 'Alamat', kAlamatTim),
    ];

    return Scaffold(
      body: Container(
        decoration: bgGradient,
        child: Column(children: [
          const SubHeader(title: 'Hubungi Kami'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const Text(
                'Ada pertanyaan, masukan, atau kendala saat memakai BiliCheck? '
                'Hubungi tim kami. Ketuk untuk menyalin.',
                style: TextStyle(color: AppColors.muted, height: 1.55),
              ),
              const SizedBox(height: 16),
              for (final k in item)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      leading: Icon(k.$1, color: AppColors.teal),
                      title: Text(k.$2,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      subtitle: Text(k.$3,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      trailing: Icon(k.$2 == 'Instagram' ? Icons.open_in_new : Icons.copy, size: 18),
                      onTap: () async {
                        if (k.$2 == 'Instagram') {
                          bukaInstagram(context);
                          return;
                        }
                        final m = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: k.$3));
                        m.showSnackBar(SnackBar(content: Text('${k.$2} disalin')));
                      },
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
