import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  // Input duration in hours, minutes, seconds
  int _inputHours = 0;
  int _inputMinutes = 5;
  int _inputSeconds = 0;

  // Running state
  Timer? _countdownTimer;
  int _totalSecondsRemaining = 0;
  int _initialTotalSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final total = (_inputHours * 3600) + (_inputMinutes * 60) + _inputSeconds;
    if (total <= 0) return;

    setState(() {
      _initialTotalSeconds = total;
      _totalSecondsRemaining = total;
      _isRunning = true;
      _isPaused = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_totalSecondsRemaining > 1) {
        setState(() {
          _totalSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _totalSecondsRemaining = 0;
          _isRunning = false;
          _isPaused = false;
        });
        _showTimerCompleteDialog();
      }
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_totalSecondsRemaining > 1) {
        setState(() {
          _totalSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _totalSecondsRemaining = 0;
          _isRunning = false;
          _isPaused = false;
        });
        _showTimerCompleteDialog();
      }
    });
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _totalSecondsRemaining = 0;
    });
  }

  void _addMinutes(int mins) {
    if (_isRunning) {
      setState(() {
        _totalSecondsRemaining += mins * 60;
        _initialTotalSeconds += mins * 60;
      });
    } else {
      setState(() {
        _inputMinutes = (_inputMinutes + mins) % 60;
      });
    }
  }

  void _showTimerCompleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.timer_rounded, color: AppTheme.activeAccent, size: 48),
        title: const Text(
          'انتهى الوقت!',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'تم انتهاء المؤقت المحدد بنجاح ⏱️',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً', style: TextStyle(color: AppTheme.activeAccent)),
          ),
        ],
      ),
    );
  }

  String _formatRemainingTime() {
    final h = _totalSecondsRemaining ~/ 3600;
    final m = (_totalSecondsRemaining % 3600) ~/ 60;
    final s = _totalSecondsRemaining % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isRunning || _isPaused) {
      return _buildRunningView();
    }
    return _buildPickerView();
  }

  // Active Running Timer view with circular progress
  Widget _buildRunningView() {
    final progress = _initialTotalSeconds > 0
        ? _totalSecondsRemaining / _initialTotalSeconds
        : 0.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.cardColor,
                      color: AppTheme.activeAccent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatRemainingTime(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isPaused ? 'متوقف مؤقتاً' : 'جارٍ الحساب...',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Quick add time buttons
            Wrap(
              spacing: 12,
              children: [
                _buildQuickAddChip('+1 دقيقة', () => _addMinutes(1)),
                _buildQuickAddChip('+5 دقائق', () => _addMinutes(5)),
              ],
            ),
            const SizedBox(height: 36),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                IconButton.filledTonal(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.cardColor,
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 28),

                // Play / Pause Main FAB
                FloatingActionButton.large(
                  onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                  backgroundColor: AppTheme.activeAccent,
                  foregroundColor: const Color(0xFF003731),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Timer Setup / Keypad-picker view
  Widget _buildPickerView() {
    final quickPresets = [1, 3, 5, 10, 15, 30];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            'تعيين المؤقت (Timer)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Duration Card with up/down controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUnitColumn('ساعات', _inputHours, (val) {
                  setState(() => _inputHours = val.clamp(0, 23));
                }),
                const Text(':', style: TextStyle(fontSize: 32, color: AppTheme.textSecondary)),
                _buildUnitColumn('دقائق', _inputMinutes, (val) {
                  setState(() => _inputMinutes = val.clamp(0, 59));
                }),
                const Text(':', style: TextStyle(fontSize: 32, color: AppTheme.textSecondary)),
                _buildUnitColumn('ثواني', _inputSeconds, (val) {
                  setState(() => _inputSeconds = val.clamp(0, 59));
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Presets
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'أوقات جاهزة:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickPresets.map((m) {
              return ActionChip(
                label: Text('$m دقيقة'),
                backgroundColor: AppTheme.cardColor,
                labelStyle: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
                onPressed: () {
                  setState(() {
                    _inputHours = 0;
                    _inputMinutes = m;
                    _inputSeconds = 0;
                  });
                  _startTimer();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          // Start FAB
          FloatingActionButton.large(
            onPressed: (_inputHours > 0 || _inputMinutes > 0 || _inputSeconds > 0)
                ? _startTimer
                : null,
            backgroundColor: AppTheme.activeAccent,
            foregroundColor: const Color(0xFF003731),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitColumn(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppTheme.activeAccent),
          onPressed: () => onChanged(value + 1),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w300,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.activeAccent),
          onPressed: () => onChanged(value - 1),
        ),
      ],
    );
  }

  Widget _buildQuickAddChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppTheme.cardColor,
      labelStyle: const TextStyle(color: AppTheme.activeAccent, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.navBarIndicator),
      ),
      onPressed: onTap,
    );
  }
}
