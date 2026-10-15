import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../theme/app_theme.dart';

class RingingDialog extends StatefulWidget {
  final AlarmModel alarm;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;

  const RingingDialog({
    super.key,
    required this.alarm,
    required this.onDismiss,
    required this.onSnooze,
  });

  @override
  State<RingingDialog> createState() => _RingingDialogState();
}

class _RingingDialogState extends State<RingingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  double _snoozeScale = 1.0;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: AppTheme.activeAccent.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.activeAccent.withValues(alpha: 0.15),
              blurRadius: 35,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Pulsing & Rotating Bell
            AnimatedBuilder(
              animation: _bellController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.activeContainer.withValues(alpha: 0.6),
                        border: Border.all(
                          color: AppTheme.activeAccent,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.alarm_on_rounded,
                        size: 58,
                        color: AppTheme.activeAccent,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              widget.alarm.formattedTime,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w300,
                color: AppTheme.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.alarm.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.activeAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'النغمة: ${widget.alarm.tone}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons: Snooze & Dismiss
            Row(
              children: [
                // Animated Snooze Button
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _snoozeScale = 0.92),
                    onTapUp: (_) {
                      setState(() => _snoozeScale = 1.0);
                      widget.onSnooze();
                    },
                    onTapCancel: () => setState(() => _snoozeScale = 1.0),
                    child: AnimatedScale(
                      scale: _snoozeScale,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.snooze_rounded,
                                color: AppTheme.activeAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'تأجيل 5 د',
                              style: TextStyle(
                                color: AppTheme.activeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Dismiss Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A),
                      foregroundColor: const Color(0xFFFFDAD6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'إيقاف',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
