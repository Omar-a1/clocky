import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AddAlarmSheet extends StatefulWidget {
  final Function(AlarmModel) onSave;

  const AddAlarmSheet({super.key, required this.onSave});

  @override
  State<AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<AddAlarmSheet> {
  late TimeOfDay _selectedTime;
  final TextEditingController _labelController =
      TextEditingController(text: 'استيقاظ');
  RepeatType _selectedRepeat = RepeatType.daily;
  String _selectedTone = 'نغمة هادئة (Chime)';
  bool _isVibrate = true;

  final List<String> _tones = [
    'نغمة هادئة (Chime)',
    'إلكتروني حديث (Digital)',
    'جرس كلاسيكي (Bell)',
    'طبيعة وأمواج (Zen Waves)',
    'تنبيه نشط (Energetic Pulse)',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF1E293B),
              hourMinuteColor: const Color(0xFF0F172A),
              hourMinuteTextColor: const Color(0xFF38BDF8),
              dialHandColor: const Color(0xFF38BDF8),
              dialBackgroundColor: const Color(0xFF0F172A),
              dialTextColor: Colors.white,
              entryModeIconColor: const Color(0xFF38BDF8),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedHour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final formattedMinute =
        _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'ص' : 'م';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ضبط منبه جديد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Large Time Picker Card
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF162032)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$formattedHour:$formattedMinute',
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF38BDF8),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      period,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.edit_calendar_rounded,
                      color: Color(0xFF38BDF8),
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Alarm Label
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'اسم المنبه',
                labelStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.label_outline, color: Color(0xFF38BDF8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Repeat Days Section
            const Text(
              'تكرار الأيام:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRepeatChip(RepeatType.daily, 'كل يوم'),
                _buildRepeatChip(RepeatType.weekdays, 'أيام العمل'),
                _buildRepeatChip(RepeatType.weekends, 'عطلة الأسبوع'),
                _buildRepeatChip(RepeatType.once, 'مرة واحدة'),
              ],
            ),
            const SizedBox(height: 18),

            // Tone Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTone,
                  dropdownColor: const Color(0xFF1E293B),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
                  isExpanded: true,
                  items: _tones.map((tone) {
                    return DropdownMenuItem<String>(
                      value: tone,
                      child: Row(
                        children: [
                          const Icon(Icons.music_note_rounded,
                              size: 18, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 10),
                          Text(
                            tone,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTone = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Vibration switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.vibration_rounded,
                          color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 10),
                      Text('الاهتزاز',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isVibrate,
                    activeThumbColor: const Color(0xFF38BDF8),
                    onChanged: (val) => setState(() => _isVibrate = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: () {
                final alarm = AlarmModel(
                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  hour: _selectedTime.hour,
                  minute: _selectedTime.minute,
                  label: _labelController.text.trim().isEmpty
                      ? 'منبه'
                      : _labelController.text.trim(),
                  repeatType: _selectedRepeat,
                  tone: _selectedTone,
                  isVibrate: _isVibrate,
                  isEnabled: true,
                );
                widget.onSave(alarm);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
              ),
              child: const Text(
                'حفظ المنبه',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatChip(RepeatType type, String label) {
    final isSelected = _selectedRepeat == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0F172A) : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF38BDF8)
            : Colors.white.withValues(alpha: 0.1),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) {
        setState(() => _selectedRepeat = type);
      },
    );
  }
}
