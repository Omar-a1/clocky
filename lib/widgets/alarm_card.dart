import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmCard extends StatefulWidget {
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
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.alarm.isEnabled) {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AlarmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alarm.isEnabled != oldWidget.alarm.isEnabled) {
      if (widget.alarm.isEnabled) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.alarm.isEnabled;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFF1E293B)
              : const Color(0xFF131B2A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEnabled
                ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
            width: isEnabled ? 1.5 : 1.0,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Digital Time Display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.alarm.formattedTime.split(' ')[0],
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: isEnabled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.alarm.formattedTime.split(' ').length > 1
                            ? widget.alarm.formattedTime.split(' ')[1]
                            : '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isEnabled
                              ? const Color(0xFF38BDF8)
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
                // Toggle Switch
                Switch.adaptive(
                  value: isEnabled,
                  activeThumbColor: const Color(0xFF38BDF8),
                  activeTrackColor:
                      const Color(0xFF38BDF8).withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.grey.shade600,
                  inactiveTrackColor: Colors.grey.shade800,
                  onChanged: (val) {
                    widget.onToggle(val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Label & Repeat
            Row(
              children: [
                Icon(
                  Icons.alarm,
                  size: 16,
                  color: isEnabled
                      ? const Color(0xFFF59E0B)
                      : Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.alarm.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Repeat Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.alarm.repeatText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled
                          ? Colors.white70
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            // Footer: Remaining time & actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time Remaining Pill
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: isEnabled
                          ? const Color(0xFF38BDF8)
                          : Colors.white24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEnabled
                          ? widget.alarm.timeRemainingText
                          : 'المنبه متوقف',
                      style: TextStyle(
                        fontSize: 12,
                        color: isEnabled
                            ? const Color(0xFF38BDF8)
                            : Colors.white30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Action Buttons
                Row(
                  children: [
                    // Test sound button
                    IconButton(
                      tooltip: 'تجربة الصوت',
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                      color: const Color(0xFFF59E0B),
                      onPressed: widget.onTest,
                    ),
                    // Delete button
                    IconButton(
                      tooltip: 'حذف المنبه',
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
