// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

import 'add_patient_screen.dart';
import 'start_examination_screen.dart';
import 'patient_history_screen.dart';
import 'device_setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Normal', 'Warning', 'Kritis'];
  final Color _primaryColor = const Color(0xFF0B6E4F);

  // Dummy data
  final List<Map<String, dynamic>> _recentExams = [
    {
      'name': 'Bayi Nyonya Siti',
      'date': '12 Sep 2026, 09:30',
      'status': 'Normal',
      'statusColor': Colors.green[700],
    },
    {
      'name': 'Bayi Nyonya Budi',
      'date': '12 Sep 2026, 10:15',
      'status': 'Warning',
      'statusColor': Colors.orange[700],
    },
    {
      'name': 'Bayi Nyonya Ayu',
      'date': '11 Sep 2026, 14:20',
      'status': 'Kritis',
      'statusColor': Colors.red[700],
    },
    {
      'name': 'Bayi Nyonya Rina',
      'date': '11 Sep 2026, 08:45',
      'status': 'Normal',
      'statusColor': Colors.green[700],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'BILINOVA',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey[700]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceSetupScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                style: TextStyle(color: Colors.grey[900]),
                decoration: InputDecoration(
                  hintText: 'Cari nama pasien atau No. RM',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.search_outlined,
                    color: Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: List.generate(_filters.length, (index) {
                final isSelected = _selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(_filters[index]),
                    labelStyle: TextStyle(
                      color: isSelected ? _primaryColor : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: _primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? _primaryColor : Colors.grey[300]!,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Pemeriksaan Terakhir',
              style: TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              itemCount: _recentExams.length,
              itemBuilder: (context, index) {
                final exam = _recentExams[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientHistoryScreen(),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exam['name'],
                                style: TextStyle(
                                  color: Colors.grey[900],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                exam['date'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          _StatusBadge(
                            label: exam['status'],
                            color: exam['statusColor'],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.person_add_outlined,
                      color: _primaryColor,
                    ),
                    title: const Text('Tambah Pasien Baru'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddPatientScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.sensors_outlined, color: _primaryColor),
                    title: const Text('Mulai Pemeriksaan'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StartExaminationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add_outlined, color: Colors.white),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}