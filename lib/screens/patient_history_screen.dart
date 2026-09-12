// lib/screens/patient_history_screen.dart
import 'package:flutter/material.dart';

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  final List<Map<String, dynamic>> _historyData = const [
    {
      'date': '12 Sep 2026',
      'time': '09:30',
      'value': '14.2 mg/dL',
      'status': 'Warning',
      'isWarning': true,
    },
    {
      'date': '11 Sep 2026',
      'time': '15:00',
      'value': '11.5 mg/dL',
      'status': 'Normal',
      'isWarning': false,
    },
    {
      'date': '10 Sep 2026',
      'time': '08:15',
      'value': '10.1 mg/dL',
      'status': 'Normal',
      'isWarning': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[900]),
        title: Text(
          'Riwayat Pasien',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bayi Nyonya Siti',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM: 0928374 • Laki-laki',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: Colors.grey[50],
            child: Text(
              'HASIL PEMERIKSAAN SEBELUMNYA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _historyData.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[200],
                height: 1,
              ),
              itemBuilder: (context, index) {
                final item = _historyData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['date'],
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['time'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            item['value'],
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item['isWarning'] ? Colors.orange[700] : Colors.green[700],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}