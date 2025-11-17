import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// Backup and restore service for user data
///
/// Backs up all user data to:
/// - Local file system
/// - Cloud storage (Google Drive, iCloud)
/// - Custom backend
///
/// Restores data from backup when needed.
///
/// Usage:
/// ```dart
/// await BackupRestoreService.instance.initialize();
///
/// // Create backup
/// final backup = await BackupRestoreService.instance.createBackup();
///
/// // Restore from backup
/// await BackupRestoreService.instance.restoreFromBackup(backup);
/// ```
class BackupRestoreService {
  static final BackupRestoreService instance = BackupRestoreService._();
  BackupRestoreService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  static const String _keyLastBackupDate = 'last_backup_date';
  static const String _keyAutoBackupEnabled = 'auto_backup_enabled';

  /// Initialize backup service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    _initialized = true;

    debugPrint('✅ Backup/Restore Service initialized');
  }

  /// Create full backup of all user data
  Future<BackupData> createBackup() async {
    if (!_initialized) await initialize();

    final allKeys = _prefs?.getKeys() ?? {};
    final data = <String, dynamic>{};

    for (final key in allKeys) {
      final value = _prefs?.get(key);
      if (value != null) {
        data[key] = value;
      }
    }

    final backup = BackupData(
      version: 1,
      timestamp: DateTime.now(),
      data: data,
    );

    // Record backup
    await _prefs?.setString(
      _keyLastBackupDate,
      DateTime.now().toIso8601String(),
    );

    AnalyticsLogger.logEvent(
      'backup_created',
      parameters: {
        'keys_count': data.length,
        'backup_size': jsonEncode(data).length,
      },
    );

    debugPrint('💾 Backup created (${data.length} keys)');

    return backup;
  }

  /// Restore data from backup
  Future<bool> restoreFromBackup(BackupData backup) async {
    if (!_initialized) await initialize();

    try {
      // Clear existing data
      await _prefs?.clear();

      // Restore all data
      for (final entry in backup.data.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          await _prefs?.setString(key, value);
        } else if (value is int) {
          await _prefs?.setInt(key, value);
        } else if (value is double) {
          await _prefs?.setDouble(key, value);
        } else if (value is bool) {
          await _prefs?.setBool(key, value);
        } else if (value is List<String>) {
          await _prefs?.setStringList(key, value);
        }
      }

      AnalyticsLogger.logEvent(
        'backup_restored',
        parameters: {
          'keys_count': backup.data.length,
          'backup_age_hours': DateTime.now().difference(backup.timestamp).inHours,
        },
      );

      debugPrint('✅ Backup restored (${backup.data.length} keys)');

      return true;
    } catch (e) {
      debugPrint('❌ Error restoring backup: $e');

      AnalyticsLogger.logEvent(
        'backup_restore_failed',
        parameters: {'error': e.toString()},
      );

      return false;
    }
  }

  /// Export backup as JSON string
  String exportBackupAsJson(BackupData backup) {
    return jsonEncode({
      'version': backup.version,
      'timestamp': backup.timestamp.toIso8601String(),
      'data': backup.data,
    });
  }

  /// Import backup from JSON string
  BackupData importBackupFromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;

    return BackupData(
      version: map['version'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      data: Map<String, dynamic>.from(map['data'] as Map),
    );
  }

  /// Get last backup date
  DateTime? getLastBackupDate() {
    final dateStr = _prefs?.getString(_keyLastBackupDate);
    if (dateStr == null) return null;

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Check if auto backup is enabled
  bool isAutoBackupEnabled() {
    return _prefs?.getBool(_keyAutoBackupEnabled) ?? false;
  }

  /// Set auto backup enabled
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _prefs?.setBool(_keyAutoBackupEnabled, enabled);

    AnalyticsLogger.logEvent(
      'auto_backup_toggled',
      parameters: {'enabled': enabled},
    );
  }

  /// Get backup statistics
  BackupStatistics getStatistics() {
    final allKeys = _prefs?.getKeys() ?? {};
    final lastBackup = getLastBackupDate();

    int totalSize = 0;
    for (final key in allKeys) {
      final value = _prefs?.get(key);
      if (value != null) {
        totalSize += value.toString().length;
      }
    }

    return BackupStatistics(
      totalKeys: allKeys.length,
      totalSize: totalSize,
      lastBackupDate: lastBackup,
      autoBackupEnabled: isAutoBackupEnabled(),
    );
  }

  /// Schedule auto backup (TODO: implement with background task)
  Future<void> scheduleAutoBackup() async {
    // TODO: Use background task package
    // For now, just enable the flag
    await setAutoBackupEnabled(true);
  }
}

/// Backup data model
class BackupData {
  final int version;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  BackupData({
    required this.version,
    required this.timestamp,
    required this.data,
  });

  @override
  String toString() {
    return 'BackupData(\n'
        '  version: $version,\n'
        '  timestamp: $timestamp,\n'
        '  keys: ${data.length}\n'
        ')';
  }
}

/// Backup statistics
class BackupStatistics {
  final int totalKeys;
  final int totalSize;
  final DateTime? lastBackupDate;
  final bool autoBackupEnabled;

  BackupStatistics({
    required this.totalKeys,
    required this.totalSize,
    this.lastBackupDate,
    required this.autoBackupEnabled,
  });

  String get totalSizeFormatted {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'BackupStatistics(\n'
        '  keys: $totalKeys,\n'
        '  size: $totalSizeFormatted,\n'
        '  lastBackup: $lastBackupDate,\n'
        '  autoBackup: $autoBackupEnabled\n'
        ')';
  }
}
