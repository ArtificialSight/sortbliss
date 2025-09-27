import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized player profile store that keeps track of gameplay stats,
/// unlocked achievements, and purchase states.
///
/// The data is persisted locally via [SharedPreferences] so a play tester can
/// exit and relaunch the app without losing progress. Widgets can subscribe to
/// [profileListenable] for reactive updates when the profile changes.
class PlayerProfileService {
  PlayerProfileService._();

  static final PlayerProfileService instance = PlayerProfileService._();

  static const String _prefsKey = 'player_profile_v1';

  final ValueNotifier<PlayerProfile> _profileNotifier =
      ValueNotifier<PlayerProfile>(PlayerProfile.defaults);

  SharedPreferences? _preferences;
  bool _initialized = false;
  Completer<void>? _initializationCompleter;

  ValueListenable<PlayerProfile> get profileListenable => _profileNotifier;

  PlayerProfile get currentProfile => _profileNotifier.value;

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }
    final completer = Completer<void>();
    _initializationCompleter = completer;
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final stored = _preferences?.getString(_prefsKey);
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        _profileNotifier.value = PlayerProfile.fromJson(decoded);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Failed to initialize PlayerProfileService: $error\n$stackTrace',
        );
      }
    } finally {
      _initialized = true;
      completer.complete();
      _initializationCompleter = null;
    }
  }

  Future<void> updateProfile(PlayerProfile profile) async {
    await _writeProfile((_) => profile);
  }

  Future<void> updateProgress({
    int? levelsCompleted,
    int? currentStreak,
    int? coinsEarned,
    int? currentLevel,
    double? levelProgress,
  }) async {
    await _writeProfile((profile) {
      return profile.copyWith(
        levelsCompleted: levelsCompleted ?? profile.levelsCompleted,
        currentStreak: currentStreak ?? profile.currentStreak,
        coinsEarned: coinsEarned ?? profile.coinsEarned,
        currentLevel: currentLevel ?? profile.currentLevel,
        levelProgress: levelProgress ?? profile.levelProgress,
      );
    });
  }

  Future<void> unlockAchievement(String achievementTitle) async {
    await _writeProfile((profile) {
      final updated = List<String>.from(profile.unlockedAchievements);
      updated.remove(achievementTitle);
      updated.insert(0, achievementTitle);
      return profile.copyWith(
        unlockedAchievements: updated.take(6).toList(growable: false),
      );
    });
  }

  Future<void> incrementShareCount() async {
    await _writeProfile((profile) {
      final newCount = profile.shareCount + 1;
      final shouldUnlock =
          newCount >= 3 && !profile.unlockedAchievements.contains('Social Butterfly');
      final achievements = List<String>.from(profile.unlockedAchievements);
      if (shouldUnlock) {
        achievements.remove('Social Butterfly');
        achievements.insert(0, 'Social Butterfly');
      }
      return profile.copyWith(
        shareCount: newCount,
        unlockedAchievements: achievements.take(6).toList(growable: false),
      );
    });
  }

  Future<void> markAudioCustomized() async {
    await _writeProfile((profile) {
      if (profile.audioCustomized) {
        return profile;
      }
      final achievements = List<String>.from(profile.unlockedAchievements);
      achievements.remove('Sound Maestro');
      achievements.insert(0, 'Sound Maestro');
      return profile.copyWith(
        audioCustomized: true,
        unlockedAchievements: achievements.take(6).toList(growable: false),
      );
    });
  }

  Future<void> markRatePromptShown() async {
    await _writeProfile((profile) {
      if (!profile.showRatePrompt) {
        return profile;
      }
      return profile.copyWith(showRatePrompt: false);
    });
  }

  Future<void> setRemoveAdsPurchased(bool value) async {
    await _writeProfile((profile) {
      if (profile.hasRemoveAdsPurchase == value) {
        return profile;
      }
      return profile.copyWith(hasRemoveAdsPurchase: value);
    });
  }

  Future<void> recordDailyChallengeCompletion(bool completed) async {
    await _writeProfile((profile) {
      if (profile.dailyChallengeCompleted == completed) {
        return profile;
      }
      return profile.copyWith(dailyChallengeCompleted: completed);
    });
  }

  Future<void> resetProfile() async {
    await _writeProfile((_) => PlayerProfile.defaults);
  }

  Future<void> _writeProfile(
    PlayerProfile Function(PlayerProfile current) transformer,
  ) async {
    if (!_initialized) {
      await ensureInitialized();
    }
    final updated = transformer(_profileNotifier.value);
    _profileNotifier.value = updated;
    await _preferences?.setString(_prefsKey, jsonEncode(updated.toJson()));
  }
}

