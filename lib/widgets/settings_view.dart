import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class InteractiveSettingsView extends StatefulWidget {
  const InteractiveSettingsView({super.key});

  @override
  State<InteractiveSettingsView> createState() => _InteractiveSettingsViewState();
}

class _InteractiveSettingsViewState extends State<InteractiveSettingsView> {
  bool _backgroundNotifications = true;
  bool _vibrationEnabled = true;
  int _snoozeMinutes = 5;
  String _volumeLevel = 'متوسط (Medium)';

  final List<int> _snoozeOptions = [3, 5, 10, 15, 20];
  final List<String> _volumeOptions = ['منخفض (Low)', 'متوسط (Medium)', 'مرتفع (High)'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backgroundNotifications = prefs.getBool('setting_bg_notif') ?? true;
      _vibrationEnabled = prefs.getBool('setting_vibration') ?? true;
      _snoozeMinutes = prefs.getInt('setting_snooze') ?? 5;
      _volumeLevel = prefs.getString('setting_volume') ?? 'متوسط (Medium)';
    });
  }

  Future<void> _savePreference(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is bool) {
      await prefs.setBool(key, val);
    } else if (val is int) {
      await prefs.setInt(key, val);
    } else if (val is String) {
      await prefs.setString(key, val);
    }
  }

  void _showSnoozePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر مدة التأجيل الافتراضية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ..._snoozeOptions.map((mins) {
                final isSelected = _snoozeMinutes == mins;
                return ListTile(
                  title: Text(
                    '$mins دقائق',
                    style: TextStyle(
                      color: isSelected ? AppTheme.activeAccent : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppTheme.activeAccent)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () {
                    setState(() => _snoozeMinutes = mins);
                    _savePreference('setting_snooze', mins);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showVolumePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مستوى صوت التنبيه',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ..._volumeOptions.map((vol) {
                final isSelected = _volumeLevel == vol;
                return ListTile(
                  title: Text(
                    vol,
                    style: TextStyle(
                      color: isSelected ? AppTheme.activeAccent : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppTheme.activeAccent)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () {
                    setState(() => _volumeLevel = vol);
                    _savePreference('setting_volume', vol);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.alarm_rounded, color: AppTheme.activeAccent, size: 40),
        title: const Text('ساعة Clocky', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'تطبيق منبه ومؤقت ذكي مبني بأحدث معايير Material Design 3 (Material You).\nالإصدار: v1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(color: AppTheme.activeAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Text(
            'عام والتنبيهات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.sectionHeader,
            ),
          ),
        ),

        // Background Notifications Switch
        _buildInteractiveCard(
          icon: Icons.notifications_active_outlined,
          title: 'إشعارات الخلفية',
          subtitle: _backgroundNotifications
              ? 'مفعلة (يرن المنبه حتى لو كان التطبيق مغلقاً)'
              : 'معطلة',
          trailing: Switch(
            value: _backgroundNotifications,
            onChanged: (val) {
              setState(() => _backgroundNotifications = val);
              _savePreference('setting_bg_notif', val);
            },
          ),
        ),
        const SizedBox(height: 10),

        // Vibration Switch
        _buildInteractiveCard(
          icon: Icons.vibration_rounded,
          title: 'الاهتزاز مع المنبه',
          subtitle: _vibrationEnabled ? 'الاهتزاز نشط تلقائياً' : 'بدون اهتزاز',
          trailing: Switch(
            value: _vibrationEnabled,
            onChanged: (val) {
              setState(() => _vibrationEnabled = val);
              _savePreference('setting_vibration', val);
            },
          ),
        ),
        const SizedBox(height: 10),

        // Snooze duration selector
        _buildInteractiveCard(
          icon: Icons.snooze_rounded,
          title: 'مدة التأجيل الافتراضية',
          subtitle: '$_snoozeMinutes دقائق عند الضغط على تأجيل',
          trailing: TextButton.icon(
            onPressed: _showSnoozePicker,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.activeContainer.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.activeAccent),
            label: Text(
              '$_snoozeMinutes د',
              style: const TextStyle(
                color: AppTheme.activeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: _showSnoozePicker,
        ),
        const SizedBox(height: 10),

        // Volume Level
        _buildInteractiveCard(
          icon: Icons.volume_up_outlined,
          title: 'مستوى صوت الرنين',
          subtitle: _volumeLevel,
          trailing: const Icon(Icons.chevron_left_rounded, color: AppTheme.textSecondary),
          onTap: _showVolumePicker,
        ),

        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Text(
            'المظهر والمعلومات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.sectionHeader,
            ),
          ),
        ),

        // Theme info
        _buildInteractiveCard(
          icon: Icons.brightness_6_rounded,
          title: 'المظهر (Theme)',
          subtitle: 'Material You Dark Teal (#0E1B18)',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.activeContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'داكن',
              style: TextStyle(
                color: AppTheme.activeAccent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // About app dialog
        _buildInteractiveCard(
          icon: Icons.info_outline_rounded,
          title: 'عن التطبيق',
          subtitle: 'Clocky • v1.0.0 Material You',
          trailing: const Icon(Icons.chevron_left_rounded, color: AppTheme.textSecondary),
          onTap: _showAboutDialog,
        ),
      ],
    );
  }

  Widget _buildInteractiveCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          ),
        ),
      ),
    );
  }
}
