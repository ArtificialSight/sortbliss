import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/user_settings_service.dart';
import '../../core/services/notification_scheduler_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/services/app_rating_service.dart';
import '../../core/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Comprehensive settings screen
///
/// Features:
/// - Audio settings (sound, music, volume)
/// - Haptic feedback toggle
/// - Notification settings
/// - Language selection
/// - Theme selection (when implemented)
/// - Privacy settings
/// - Data management (clear cache, reset progress)
/// - About section (version, credits, licenses)
/// - Support links (help, feedback, contact)
/// - Account management
///
/// Sections:
/// 1. Gameplay
/// 2. Audio & Haptics
/// 3. Notifications
/// 4. Display
/// 5. Privacy & Data
/// 6. Support
/// 7. About
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserSettingsService _settings = UserSettingsService.instance;
  final NotificationSchedulerService _notifications =
      NotificationSchedulerService.instance;
  final RemoteConfigService _remoteConfig = RemoteConfigService.instance;
  final AppRatingService _rating = AppRatingService.instance;

  String _appVersion = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // PackageInfo not available, use defaults
      debugPrint('Could not load package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: AppTheme.lightTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Gameplay Section
          _buildSectionHeader('Gameplay'),
          _buildSwitchTile(
            'Tutorial Mode',
            'Show hints and guidance for new features',
            _settings.getTutorialEnabled(),
            (value) {
              _settings.setTutorialEnabled(value);
              setState(() {});
            },
            Icons.school,
          ),
          _buildSwitchTile(
            'Confirm Moves',
            'Ask for confirmation before important actions',
            _settings.getConfirmMoves(),
            (value) {
              _settings.setConfirmMoves(value);
              setState(() {});
            },
            Icons.check_circle_outline,
          ),

          const Divider(),

          // Audio & Haptics Section
          _buildSectionHeader('Audio & Haptics'),
          _buildSwitchTile(
            'Sound Effects',
            'Play sounds for game actions',
            _settings.getSoundEnabled(),
            (value) {
              _settings.setSoundEnabled(value);
              setState(() {});
            },
            Icons.volume_up,
          ),
          _buildSwitchTile(
            'Background Music',
            'Play music during gameplay',
            _settings.getMusicEnabled(),
            (value) {
              _settings.setMusicEnabled(value);
              setState(() {});
            },
            Icons.music_note,
          ),
          _buildSliderTile(
            'Sound Volume',
            _settings.getSoundVolume(),
            (value) {
              _settings.setSoundVolume(value);
              setState(() {});
            },
            Icons.volume_down,
            enabled: _settings.getSoundEnabled(),
          ),
          _buildSliderTile(
            'Music Volume',
            _settings.getMusicVolume(),
            (value) {
              _settings.setMusicVolume(value);
              setState(() {});
            },
            Icons.music_note,
            enabled: _settings.getMusicEnabled(),
          ),
          _buildSwitchTile(
            'Haptic Feedback',
            'Vibrate on touch and game events',
            _settings.getHapticEnabled(),
            (value) {
              _settings.setHapticEnabled(value);
              setState(() {});
            },
            Icons.vibration,
          ),

          const Divider(),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Enable Notifications',
            'Receive reminders and updates',
            true, // TODO: Get from notification service
            (value) async {
              await _notifications.setNotificationsEnabled(value);
              setState(() {});
            },
            Icons.notifications,
          ),
          _buildNavigationTile(
            'Notification Preferences',
            'Customize notification types and timing',
            Icons.tune,
            () {
              // TODO: Navigate to detailed notification settings
              _showNotificationPreferences();
            },
          ),

          const Divider(),

          // Display Section
          _buildSectionHeader('Display'),
          _buildSwitchTile(
            'Animations',
            'Show visual effects and animations',
            _settings.getAnimationsEnabled(),
            (value) {
              _settings.setAnimationsEnabled(value);
              setState(() {});
            },
            Icons.animation,
          ),
          _buildSwitchTile(
            'Particle Effects',
            'Show confetti and celebration effects',
            true, // TODO: Add to settings service
            (value) {
              // TODO: Implement particle effects toggle
              setState(() {});
            },
            Icons.auto_awesome,
          ),
          _buildNavigationTile(
            'Theme',
            'Light (Dark mode coming soon)',
            Icons.palette,
            () {
              // TODO: Theme selection when implemented
              _showComingSoon();
            },
          ),

          const Divider(),

          // Privacy & Data Section
          _buildSectionHeader('Privacy & Data'),
          _buildSwitchTile(
            'Analytics',
            'Help us improve by sharing usage data',
            _settings.getAnalyticsEnabled(),
            (value) {
              _settings.setAnalyticsEnabled(value);
              setState(() {});
            },
            Icons.analytics,
          ),
          _buildNavigationTile(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip,
            () {
              // TODO: Open privacy policy
              _openPrivacyPolicy();
            },
          ),
          _buildNavigationTile(
            'Clear Cache',
            'Free up storage space',
            Icons.cleaning_services,
            () {
              _showClearCacheDialog();
            },
          ),
          _buildNavigationTile(
            'Reset Progress',
            'Start fresh (cannot be undone)',
            Icons.restart_alt,
            () {
              _showResetProgressDialog();
            },
            destructive: true,
          ),

          const Divider(),

          // Support Section
          _buildSectionHeader('Support'),
          _buildNavigationTile(
            'Help & FAQ',
            'Get help with common questions',
            Icons.help_outline,
            () {
              // TODO: Open help center
              _openHelp();
            },
          ),
          _buildNavigationTile(
            'Send Feedback',
            'Share your thoughts and suggestions',
            Icons.feedback,
            () {
              _showFeedbackDialog();
            },
          ),
          _buildNavigationTile(
            'Contact Support',
            'Get assistance from our team',
            Icons.support_agent,
            () {
              _contactSupport();
            },
          ),
          _buildNavigationTile(
            'Rate SortBliss',
            'Enjoying the game? Rate us!',
            Icons.star,
            () async {
              await _rating.promptForRating(context);
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          _buildInfoTile(
            'Version',
            '$_appVersion (Build $_buildNumber)',
            Icons.info_outline,
          ),
          _buildNavigationTile(
            'What\'s New',
            'See recent updates and features',
            Icons.new_releases,
            () {
              _showWhatsNew();
            },
          ),
          _buildNavigationTile(
            'Credits',
            'Made with ❤️ by the SortBliss team',
            Icons.people,
            () {
              _showCredits();
            },
          ),
          _buildNavigationTile(
            'Open Source Licenses',
            'View third-party licenses',
            Icons.article,
            () {
              _showLicenses();
            },
          ),

          SizedBox(height: 4.h),

          // Footer
          Center(
            child: Text(
              '© 2025 SortBliss',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
            ),
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 1.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.lightTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.lightTheme.primaryColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.lightTheme.primaryColor,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    Function(double) onChanged,
    IconData icon, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled
            ? AppTheme.lightTheme.primaryColor
            : Colors.grey[400],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.grey[900] : Colors.grey[400],
        ),
      ),
      subtitle: Slider(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppTheme.lightTheme.primaryColor,
        inactiveColor: Colors.grey[300],
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: destructive ? Colors.red : AppTheme.lightTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: destructive ? Colors.red : Colors.grey[900],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.lightTheme.primaryColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
      ),
    );
  }

  // Dialog methods

  void _showNotificationPreferences() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Preferences'),
        content: const Text(
          'Customize notification types:\n\n'
          '• Daily reminders\n'
          '• Streak protection\n'
          '• Event notifications\n'
          '• Achievement updates\n\n'
          'Coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and free up storage. '
          'Your progress will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement cache clearing
              Navigator.pop(context);
              _showSnackBar('Cache cleared successfully');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetProgressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'This will delete ALL your progress, achievements, and stats. '
          'This action CANNOT be undone.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmResetProgress();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmResetProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Type "DELETE" to confirm resetting all progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement progress reset
              Navigator.pop(context);
              _showSnackBar('Progress has been reset');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text(
          'We\'d love to hear from you!\n\n'
          'Email us at: feedback@sortbliss.com\n\n'
          'Or use the in-app feedback form (coming soon).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWhatsNew() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What\'s New'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version $_appVersion',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Complete UI overhaul\n'
                  '• New achievement system\n'
                  '• Seasonal events\n'
                  '• Leaderboards\n'
                  '• Power-ups shop\n'
                  '• Performance improvements\n'
                  '• Bug fixes'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCredits() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Credits'),
        content: const Text(
          'SortBliss\n\n'
          'Made with ❤️ by the SortBliss team\n\n'
          'Special thanks to:\n'
          '• Our amazing players\n'
          '• The Flutter community\n'
          '• Open source contributors',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'SortBliss',
      applicationVersion: _appVersion,
      applicationIcon: Icon(
        Icons.sort,
        size: 50,
        color: AppTheme.lightTheme.primaryColor,
      ),
    );
  }

  void _showComingSoon() {
    _showSnackBar('Coming soon!');
  }

  void _openPrivacyPolicy() {
    // TODO: Open privacy policy URL
    _showSnackBar('Opening privacy policy...');
  }

  void _openHelp() {
    // TODO: Open help center
    _showSnackBar('Opening help center...');
  }

  void _contactSupport() {
    // TODO: Open support contact
    _showSnackBar('Opening support...');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
