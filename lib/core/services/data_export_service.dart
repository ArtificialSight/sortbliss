import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sortbliss/core/services/player_profile_service.dart';
import 'package:sortbliss/core/services/achievements_tracker_service.dart';
import 'package:sortbliss/core/services/user_settings_service.dart';
import '../analytics/analytics_logger.dart';

/// Service for exporting player data in multiple formats.
///
/// Provides GDPR-compliant data export functionality, allowing players to
/// download their complete gameplay data in JSON, CSV, or formatted text.
/// This feature can be gated behind premium purchases or used as a user
/// retention/trust building tool.
class DataExportService {
  DataExportService._();

  static final DataExportService instance = DataExportService._();

  /// Export complete player data as JSON
  /// Returns the file path of the exported JSON file
  Future<String> exportAsJson({
    bool includeProfile = true,
    bool includeAchievements = true,
    bool includeSettings = true,
    bool includeMetadata = true,
  }) async {
    try {
      final data = await _collectExportData(
        includeProfile: includeProfile,
        includeAchievements: includeAchievements,
        includeSettings: includeSettings,
        includeMetadata: includeMetadata,
      );

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final file = await _writeToFile('sortbliss_export.json', jsonString);

      AnalyticsLogger.logEvent('data_export_json', parameters: {
        'file_size': jsonString.length,
        'includes_profile': includeProfile,
        'includes_achievements': includeAchievements,
        'includes_settings': includeSettings,
      });

      return file.path;
    } catch (error, stackTrace) {
      AnalyticsLogger.logEvent('data_export_failed', parameters: {
        'format': 'json',
        'error': error.toString(),
      });
      rethrow;
    }
  }

  /// Export player data as CSV format
  /// Returns the file path of the exported CSV file
  Future<String> exportAsCsv() async {
    try {
      final data = await _collectExportData();
      final csv = _convertToCSV(data);
      final file = await _writeToFile('sortbliss_export.csv', csv);

      AnalyticsLogger.logEvent('data_export_csv', parameters: {
        'file_size': csv.length,
      });

      return file.path;
    } catch (error, stackTrace) {
      AnalyticsLogger.logEvent('data_export_failed', parameters: {
        'format': 'csv',
        'error': error.toString(),
      });
      rethrow;
    }
  }

  /// Export player data as human-readable formatted text
  /// Returns the file path of the exported text file
  Future<String> exportAsFormattedText() async {
    try {
      final data = await _collectExportData();
      final text = _convertToFormattedText(data);
      final file = await _writeToFile('sortbliss_export.txt', text);

      AnalyticsLogger.logEvent('data_export_text', parameters: {
        'file_size': text.length,
      });

      return file.path;
    } catch (error, stackTrace) {
      AnalyticsLogger.logEvent('data_export_failed', parameters: {
        'format': 'text',
        'error': error.toString(),
      });
      rethrow;
    }
  }

