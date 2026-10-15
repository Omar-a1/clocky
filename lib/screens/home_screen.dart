import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/alarm_card.dart';
import '../widgets/add_alarm_sheet.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/ringing_dialog.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmService _alarmService = AlarmService();
  List<AlarmModel> _alarms = [];
  bool _isLoading = true;
  int _currentNavIndex = 0; // 0: Timer / Alarms, 1: Settings

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  StreamSubscription<AlarmModel>? _alarmSub;

  @override
  void initState() {
    super.initState();
    _loadAlarms();

    // Clock ticker every second
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
            backgroundColor: AppTheme.cardColor,
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
          backgroundColor: AppTheme.cardColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'تراجع',
            textColor: AppTheme.activeAccent,
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
          content: Text('تم ضبط المنبه بنجاح: ${alarm.formattedTime}'),
          backgroundColor: AppTheme.cardColor,
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
              backgroundColor: AppTheme.cardColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('ساعة Google'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppTheme.textPrimary,
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _currentNavIndex == 0 ? _buildTimerTab() : _buildSettingsTab(),
      ),
      bottomNavigationBar: GoogleClockNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
        },
      ),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddAlarmSheet,
              backgroundColor: AppTheme.activeAccent,
              foregroundColor: const Color(0xFF003731),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22), // Rounded squircle FAB
              ),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildTimerTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.activeAccent),
      );
    }

    // Categorize into sections strictly matching Google Clock: 'Wake up' and 'Other'
    final wakeUpAlarms = <AlarmModel>[];
    final otherAlarms = <AlarmModel>[];

    for (final alarm in _alarms) {
      final labelLower = alarm.label.toLowerCase();
      // Morning / Wake up hours (5 AM to 10 AM) or label containing wake/استيقاظ/صباح
      final isMorningHour = alarm.hour >= 5 && alarm.hour <= 10;
      final isWakeUpKeyword = labelLower.contains('wake') ||
          labelLower.contains('استيقاظ') ||
          labelLower.contains('صباح') ||
          labelLower.contains('fajr') ||
          labelLower.contains('فجر');

      if (isWakeUpKeyword || isMorningHour) {
        wakeUpAlarms.add(alarm);
      } else {
        otherAlarms.add(alarm);
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Digital Live Time Sub-Header
        SliverToBoxAdapter(
          child: _buildDigitalClockHeader(),
        ),

        if (_alarms.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else ...[
          // Wake up section
          if (wakeUpAlarms.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader('Wake up', 'استيقاظ'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final alarm = wakeUpAlarms[index];
                  final originalIndex = _alarms.indexOf(alarm);
                  return AlarmCard(
                    key: ValueKey(alarm.id),
                    alarm: alarm,
                    onToggle: (val) => _toggleAlarm(alarm, val),
                    onDelete: () => _deleteAlarm(originalIndex),
                    onTest: () => _alarmService.triggerAlarm(alarm),
                  );
                },
                childCount: wakeUpAlarms.length,
              ),
            ),
          ],

          // Other section
          if (otherAlarms.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader('Other', 'أخرى'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final alarm = otherAlarms[index];
                  final originalIndex = _alarms.indexOf(alarm);
                  return AlarmCard(
                    key: ValueKey(alarm.id),
                    alarm: alarm,
                    onToggle: (val) => _toggleAlarm(alarm, val),
                    onDelete: () => _deleteAlarm(originalIndex),
                    onTest: () => _alarmService.triggerAlarm(alarm),
                  );
                },
                childCount: otherAlarms.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String englishTitle, String arabicSubtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Text(
            englishTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.sectionHeader,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• $arabicSubtitle',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalClockHeader() {
    final timeStr = DateFormat('hh:mm').format(_currentTime);
    final secondStr = DateFormat('ss').format(_currentTime);
    final periodStr = DateFormat('a').format(_currentTime) == 'AM' ? 'ص' : 'م';
    final dateStr = DateFormat('EEEE، d MMMM', 'ar').format(_currentTime);
    final activeCount = _alarms.where((a) => a.isEnabled).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ':$secondStr',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.activeAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      periodStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.activeContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alarm_on_rounded,
                    size: 16,
                    color: AppTheme.activeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$activeCount نشط',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.activeAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.cardColor,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 56,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'لا يوجد منبهات حالياً',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اضغط على زر (+) في الأسفل لإضافة منبه جديد',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'عام',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.sectionHeader,
            ),
          ),
        ),
        _buildSettingCard(
          icon: Icons.brightness_6_rounded,
          title: 'المظهر (Theme)',
          subtitle: 'Google Clock Dark Theme (Material You)',
          trailing: const Text(
            'داكن',
            style: TextStyle(
              color: AppTheme.activeAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildSettingCard(
          icon: Icons.notifications_active_outlined,
          title: 'إشعارات الخلفية',
          subtitle: 'تفعيل التنبيهات الدقيقة حتى عند إغلاق التطبيق',
          trailing: const Icon(Icons.check_circle_rounded, color: AppTheme.activeAccent),
        ),
        const SizedBox(height: 10),
        _buildSettingCard(
          icon: Icons.vibration_rounded,
          title: 'الاهتزاز الافتراضي',
          subtitle: 'اهتزاز تدريجي عند انطلاق الرنين',
          trailing: const Icon(Icons.check_circle_rounded, color: AppTheme.activeAccent),
        ),
        const SizedBox(height: 10),
        _buildSettingCard(
          icon: Icons.snooze_rounded,
          title: 'مدة التأجيل الافتراضية',
          subtitle: '5 دقائق',
          trailing: const Text(
            '5 د',
            style: TextStyle(
              color: AppTheme.activeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'حول',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.sectionHeader,
            ),
          ),
        ),
        _buildSettingCard(
          icon: Icons.info_outline_rounded,
          title: 'ساعة Google (Clock)',
          subtitle: 'Material You Design 3 • Inspired UI',
          trailing: const Icon(Icons.chevron_left_rounded, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.activeContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.activeAccent, size: 22),
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
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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
