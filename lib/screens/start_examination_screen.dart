// lib/screens/start_examination_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'result_screen.dart';

class StartExaminationScreen extends StatefulWidget {
  const StartExaminationScreen({super.key});

  @override
  State<StartExaminationScreen> createState() => _StartExaminationScreenState();
}

class _StartExaminationScreenState extends State<StartExaminationScreen> {
  final Color _primaryColor = const Color(0xFF0B6E4F);
  
  String _statusMessage = "Menghubungkan ke device...";
  IconData _statusIcon = Icons.bluetooth_searching_outlined;
  bool _isConnected = false;
  bool _isMeasuring = false;

  @override
  void initState() {
    super.initState();
    _simulateProcess();
  }

  void _simulateProcess() {
    // Simulate connection delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _statusMessage = "Terhubung";
          _statusIcon = Icons.bluetooth_connected_outlined;
        });

        // Simulate transition to measurement state
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
            _isMeasuring = true;
            _statusMessage = "Menunggu hasil sensor...";
            _statusIcon = Icons.sensors_outlined;
          });
          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ResultScreen()),
              );
            }    
          });
        }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[900]),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: _isMeasuring 
                  ? SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      _statusIcon,
                      size: 48,
                      color: _isConnected ? _primaryColor : Colors.grey[400],
                    ),
              ),
              const SizedBox(height: 32),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isMeasuring) ...[
                const SizedBox(height: 16),
                Text(
                  "Pastikan sensor menempel sempurna pada kulit bayi.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}