  /// Export and share via system share dialog
  /// Returns true if share was initiated successfully
  Future<bool> exportAndShare({String format = 'json'}) async {
    try {
      String filePath;

      switch (format.toLowerCase()) {
        case 'csv':
          filePath = await exportAsCsv();
          break;
        case 'txt':
        case 'text':
          filePath = await exportAsFormattedText();
          break;
        case 'json':
        default:
          filePath = await exportAsJson();
      }

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'SortBliss Game Progress Export',
        text: 'Here is my SortBliss game progress data.',
      );

      AnalyticsLogger.logEvent('data_export_shared', parameters: {
        'format': format,
        'status': result.status.name,
      });

      return result.status == ShareResultStatus.success;
    } catch (error, stackTrace) {
      AnalyticsLogger.logEvent('data_export_share_failed', parameters: {
        'format': format,
        'error': error.toString(),
      });
      return false;
    }
  }

  /// Get export summary statistics without full export
  Future<Map<String, dynamic>> getExportSummary() async {
    final profile = PlayerProfileService.instance.currentProfile;
    final achievements = AchievementsTrackerService.instance.trackedIds;
    final settings = UserSettingsService.instance.settings.value;

    return {
      'total_levels_completed': profile.levelsCompleted,
      'total_coins_earned': profile.coinsEarned,
      'current_streak': profile.currentStreak,
      'achievements_unlocked': profile.unlockedAchievements.length,
      'achievements_tracked': achievements.length,
      'has_premium_features': profile.hasRemoveAdsPurchase,
      'share_count': profile.shareCount,
      'audio_customized': profile.audioCustomized,
      'current_difficulty': settings.difficulty,
    };
  }

  Future<Map<String, dynamic>> _collectExportData({
    bool includeProfile = true,
    bool includeAchievements = true,
    bool includeSettings = true,
    bool includeMetadata = true,
  }) async {
    final exportData = <String, dynamic>{};

    if (includeMetadata) {
      exportData['metadata'] = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'export_format_version': '1.0',
      };
    }

    if (includeProfile) {
      final profile = PlayerProfileService.instance.currentProfile;
      exportData['player_profile'] = {
        'levels_completed': profile.levelsCompleted,
        'current_level': profile.currentLevel,
        'level_progress': profile.levelProgress,
        'current_streak': profile.currentStreak,
        'coins_earned': profile.coinsEarned,
        'share_count': profile.shareCount,
        'unlocked_achievements': profile.unlockedAchievements,
        'audio_customized': profile.audioCustomized,
        'has_remove_ads_purchase': profile.hasRemoveAdsPurchase,
        'daily_challenge_completed': profile.dailyChallengeCompleted,
        'show_rate_prompt': profile.showRatePrompt,
      };
    }

    if (includeAchievements) {
      final tracked = AchievementsTrackerService.instance.trackedIds;
      exportData['achievements'] = {
        'tracked_achievements': tracked.toList()..sort(),
        'total_tracked': tracked.length,
      };
    }

    if (includeSettings) {
      final settings = UserSettingsService.instance.settings.value;
      exportData['user_settings'] = {
        'sound_effects_enabled': settings.soundEffectsEnabled,
        'music_enabled': settings.musicEnabled,
        'haptics_enabled': settings.hapticsEnabled,
        'notifications_enabled': settings.notificationsEnabled,
        'voice_commands_enabled': settings.voiceCommandsEnabled,
        'difficulty': settings.difficulty,
      };
    }

    return exportData;
  }

  String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('SortBliss Data Export');
    buffer.writeln('Export Date,${data['metadata']?['export_date'] ?? 'Unknown'}');
    buffer.writeln('');

    // Player Profile Section
    if (data.containsKey('player_profile')) {
      buffer.writeln('Player Profile');
      buffer.writeln('Metric,Value');

      final profile = data['player_profile'] as Map<String, dynamic>;
      profile.forEach((key, value) {
        final displayKey = _toTitleCase(key.replaceAll('_', ' '));
        if (value is List) {
          buffer.writeln('$displayKey,"${value.join(', ')}"');
        } else {
          buffer.writeln('$displayKey,$value');
        }
      });
      buffer.writeln('');
    }

    // Achievements Section
    if (data.containsKey('achievements')) {
      buffer.writeln('Achievements');
      buffer.writeln('Tracked Achievements');

      final achievements = data['achievements'] as Map<String, dynamic>;
      final tracked = achievements['tracked_achievements'] as List?;
      if (tracked != null && tracked.isNotEmpty) {
        for (final achievement in tracked) {
          buffer.writeln(achievement);
        }
      } else {
        buffer.writeln('None');
      }
      buffer.writeln('');
    }

    // Settings Section
    if (data.containsKey('user_settings')) {
      buffer.writeln('User Settings');
      buffer.writeln('Setting,Value');

      final settings = data['user_settings'] as Map<String, dynamic>;
      settings.forEach((key, value) {
        final displayKey = _toTitleCase(key.replaceAll('_', ' '));
        buffer.writeln('$displayKey,$value');
      });
    }

    return buffer.toString();
  }

  String _convertToFormattedText(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('SORTBLISS GAME PROGRESS EXPORT');
    buffer.writeln('=' * 60);
    buffer.writeln('');

    // Metadata
    if (data.containsKey('metadata')) {
      final metadata = data['metadata'] as Map<String, dynamic>;
      buffer.writeln('Export Date: ${metadata['export_date']}');
      buffer.writeln('App Version: ${metadata['app_version']}');
      buffer.writeln('');
    }

    // Player Profile
    if (data.containsKey('player_profile')) {
      buffer.writeln('-' * 60);
      buffer.writeln('PLAYER PROFILE');
      buffer.writeln('-' * 60);

      final profile = data['player_profile'] as Map<String, dynamic>;

      buffer.writeln('Levels Completed: ${profile['levels_completed']}');
      buffer.writeln('Current Level: ${profile['current_level']}');
      buffer.writeln('Level Progress: ${(profile['level_progress'] as num * 100).toStringAsFixed(1)}%');
      buffer.writeln('Current Streak: ${profile['current_streak']} days');
      buffer.writeln('Coins Earned: ${profile['coins_earned']}');
      buffer.writeln('Share Count: ${profile['share_count']}');
      buffer.writeln('');

      buffer.writeln('Unlocked Achievements:');
      final achievements = profile['unlocked_achievements'] as List;
      if (achievements.isNotEmpty) {
        for (int i = 0; i < achievements.length; i++) {
          buffer.writeln('  ${i + 1}. ${achievements[i]}');
        }
      } else {
        buffer.writeln('  None');
      }
      buffer.writeln('');

      buffer.writeln('Premium Features:');
      buffer.writeln('  Remove Ads: ${profile['has_remove_ads_purchase'] ? 'Purchased' : 'Not purchased'}');
      buffer.writeln('  Audio Customized: ${profile['audio_customized'] ? 'Yes' : 'No'}');
      buffer.writeln('');
    }

    // Tracked Achievements
    if (data.containsKey('achievements')) {
      buffer.writeln('-' * 60);
      buffer.writeln('TRACKED ACHIEVEMENTS');
      buffer.writeln('-' * 60);

      final achievementsData = data['achievements'] as Map<String, dynamic>;
      final tracked = achievementsData['tracked_achievements'] as List;

      buffer.writeln('Total Tracked: ${achievementsData['total_tracked']}');
      buffer.writeln('');

      if (tracked.isNotEmpty) {
        for (int i = 0; i < tracked.length; i++) {
          buffer.writeln('  ${i + 1}. ${tracked[i]}');
        }
      } else {
        buffer.writeln('  None currently tracked');
      }
      buffer.writeln('');
    }

    // User Settings
    if (data.containsKey('user_settings')) {
      buffer.writeln('-' * 60);
      buffer.writeln('USER SETTINGS');
      buffer.writeln('-' * 60);

      final settings = data['user_settings'] as Map<String, dynamic>;

      buffer.writeln('Sound Effects: ${settings['sound_effects_enabled'] ? 'Enabled' : 'Disabled'}');
      buffer.writeln('Music: ${settings['music_enabled'] ? 'Enabled' : 'Disabled'}');
      buffer.writeln('Haptics: ${settings['haptics_enabled'] ? 'Enabled' : 'Disabled'}');
      buffer.writeln('Notifications: ${settings['notifications_enabled'] ? 'Enabled' : 'Disabled'}');
      buffer.writeln('Voice Commands: ${settings['voice_commands_enabled'] ? 'Enabled' : 'Disabled'}');
      buffer.writeln('Difficulty: ${_getDifficultyLabel(settings['difficulty'] as double)}');
      buffer.writeln('');
    }

    buffer.writeln('=' * 60);
    buffer.writeln('END OF EXPORT');
    buffer.writeln('=' * 60);

    return buffer.toString();
  }

  Future<File> _writeToFile(String filename, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    return file.writeAsString(content);
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _getDifficultyLabel(double difficulty) {
    if (difficulty <= 0.25) return 'Tranquil (${(difficulty * 100).toStringAsFixed(0)}%)';
    if (difficulty <= 0.5) return 'Balanced (${(difficulty * 100).toStringAsFixed(0)}%)';
    if (difficulty <= 0.75) return 'Challenging (${(difficulty * 100).toStringAsFixed(0)}%)';
    return 'Brain Burner (${(difficulty * 100).toStringAsFixed(0)}%)';
  }
}