class PlayerProfile {
  const PlayerProfile({
    required this.levelsCompleted,
    required this.currentStreak,
    required this.coinsEarned,
    required this.currentLevel,
    required this.levelProgress,
    required this.unlockedAchievements,
    required this.shareCount,
    required this.audioCustomized,
    required this.showRatePrompt,
    required this.hasRemoveAdsPurchase,
    required this.dailyChallengeCompleted,
  });

  final int levelsCompleted;
  final int currentStreak;
  final int coinsEarned;
  final int currentLevel;
  final double levelProgress;
  final List<String> unlockedAchievements;
  final int shareCount;
  final bool audioCustomized;
  final bool showRatePrompt;
  final bool hasRemoveAdsPurchase;
  final bool dailyChallengeCompleted;

  static const PlayerProfile defaults = PlayerProfile(
    levelsCompleted: 47,
    currentStreak: 12,
    coinsEarned: 2850,
    currentLevel: 48,
    levelProgress: 0.65,
    unlockedAchievements: ['Speed Demon', 'Perfectionist'],
    shareCount: 1,
    audioCustomized: false,
    showRatePrompt: true,
    hasRemoveAdsPurchase: false,
    dailyChallengeCompleted: false,
  );

  PlayerProfile copyWith({
    int? levelsCompleted,
    int? currentStreak,
    int? coinsEarned,
    int? currentLevel,
    double? levelProgress,
    List<String>? unlockedAchievements,
    int? shareCount,
    bool? audioCustomized,
    bool? showRatePrompt,
    bool? hasRemoveAdsPurchase,
    bool? dailyChallengeCompleted,
  }) {
    return PlayerProfile(
      levelsCompleted: levelsCompleted ?? this.levelsCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      currentLevel: currentLevel ?? this.currentLevel,
      levelProgress: levelProgress ?? this.levelProgress,
      unlockedAchievements:
          unlockedAchievements ?? List<String>.from(this.unlockedAchievements),
      shareCount: shareCount ?? this.shareCount,
      audioCustomized: audioCustomized ?? this.audioCustomized,
      showRatePrompt: showRatePrompt ?? this.showRatePrompt,
      hasRemoveAdsPurchase:
          hasRemoveAdsPurchase ?? this.hasRemoveAdsPurchase,
      dailyChallengeCompleted:
          dailyChallengeCompleted ?? this.dailyChallengeCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelsCompleted': levelsCompleted,
      'currentStreak': currentStreak,
      'coinsEarned': coinsEarned,
      'currentLevel': currentLevel,
      'levelProgress': levelProgress,
      'unlockedAchievements': unlockedAchievements,
      'shareCount': shareCount,
      'audioCustomized': audioCustomized,
      'showRatePrompt': showRatePrompt,
      'hasRemoveAdsPurchase': hasRemoveAdsPurchase,
      'dailyChallengeCompleted': dailyChallengeCompleted,
    };
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      levelsCompleted: json['levelsCompleted'] as int? ?? defaults.levelsCompleted,
      currentStreak: json['currentStreak'] as int? ?? defaults.currentStreak,
      coinsEarned: json['coinsEarned'] as int? ?? defaults.coinsEarned,
      currentLevel: json['currentLevel'] as int? ?? defaults.currentLevel,
      levelProgress: (json['levelProgress'] as num?)?.toDouble() ??
          defaults.levelProgress,
      unlockedAchievements: (json['unlockedAchievements'] as List?)
              ?.cast<String>()
              .toList(growable: false) ??
          defaults.unlockedAchievements,
      shareCount: json['shareCount'] as int? ?? defaults.shareCount,
      audioCustomized: json['audioCustomized'] as bool? ??
          defaults.audioCustomized,
      showRatePrompt: json['showRatePrompt'] as bool? ??
          defaults.showRatePrompt,
      hasRemoveAdsPurchase: json['hasRemoveAdsPurchase'] as bool? ??
          defaults.hasRemoveAdsPurchase,
      dailyChallengeCompleted:
          json['dailyChallengeCompleted'] as bool? ?? defaults.dailyChallengeCompleted,
    );
  }
}
