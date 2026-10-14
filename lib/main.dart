import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/alarm_service.dart';
import 'screens/home_screen.dart';

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
      title: 'منبه ذكي | Alarm App',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0F1D),
          elevation: 0,
          centerTitle: true,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF38BDF8);
            }
            return Colors.grey.shade400;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF38BDF8).withValues(alpha: 0.35);
            }
            return Colors.grey.shade800;
          }),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

