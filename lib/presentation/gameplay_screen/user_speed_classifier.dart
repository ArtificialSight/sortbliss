import 'package:flutter/foundation.dart';

/// Profiles describing how quickly a user is completing moves relative to the
/// expected cadence of the game.
enum UserSpeedProfile { slow, balanced, fast }

/// Thresholds used to classify a user's speed.
@visibleForTesting
const double kFastUserSpeedThreshold = 1.5;
@visibleForTesting
const double kSlowUserSpeedThreshold = 0.7;

/// Adaptive delays applied to tutorial steps depending on the user's pace.
@visibleForTesting
const double kFastUserAdaptiveDelay = 0.7;
@visibleForTesting
const double kBalancedUserAdaptiveDelay = 1.0;
@visibleForTesting
const double kSlowUserAdaptiveDelay = 1.5;

/// Classifies the [userSpeed] into a [UserSpeedProfile] using the configured
/// thresholds.
UserSpeedProfile classifyUserSpeed(
  double userSpeed, {
  double fastThreshold = kFastUserSpeedThreshold,
  double slowThreshold = kSlowUserSpeedThreshold,
}) {
  if (userSpeed >= fastThreshold) {
    return UserSpeedProfile.fast;
  }

  if (userSpeed <= slowThreshold) {
    return UserSpeedProfile.slow;
  }

  return UserSpeedProfile.balanced;
}

/// Returns the adaptive delay value that should be used for the provided
/// [userSpeed].
double calculateAdaptiveDelay(
  double userSpeed, {
  double fastThreshold = kFastUserSpeedThreshold,
  double slowThreshold = kSlowUserSpeedThreshold,
  double fastDelay = kFastUserAdaptiveDelay,
  double balancedDelay = kBalancedUserAdaptiveDelay,
  double slowDelay = kSlowUserAdaptiveDelay,
}) {
  switch (classifyUserSpeed(
    userSpeed,
    fastThreshold: fastThreshold,
    slowThreshold: slowThreshold,
  )) {
    case UserSpeedProfile.fast:
      return fastDelay;
    case UserSpeedProfile.balanced:
      return balancedDelay;
    case UserSpeedProfile.slow:
      return slowDelay;
  }
}
