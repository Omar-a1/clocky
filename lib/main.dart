import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/alarm_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Arabic locale symbols for intl
  await initializeDateFormatting('ar', null);

  // Initialize Alarm Service & Notification channels
  final alarmService = AlarmService();
  await alarmService.initialize();

  runApp(const ModernAlarmApp());
}

class ModernAlarmApp extends StatelessWidget {
  const ModernAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock - ساعة جوجل',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
