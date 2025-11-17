import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/player_profile_service.dart';
import '../../core/services/rate_app_service.dart';
import '../../core/services/user_settings_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/level_progression_service.dart';
import '../../core/services/daily_rewards_service.dart';
import '../../core/monetization/monetization_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserSettingsService _settingsService = UserSettingsService.instance;
  final PlayerProfileService _profileService = PlayerProfileService.instance;
  late Future<void> _initialization;
  double? _pendingDifficulty;

  @override
  void initState() {
    super.initState();
    _initialization = _settingsService.ensureInitialized();
    _profileService.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initialization,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return ValueListenableBuilder<UserSettings>(
              valueListenable: _settingsService.settings,
              builder: (context, settings, _) {
                return ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
                  children: [
                    // Player Profile Stats Section
                    _buildProfileStatsSection(),
                    SizedBox(height: 3.h),

                    _SettingsSection(
                      title: 'Audio',
                      children: [
                        _SettingsTile.switchTile(
                          icon: Icons.graphic_eq,
                          title: 'Sound effects',
                          subtitle: 'Toggles item sorting and UI effects',
                          value: settings.soundEffectsEnabled,
                          onChanged: (value) {
                            _settingsService.setSoundEffectsEnabled(value);
                            _profileService.markAudioCustomized();
                          },
                        ),
                        _SettingsTile.switchTile(
                          icon: Icons.music_note,
                          title: 'Background music',
                          subtitle:
                              'Relaxing playlists that adapt to difficulty',
                          value: settings.musicEnabled,
                          onChanged: (value) {
                            _settingsService.setMusicEnabled(value);
                            _profileService.markAudioCustomized();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    _SettingsSection(
                      title: 'Feedback & accessibility',
                      children: [
                        _SettingsTile.switchTile(
                          icon: Icons.vibration,
                          title: 'Haptic feedback',
                          subtitle: 'Subtle vibration for successful drops',
                          value: settings.hapticsEnabled,
                          onChanged: _settingsService.setHapticsEnabled,
                        ),
                        _SettingsTile.switchTile(
                          icon: Icons.notifications_active,
                          title: 'Daily challenge reminders',
                          subtitle:
                              'We will notify you when a new challenge drops',
                          value: settings.notificationsEnabled,
                          onChanged: _settingsService.setNotificationsEnabled,
                        ),
                        _SettingsTile.switchTile(
                          icon: Icons.record_voice_over,
                          title: 'Voice commands',
                          subtitle:
                              'Hands-free play mode using speech recognition',
                          value: settings.voiceCommandsEnabled,
                          onChanged: _settingsService.setVoiceCommandsEnabled,
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    _SettingsSection(
                      title: 'Game balance',
                      children: [
                        _SettingsTile(
                          icon: Icons.equalizer,
                          title: 'Difficulty tuning',
                          subtitle:
                              'Fine tune the puzzle generator to your liking',
                          trailing: Text(
                            _difficultyLabel(_pendingDifficulty ?? settings.difficulty),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),
                        ),
                        Slider(
                          value: _pendingDifficulty ?? settings.difficulty,
                          onChanged: (value) {
                            setState(() {
                              _pendingDifficulty = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _pendingDifficulty = null;
                            _settingsService.setDifficulty(value);
                          },
                          divisions: 4,
                          label: _difficultyLabel(
                              _pendingDifficulty ?? settings.difficulty),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    _SettingsSection(
                      title: 'Legal & Privacy',
                      children: [
                        _SettingsTile(
                          icon: Icons.privacy_tip,
                          title: 'Privacy Policy',
                          subtitle: 'Learn how we protect your data',
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: _openPrivacyPolicy,
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.description,
                          title: 'Terms of Service',
                          subtitle: 'Read our terms and conditions',
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: _openTermsOfService,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // Notifications Section (Enhanced)
                    _SettingsSection(
                      title: 'Notifications',
                      children: [
                        _SettingsTile.switchTile(
                          icon: Icons.card_giftcard,
                          title: 'Daily reward reminders',
                          subtitle: 'Get notified when rewards are available',
                          value: NotificationService.instance.isDailyRewardReminderEnabled(),
                          onChanged: (value) {
                            setState(() {
                              NotificationService.instance.setDailyRewardReminderEnabled(value);
                            });
                          },
                        ),
                        _SettingsTile.switchTile(
                          icon: Icons.emoji_events,
                          title: 'Level reminders',
                          subtitle: 'Reminders to continue your progress',
                          value: NotificationService.instance.isLevelReminderEnabled(),
                          onChanged: (value) {
                            setState(() {
                              NotificationService.instance.setLevelReminderEnabled(value);
                            });
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.bedtime,
                          title: 'Quiet hours',
                          subtitle: 'No notifications: ${NotificationService.instance.getQuietHoursStart()}:00 - ${NotificationService.instance.getQuietHoursEnd()}:00',
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _showQuietHoursPicker,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // Accessibility Section
                    _SettingsSection(
                      title: 'Accessibility',
                      children: [
                        _SettingsTile(
                          icon: Icons.text_fields,
                          title: 'Text size',
                          subtitle: 'Adjust UI text scaling for readability',
                          trailing: Text(
                            _getTextScaleLabel(settings.textScale),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Slider(
                          value: settings.textScale,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          label: _getTextScaleLabel(settings.textScale),
                          onChanged: (value) {
                            _settingsService.setTextScale(value);
                          },
                        ),
                        _SettingsTile.switchTile(
                          icon: Icons.animation,
                          title: 'Reduce motion',
                          subtitle: 'Minimize animations for accessibility',
                          value: settings.reduceMotion,
                          onChanged: _settingsService.setReduceMotion,
                        ),
                        _SettingsTile.switchTile(
                          icon: Icons.palette,
                          title: 'High contrast mode',
                          subtitle: 'Increase visual contrast for better visibility',
                          value: settings.highContrastMode,
                          onChanged: _settingsService.setHighContrastMode,
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // Performance Section
                    _SettingsSection(
                      title: 'Performance',
                      children: [
                        _SettingsTile.switchTile(
                          icon: Icons.auto_awesome,
                          title: 'Particle effects',
                          subtitle: 'Visual effects for level completion',
                          value: settings.particleEffectsEnabled,
                          onChanged: _settingsService.setParticleEffectsEnabled,
                        ),
                        _SettingsTile.switchTile(
                          icon: Icons.speed,
                          title: 'Performance mode',
                          subtitle: 'Reduce effects for smoother gameplay',
                          value: settings.performanceMode,
                          onChanged: _settingsService.setPerformanceMode,
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // Data Management Section
                    _SettingsSection(
                      title: 'Data Management',
                      children: [
                        _SettingsTile(
                          icon: Icons.cloud_upload,
                          title: 'Export progress',
                          subtitle: 'Save your game data for backup',
                          trailing: TextButton(
                            onPressed: _exportProgress,
                            child: const Text('Export'),
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.cloud_download,
                          title: 'Import progress',
                          subtitle: 'Restore game data from backup',
                          trailing: TextButton(
                            onPressed: _importProgress,
                            child: const Text('Import'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    _SettingsSection(
                      title: 'Support & Feedback',
                      children: [
                        _SettingsTile(
                          icon: Icons.star_rate,
                          title: 'Rate SortBliss',
                          subtitle: 'Help us grow by rating the app',
                          trailing: TextButton(
                            onPressed: _rateApp,
                            child: const Text('Rate'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    _SettingsSection(
                      title: 'Danger zone',
                      children: [
                        _SettingsTile(
                          icon: Icons.refresh,
                          title: 'Reset to defaults',
                          subtitle: 'Restore all preferences to the original state',
                          trailing: TextButton(
                            onPressed: _confirmReset,
                            child: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),

                    // Developer Section (Debug mode only)
                    if (kDebugMode) ...[
                      SizedBox(height: 3.h),
                      _SettingsSection(
                        title: 'Developer Tools',
                        children: [
                          _SettingsTile(
                            icon: Icons.bug_report,
                            title: 'Reset daily rewards',
                            subtitle: 'Clear daily reward claim state',
                            trailing: TextButton(
                              onPressed: _resetDailyRewards,
                              child: const Text('Reset'),
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.notifications_active,
                            title: 'Test notification',
                            subtitle: 'Trigger test notification immediately',
                            trailing: TextButton(
                              onPressed: _testNotification,
                              child: const Text('Test'),
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.money,
                            title: 'Add 1000 coins',
                            subtitle: 'Grant test coins for development',
                            trailing: TextButton(
                              onPressed: _addTestCoins,
                              child: const Text('Grant'),
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.lock_open,
                            title: 'Unlock all levels',
                            subtitle: 'Unlock all levels for testing',
                            trailing: TextButton(
                              onPressed: _unlockAllLevels,
                              child: const Text('Unlock'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Player Profile Stats Section
  Widget _buildProfileStatsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Player level badge
              Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '${LevelProgressionService.instance.getPlayerLevel()}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player Profile',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.monetization_on, size: 14.sp, color: Colors.amber),
                        SizedBox(width: 1.w),
                        Text(
                          '${MonetizationManager.instance.currentCoins} coins',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Icon(Icons.stars, size: 14.sp, color: Colors.amber),
                        SizedBox(width: 1.w),
                        Text(
                          '${LevelProgressionService.instance.getTotalStars()} stars',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // XP progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Progress',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '${LevelProgressionService.instance.getPlayerXP()} XP',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Container(
                height: 1.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(0.5.h),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: LevelProgressionService.instance.getXPProgressToNextLevel(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(0.5.h),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(double value) {
    if (value <= 0.25) return 'Tranquil';
    if (value <= 0.5) return 'Balanced';
    if (value <= 0.75) return 'Challenging';
    return 'Brain Burner';
  }

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('https://raw.githubusercontent.com/ArtificialSight/sortbliss/main/PRIVACY_POLICY.md');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Privacy Policy')),
      );
    }
  }

  Future<void> _openTermsOfService() async {
    final url = Uri.parse('https://raw.githubusercontent.com/ArtificialSight/sortbliss/main/TERMS_OF_SERVICE.md');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Terms of Service')),
      );
    }
  }

  Future<void> _rateApp() async {
    await RateAppService.instance.requestReview();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  String _getTextScaleLabel(double scale) {
    if (scale <= 0.9) return 'Small';
    if (scale <= 1.1) return 'Normal';
    if (scale <= 1.3) return 'Large';
    return 'Extra Large';
  }

  Future<void> _showQuietHoursPicker() async {
    final start = NotificationService.instance.getQuietHoursStart();
    final end = NotificationService.instance.getQuietHoursEnd();

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _QuietHoursPickerDialog(startHour: start, endHour: end),
    );

    if (result != null) {
      await NotificationService.instance.setQuietHours(
        start: result['start']!,
        end: result['end']!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiet hours updated: ${result['start']}:00 - ${result['end']}:00')),
      );

      setState(() {}); // Refresh UI
    }
  }

  Future<void> _exportProgress() async {
    // TODO: Implement progress export (save to file/share)
    // For now, just show a placeholder
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export progress feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _importProgress() async {
    // TODO: Implement progress import (load from file)
    // For now, just show a placeholder
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import progress feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Developer tools (debug mode only)
  Future<void> _resetDailyRewards() async {
    await DailyRewardsService.instance.resetForTesting();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('[DEV] Daily rewards reset')),
    );
  }

  Future<void> _testNotification() async {
    await NotificationService.instance.scheduleDailyRewardReminder(
      hour: DateTime.now().hour,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('[DEV] Test notification scheduled')),
    );
  }

  Future<void> _addTestCoins() async {
    MonetizationManager.instance.addCoins(1000);

    if (!mounted) return;
    setState(() {}); // Refresh profile stats
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('[DEV] Added 1000 coins')),
    );
  }

  Future<void> _unlockAllLevels() async {
    // TODO: Implement unlock all levels for testing
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('[DEV] Unlock all levels feature coming soon!')),
    );
  }

  Future<void> _confirmReset() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset preferences?'),
          content: const Text(
              'This will restore audio, accessibility and gameplay settings to their defaults.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true && mounted) {
      await _settingsService.resetToDefaults();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences restored to defaults.')),
      );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.2.h),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  }) : _isSwitch = false, onChanged = null, value = null;

  const _SettingsTile.switchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required bool this.value,
    required ValueChanged<bool>? this.onChanged,
  })  : trailing = null,
        _isSwitch = true;

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final bool _isSwitch;

  @override
  Widget build(BuildContext context) {
    final tileColor = Theme.of(context).colorScheme.surface;
    final shadow = Colors.black.withOpacity(0.04);
    final tile = Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: EdgeInsets.all(2.w),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_isSwitch)
            Switch(
              value: value ?? false,
              onChanged: onChanged,
            )
          else if (trailing != null)
            trailing!,
        ],
      ),
    );

    if (_isSwitch) {
      return GestureDetector(
        onTap: () => onChanged?.call(!(value ?? false)),
        behavior: HitTestBehavior.opaque,
        child: tile,
      );
    }
    return tile;
  }
}

// Quiet Hours Picker Dialog
class _QuietHoursPickerDialog extends StatefulWidget {
  final int startHour;
  final int endHour;

  const _QuietHoursPickerDialog({
    required this.startHour,
    required this.endHour,
  });

  @override
  State<_QuietHoursPickerDialog> createState() => _QuietHoursPickerDialogState();
}

class _QuietHoursPickerDialogState extends State<_QuietHoursPickerDialog> {
  late int _start;
  late int _end;

  @override
  void initState() {
    super.initState();
    _start = widget.startHour;
    _end = widget.endHour;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Quiet Hours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No notifications will be sent during these hours'),
          SizedBox(height: 2.h),

          // Start hour picker
          Row(
            children: [
              const Text('Start:'),
              SizedBox(width: 2.w),
              Expanded(
                child: DropdownButton<int>(
                  value: _start,
                  isExpanded: true,
                  items: List.generate(24, (i) => i).map((hour) {
                    return DropdownMenuItem(
                      value: hour,
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _start = value);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),

          // End hour picker
          Row(
            children: [
              const Text('End:'),
              SizedBox(width: 2.w),
              Expanded(
                child: DropdownButton<int>(
                  value: _end,
                  isExpanded: true,
                  items: List.generate(24, (i) => i).map((hour) {
                    return DropdownMenuItem(
                      value: hour,
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _end = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {'start': _start, 'end': _end});
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
