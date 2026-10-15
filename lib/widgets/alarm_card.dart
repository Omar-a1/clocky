import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../theme/app_theme.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = alarm.isEnabled;

    // Split formatted time into digits and period (e.g. "07:30 ص" or "07:30 AM")
    final parts = alarm.formattedTime.split(' ');
    final timeDigits = parts.isNotEmpty ? parts[0] : alarm.formattedTime;
    final period = parts.length > 1 ? parts[1] : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled ? AppTheme.cardColor : AppTheme.cardColorInactive,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isEnabled
              ? AppTheme.activeAccent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: High-contrast large digits & M3 Switch on the right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          timeDigits,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300, // Clean thin weight
                            letterSpacing: -1.0,
                            color: isEnabled
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        if (period.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            period,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: isEnabled
                                  ? AppTheme.activeAccent
                                  : AppTheme.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Right side M3 Switch
                  Switch(
                    value: isEnabled,
                    onChanged: onToggle,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Middle Row: Alarm Label and Repeat chip/days
              Row(
                children: [
                  Icon(
                    Icons.label_outline_rounded,
                    size: 16,
                    color: isEnabled
                        ? AppTheme.activeAccent
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      alarm.label.isEmpty ? 'منبه' : alarm.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isEnabled
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? AppTheme.activeContainer.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      alarm.repeatText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isEnabled
                            ? AppTheme.activeAccentMuted
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(
                color: Colors.white.withValues(alpha: 0.06),
                height: 1,
              ),
              const SizedBox(height: 8),

              // Bottom Row: Remaining time info & Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: isEnabled
                            ? AppTheme.activeAccent
                            : AppTheme.textSecondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEnabled
                            ? alarm.timeRemainingText
                            : 'المنبه متوقف',
                        style: TextStyle(
                          fontSize: 12,
                          color: isEnabled
                              ? AppTheme.textPrimary.withValues(alpha: 0.8)
                              : AppTheme.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'تجربة التنبيه',
                        icon: const Icon(Icons.volume_up_outlined, size: 20),
                        color: isEnabled ? AppTheme.activeAccent : AppTheme.textSecondary,
                        visualDensity: VisualDensity.compact,
                        onPressed: onTest,
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        color: AppTheme.textSecondary,
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
