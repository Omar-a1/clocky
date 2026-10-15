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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Swipe slider state (-1.0 = full left / Snooze, +1.0 = full right / Stop)
  double _dragOffset = 0.0;
  final double _maxDrag = 120.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(-_maxDrag, _maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset <= -_maxDrag * 0.75) {
      // Swiped Left -> Snooze
      widget.onSnooze();
    } else if (_dragOffset >= _maxDrag * 0.75) {
      // Swiped Right -> Stop / Dismiss
      widget.onDismiss();
    } else {
      // Spring back to center
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current time digits and period
    final parts = widget.alarm.formattedTime.split(' ');
    final timeStr = parts.isNotEmpty ? parts[0] : widget.alarm.formattedTime;
    final period = parts.length > 1 ? parts[1] : '';

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: AppTheme.activeAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 40,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: AppTheme.activeAccent.withValues(alpha: 0.15),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Alarm Icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cardColor,
                    border: Border.all(
                      color: AppTheme.activeAccent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.activeAccent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.alarm_on_rounded,
                    size: 48,
                    color: AppTheme.activeAccent,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Large Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  if (period.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      period,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.activeAccent,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Alarm Label
              Text(
                widget.alarm.label.isNotEmpty ? widget.alarm.label : 'المنبه الذكي',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.activeAccent,
                ),
              ),

              const SizedBox(height: 6),
              Text(
                widget.alarm.tone,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // --- Material You Interactive Slider (Left: Snooze, Right: Stop) ---
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Guide Labels & Icons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Snooze
                          Row(
                            children: [
                              const Icon(Icons.snooze_rounded, color: AppTheme.activeAccent, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'تأجيل',
                                style: TextStyle(
                                  color: AppTheme.activeAccent.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          // Right side: Stop
                          Row(
                            children: [
                              const Text(
                                'إيقاف',
                                style: TextStyle(
                                  color: Color(0xFFFF897D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.close_rounded, color: Color(0xFFFF897D), size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Draggable Center Handle Pill
                    Transform.translate(
                      offset: Offset(_dragOffset, 0),
                      child: GestureDetector(
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                        child: Container(
                          width: 80,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _dragOffset < -20
                                ? AppTheme.activeContainer
                                : (_dragOffset > 20
                                    ? const Color(0xFF93000A)
                                    : AppTheme.activeAccent),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _dragOffset < -20
                                ? Icons.snooze_rounded
                                : (_dragOffset > 20
                                    ? Icons.stop_rounded
                                    : Icons.drag_handle_rounded),
                            color: (_dragOffset < -20 || _dragOffset > 20)
                                ? Colors.white
                                : const Color(0xFF003731),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Helper text
              Text(
                '← اسحب لليسار للتأجيل  |  اسحب لليمين للإيقاف →',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
