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

  // Stream to notify UI when an alarm is actively ringing or test triggered
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

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, RepeatType repeatType) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (repeatType == RepeatType.weekdays) {
      while (scheduledDate.weekday == DateTime.friday ||
          scheduledDate.weekday == DateTime.saturday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    } else if (repeatType == RepeatType.weekends) {
      while (scheduledDate.weekday != DateTime.friday &&
          scheduledDate.weekday != DateTime.saturday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    return scheduledDate;
  }

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;
    await initialize();

    final scheduledDate =
        _nextInstanceOfTime(alarm.hour, alarm.minute, alarm.repeatType);

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
      debugPrint('Alarm [${alarm.id}] scheduled for: $scheduledDate');
    } catch (e) {
      debugPrint('Failed to zonedSchedule alarm: $e');
    }
  }

  Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id: id);
    debugPrint('Alarm [$id] cancelled.');
  }

  // Trigger preview / test alarm directly
  Future<void> triggerAlarm(AlarmModel alarm) async {
    _isRinging = true;
    _currentRingingAlarm = alarm;
    _alarmTriggeredController.add(alarm);

    final details = _buildNotificationDetails(
      title: alarm.label,
      tone: alarm.tone,
      vibrate: alarm.isVibrate,
    );

    await _notificationsPlugin.show(
      id: alarm.id,
      title: '⏰ المنبه يرن الآن!',
      body: '${alarm.label} - ${alarm.formattedTime}',
      notificationDetails: details,
    );

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(
        UrlSource(
          'https://actions.google.com/sounds/v1/alarms/beep_short.ogg',
        ),
      );
    } catch (e) {
      debugPrint('Audio playback note: $e');
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
      id: alarm.id + 1000,
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
      final defaultAlarms = [
        AlarmModel(
          id: 1,
          hour: 6,
          minute: 30,
          label: 'صلاة الفجر والورد الصباحي',
          isEnabled: true,
          repeatType: RepeatType.daily,
          tone: 'نغمة هادئة (Chime)',
        ),
        AlarmModel(
          id: 2,
          hour: 8,
          minute: 0,
          label: 'بدء العمل والمذاكرة',
          isEnabled: false,
          repeatType: RepeatType.weekdays,
          tone: 'إلكتروني حديث (Digital)',
        ),
      ];
      await saveAlarms(defaultAlarms);
      return defaultAlarms;
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
