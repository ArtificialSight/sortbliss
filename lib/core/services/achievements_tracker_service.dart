import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight persistence for a player's tracked ("pinned") achievements.
///
/// The main menu and achievements screen can use this service to highlight
/// achievements that the player wants to focus on next. The service exposes a
/// [ValueListenable] so UIs can rebuild reactively when the tracked
/// achievements change.
class AchievementsTrackerService {
  AchievementsTrackerService._();

  static final AchievementsTrackerService instance =
      AchievementsTrackerService._();

  static const String _prefsKey = 'tracked_achievements_v1';

  final ValueNotifier<Set<String>> _trackedNotifier =
      ValueNotifier(const <String>{});

  SharedPreferences? _preferences;
  bool _initialized = false;
  Completer<void>? _pendingInitialization;

  /// Listen for tracked-achievement updates.
  ValueListenable<Set<String>> get trackedListenable => _trackedNotifier;

  /// Current snapshot of the tracked achievement identifiers.
  Set<String> get trackedIds => _trackedNotifier.value;

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (_pendingInitialization != null) {
      return _pendingInitialization!.future;
    }
    final completer = Completer<void>();
    _pendingInitialization = completer;
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final storedIds = _preferences?.getStringList(_prefsKey);
      if (storedIds != null) {
        _trackedNotifier.value = storedIds.toSet();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        // Surface the failure during development without breaking runtime.
        debugPrint(
          'Failed to initialize AchievementsTrackerService: $error\n$stackTrace',
        );
      }
    } finally {
      _initialized = true;
      completer.complete();
      _pendingInitialization = null;
    }
  }

  bool isTracked(String achievementId) {
    return _trackedNotifier.value.contains(achievementId);
  }

  Future<void> toggleTracked(String achievementId) async {
    if (!_initialized) {
      await ensureInitialized();
    }
    final updated = _trackedNotifier.value.toSet();
    if (!updated.add(achievementId)) {
      updated.remove(achievementId);
    }
    _trackedNotifier.value = updated;
    await _preferences?.setStringList(
      _prefsKey,
      updated.toList()..sort(),
    );
  }

  Future<void> clear() async {
    if (!_initialized) {
      await ensureInitialized();
    }
    _trackedNotifier.value = const <String>{};
    await _preferences?.remove(_prefsKey);
  }
}
