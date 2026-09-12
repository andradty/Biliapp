import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/landing_page.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_patient_screen.dart';
import 'screens/start_examination_screen.dart';
import 'screens/result_screen.dart';
import 'screens/patient_history_screen.dart';
import 'screens/device_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const BilinovaApp());
}

class BilinovaApp extends StatelessWidget {
  const BilinovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BILINOVA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0B6E4F),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/dashboard': (context) => const DashboardScreen(),
        '/add-patient': (context) => const AddPatientScreen(),
        '/start-exam': (context) => const StartExaminationScreen(),
        '/result': (context) => const ResultScreen(),
        '/history': (context) => const PatientHistoryScreen(),
        '/device-setup': (context) => const DeviceSetupScreen(),
      },
    );
  }
}