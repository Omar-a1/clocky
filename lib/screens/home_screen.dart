import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/alarm_card.dart';
import '../widgets/add_alarm_sheet.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/ringing_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmService _alarmService = AlarmService();
  List<AlarmModel> _alarms = [];
  bool _isLoading = true;
  int _currentNavIndex = 0;

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  StreamSubscription<AlarmModel>? _alarmSub;

  @override
  void initState() {
    super.initState();
    _loadAlarms();

    // Clock ticker every second for live digital header
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Listen for alarms ringing
    _alarmSub = _alarmService.onAlarmTriggered.listen((ringingAlarm) {
      if (mounted) {
        _showRingingDialog(ringingAlarm);
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _alarmSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final list = await _alarmService.loadAlarms();
    if (mounted) {
      setState(() {
        _alarms = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAlarm(AlarmModel alarm, bool enabled) async {
    setState(() {
      alarm.isEnabled = enabled;
    });
    await _alarmService.saveAlarms(_alarms);

    if (enabled) {
      await _alarmService.scheduleAlarm(alarm);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تفعيل المنبه (${alarm.formattedTime})'),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _alarmService.cancelAlarm(alarm.id);
    }
  }

  Future<void> _deleteAlarm(int index) async {
    final deleted = _alarms[index];
    setState(() {
      _alarms.removeAt(index);
    });
    await _alarmService.cancelAlarm(deleted.id);
    await _alarmService.saveAlarms(_alarms);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف منبه ${deleted.label}'),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'تراجع',
            textColor: const Color(0xFF38BDF8),
            onPressed: () {
              setState(() {
                _alarms.insert(index, deleted);
              });
              _alarmService.saveAlarms(_alarms);
              if (deleted.isEnabled) {
                _alarmService.scheduleAlarm(deleted);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _addAlarm(AlarmModel alarm) async {
    setState(() {
      _alarms.insert(0, alarm);
    });
    await _alarmService.saveAlarms(_alarms);
    await _alarmService.scheduleAlarm(alarm);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ المنبه بنجاح: ${alarm.formattedTime}'),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _showAddAlarmSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlarmSheet(onSave: _addAlarm),
    );
  }

  void _showRingingDialog(AlarmModel alarm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RingingDialog(
        alarm: alarm,
        onDismiss: () {
          _alarmService.stopRinging();
          Navigator.pop(context);
        },
        onSnooze: () {
          _alarmService.snoozeAlarm(alarm, minutes: 5);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم تأجيل المنبه 5 دقائق ⏱️'),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: Stack(
        children: [
          // Background subtle gradient glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildCurrentTab(),
                ),
                // Padding for floating navbar height
                const SizedBox(height: 90),
              ],
            ),
          ),

          // Floating Navigation Bar at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() => _currentNavIndex = index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _currentNavIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.extended(
                onPressed: _showAddAlarmSheet,
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 8,
                icon: const Icon(Icons.add_alarm_rounded, size: 24),
                label: const Text(
                  'منبه جديد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentNavIndex) {
      case 0:
        return _buildAlarmsList();
      case 1:
        return _buildQuickTimerTab();
      case 2:
        return _buildSettingsTab();
      default:
        return _buildAlarmsList();
    }
  }

  Widget _buildHeader() {
    final timeStr = DateFormat('hh:mm').format(_currentTime);
    final secondStr = DateFormat('ss').format(_currentTime);
    final periodStr = DateFormat('a').format(_currentTime) == 'AM' ? 'ص' : 'م';
    final dateStr = DateFormat('EEEE، d MMMM', 'ar').format(_currentTime);

    final activeCount = _alarms.where((a) => a.isEnabled).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المنبه الذكي',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_on_rounded,
                        size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      '$activeCount نشط',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big Live Digital Clock Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E293B).withValues(alpha: 0.8),
                  const Color(0xFF0F172A).withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ':$secondStr',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  periodStr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
      );
    }

    if (_alarms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              ),
              child: const Icon(
                Icons.alarm_add_rounded,
                size: 64,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا يوجد منبهات حالياً',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط على زر (+) في الأسفل لإضافة منبه جديد',
              style: TextStyle(fontSize: 13, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: _alarms.length,
      itemBuilder: (context, index) {
        final alarm = _alarms[index];
        return AlarmCard(
          key: ValueKey(alarm.id),
          alarm: alarm,
          onToggle: (val) => _toggleAlarm(alarm, val),
          onDelete: () => _deleteAlarm(index),
          onTest: () {
            _alarmService.triggerAlarm(alarm);
          },
        );
      },
    );
  }

  // Quick Timer Tab
  Widget _buildQuickTimerTab() {
    final quickMinutes = [1, 5, 10, 15, 20, 30, 45, 60];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مؤقت سريع (Quick Presets)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على أي مدة لبدء منبه سريع بعد انقضاء الوقت مباشرة:',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.4,
              ),
              itemCount: quickMinutes.length,
              itemBuilder: (context, index) {
                final m = quickMinutes[index];
                return InkWell(
                  onTap: () {
                    final target = DateTime.now().add(Duration(minutes: m));
                    final quickAlarm = AlarmModel(
                      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      hour: target.hour,
                      minute: target.minute,
                      label: 'مؤقت سريع ($m دقيقة)',
                      repeatType: RepeatType.once,
                      isEnabled: true,
                    );
                    _addAlarm(quickAlarm);
                    setState(() => _currentNavIndex = 0);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF131B2A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$m',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'دقيقة',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Settings Tab
  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إعدادات المنبه',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          _buildSettingTile(
            icon: Icons.notifications_active_rounded,
            title: 'إشعارات الخلفية',
            subtitle: 'تفعيل التنبيهات حتى عند إغلاق التطبيق',
            trailing: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF38BDF8)),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.vibration_rounded,
            title: 'الاهتزاز الافتراضي',
            subtitle: 'اهتزاز قوي عند الرنين',
            trailing: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF38BDF8)),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.snooze_rounded,
            title: 'مدة التأجيل الافتراضية',
            subtitle: '5 دقائق',
            trailing: const Text(
              '5 د',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.info_outline_rounded,
            title: 'عن التطبيق',
            subtitle: 'Alarm App - Flutter Material 3 v1.0.0',
            trailing: const Icon(Icons.chevron_left_rounded, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF38BDF8), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
