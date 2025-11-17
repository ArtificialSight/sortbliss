import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/player_profile_service.dart';
import '../../core/services/rate_app_service.dart';
import '../../core/services/user_settings_service.dart';

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
                  ],
                );
              },
            );
          },
        ),
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
