// lib/screens/device_setup_screen.dart
import 'package:flutter/material.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final int _totalSteps = 3;
  final Color _primaryColor = const Color(0xFF0B6E4F);

  final List<Map<String, String>> _setupSteps = [
    {
      'title': 'Nyalakan Perangkat',
      'description': 'Tekan dan tahan tombol power pada alat BILINOVA hingga lampu indikator berwarna biru berkedip.',
      'icon': 'power_settings_new_outlined',
    },
    {
      'title': 'Hubungkan ke WiFi Puskesmas',
      'description': 'Pastikan smartphone Anda sudah terhubung dengan jaringan WiFi Puskesmas agar data dapat tersinkronisasi.',
      'icon': 'wifi_outlined',
    },
    {
      'title': 'Sinkronisasi Alat',
      'description': 'Dekatkan smartphone Anda dengan alat BILINOVA untuk memulai proses pairing otomatis.',
      'icon': 'sync_outlined',
    },
  ];

  IconData _getIconForStep(String iconName) {
    switch (iconName) {
      case 'power_settings_new_outlined':
        return Icons.power_settings_new_outlined;
      case 'wifi_outlined':
        return Icons.wifi_outlined;
      case 'sync_outlined':
        return Icons.sync_outlined;
      default:
        return Icons.device_unknown_outlined;
    }
  }

  void _nextStep() {
    if (_currentIndex < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[900]),
        title: Text(
          'Setup Alat Baru',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _totalSteps,
            backgroundColor: Colors.grey[200],
            color: _primaryColor,
            minHeight: 4,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _totalSteps,
              itemBuilder: (context, index) {
                final step = _setupSteps[index];
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Icon(
                          _getIconForStep(step['icon']!),
                          size: 32,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step['title']!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step['description']!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Kembali'),
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentIndex == _totalSteps - 1 ? 'Selesai' : 'Selanjutnya',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}