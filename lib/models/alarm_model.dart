import 'dart:convert';
import 'package:flutter/material.dart';

enum RepeatType { once, daily, weekdays, weekends }

class AlarmModel {
  final int id;
  final int hour;
  final int minute;
  final String label;
  bool isEnabled;
  final RepeatType repeatType;
  final String tone;
  final bool isVibrate;

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    this.isEnabled = true,
    this.repeatType = RepeatType.daily,
    this.tone = 'نغمة هادئة (Chime)',
    this.isVibrate = true,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String get formattedTime {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }

  String get repeatText {
    switch (repeatType) {
      case RepeatType.once:
        return 'مرة واحدة';
      case RepeatType.daily:
        return 'كل يوم';
      case RepeatType.weekdays:
        return 'أيام العمل (الأحد - الخميس)';
      case RepeatType.weekends:
        return 'عطلة الأسبوع (الجمعة - السبت)';
    }
  }

  String get timeRemainingText {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final diff = scheduled.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours == 0 && minutes == 0) {
      return 'أقل من دقيقة';
    } else if (hours == 0) {
      return 'بعد $minutes دقيقة';
    } else if (minutes == 0) {
      return 'بعد $hours ساعة';
    } else {
      return 'بعد $hours ساعة و $minutes دقيقة';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isEnabled': isEnabled,
      'repeatType': repeatType.index,
      'tone': tone,
      'isVibrate': isVibrate,
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      id: map['id'] as int,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      label: (map['label'] as String?) ?? 'منبه',
      isEnabled: (map['isEnabled'] as bool?) ?? true,
      repeatType: RepeatType.values[(map['repeatType'] as int?) ?? 1],
      tone: (map['tone'] as String?) ?? 'نغمة هادئة (Chime)',
      isVibrate: (map['isVibrate'] as bool?) ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlarmModel.fromJson(String source) =>
      AlarmModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
