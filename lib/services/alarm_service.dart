import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm_model.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  static const String _storageKey = 'saved_alarms_list_v1';

  // In-app active timers map (for desktop/web & live in-app triggering)
  final Map<int, Timer> _activeInMemoryTimers = {};

  // Stream to notify UI when an alarm is actively ringing
  final StreamController<AlarmModel> _alarmTriggeredController =
      StreamController<AlarmModel>.broadcast();
  Stream<AlarmModel> get onAlarmTriggered => _alarmTriggeredController.stream;

  bool _isRinging = false;
  bool get isRinging => _isRinging;
  AlarmModel? _currentRingingAlarm;
  AlarmModel? get currentRingingAlarm => _currentRingingAlarm;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      final String timeZoneName = tz.local.name;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Timezone initialization fallback: $e');
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  NotificationDetails _buildNotificationDetails({
    required String title,
    required String tone,
    required bool vibrate,
  }) {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_service_channel',
      'منبهات التطبيق (Alarms)',
      channelDescription: 'قناة إشعارات المنبهات بصوت واهتزاز عالي الأولوية',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      enableVibration: vibrate,
      playSound: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  DateTime _calculateNextTriggerTime(int hour, int minute, RepeatType repeatType) {
    final now = DateTime.now();
    DateTime target = DateTime(now.year, now.month, now.day, hour, minute);

    if (target.isBefore(now) || target.difference(now).inSeconds <= 0) {
      target = target.add(const Duration(days: 1));
    }

    if (repeatType == RepeatType.weekdays) {
      while (target.weekday == DateTime.friday || target.weekday == DateTime.saturday) {
        target = target.add(const Duration(days: 1));
      }
    } else if (repeatType == RepeatType.weekends) {
      while (target.weekday != DateTime.friday && target.weekday != DateTime.saturday) {
        target = target.add(const Duration(days: 1));
      }
    }

    return target;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, RepeatType repeatType) {
    final target = _calculateNextTriggerTime(hour, minute, repeatType);
    return tz.TZDateTime.from(target, tz.local);
  }

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;
    await initialize();

    // 1. Cancel previous timer if exists
    _activeInMemoryTimers[alarm.id]?.cancel();

    // 2. Schedule in-memory precision Timer (guarantees firing on Windows Desktop & Foreground)
    final targetDateTime = _calculateNextTriggerTime(alarm.hour, alarm.minute, alarm.repeatType);
    final durationUntilTrigger = targetDateTime.difference(DateTime.now());

    if (durationUntilTrigger.isNegative) return;

    _activeInMemoryTimers[alarm.id] = Timer(durationUntilTrigger, () {
      triggerAlarm(alarm);
      // If repeatType == daily or weekdays/weekends, schedule next instance
      if (alarm.repeatType != RepeatType.once) {
        scheduleAlarm(alarm);
      }
    });

    debugPrint('Live in-app timer scheduled for [${alarm.id}] in ${durationUntilTrigger.inMinutes}m ${durationUntilTrigger.inSeconds % 60}s');

    // 3. Also schedule OS level notification (for Android background/lockscreen)
    final scheduledDate = _nextInstanceOfTime(alarm.hour, alarm.minute, alarm.repeatType);
    final details = _buildNotificationDetails(
      title: alarm.label,
      tone: alarm.tone,
      vibrate: alarm.isVibrate,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: alarm.id,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: '⏰ حان موعد المنبه!',
        body: alarm.label.isNotEmpty ? alarm.label : 'استيقظ الآن أو ابدأ مهمتك',
        matchDateTimeComponents:
            alarm.repeatType == RepeatType.daily ? DateTimeComponents.time : null,
      );
    } catch (e) {
      debugPrint('Local notifications zonedSchedule info: $e');
    }
  }

  Future<void> cancelAlarm(int id) async {
    _activeInMemoryTimers[id]?.cancel();
    _activeInMemoryTimers.remove(id);
    await _notificationsPlugin.cancel(id: id);
    debugPrint('Alarm [$id] cancelled.');
  }

  /// Check all alarms on app launch/resume and re-arm timers
  Future<void> rescheduleAllActiveAlarms() async {
    final list = await loadAlarms();
    for (final alarm in list) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }

  // Trigger ringing event
  Future<void> triggerAlarm(AlarmModel alarm) async {
    _isRinging = true;
    _currentRingingAlarm = alarm;
    _alarmTriggeredController.add(alarm);

    // Show OS level alert
    final details = _buildNotificationDetails(
      title: alarm.label,
      tone: alarm.tone,
      vibrate: alarm.isVibrate,
    );

    try {
      await _notificationsPlugin.show(
        id: alarm.id,
        title: '⏰ المنبه يرن الآن!',
        body: '${alarm.label} - ${alarm.formattedTime}',
        notificationDetails: details,
      );
    } catch (_) {}

    // Play ringing sound with fallback
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(
        UrlSource(
          'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
        ),
      );
    } catch (e) {
      debugPrint('Audio playback error fallback: $e');
      try {
        await _audioPlayer.play(
          UrlSource('https://actions.google.com/sounds/v1/alarms/beep_short.ogg'),
        );
      } catch (_) {}
    }
  }

  Future<void> stopRinging() async {
    _isRinging = false;
    _currentRingingAlarm = null;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> snoozeAlarm(AlarmModel alarm, {int minutes = 5}) async {
    await stopRinging();
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final snoozedAlarm = AlarmModel(
      id: alarm.id + 10000,
      hour: snoozeTime.hour,
      minute: snoozeTime.minute,
      label: '${alarm.label} (تأجيل $minutes دقائق)',
      isEnabled: true,
      repeatType: RepeatType.once,
      tone: alarm.tone,
      isVibrate: alarm.isVibrate,
    );
    await scheduleAlarm(snoozedAlarm);
  }

  // Persistence
  Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_storageKey);
    if (stored == null || stored.isEmpty) {
      return [];
    }

    try {
      return stored.map((item) => AlarmModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error parsing saved alarms: $e');
      return [];
    }
  }

  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = alarms.map((a) => a.toJson()).toList();
    await prefs.setStringList(_storageKey, encoded);
  }
}
