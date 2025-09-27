import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/services/achievements_tracker_service.dart';
import '../../core/services/player_profile_service.dart';
import '../../theme/app_theme.dart';

class AchievementsScreenArgs {
  const AchievementsScreenArgs({
    required this.levelsCompleted,
    required this.currentStreak,
    required this.coinsEarned,
    required this.unlockedAchievements,
    required this.shareCount,
    required this.audioCustomized,
  });

  final int levelsCompleted;
  final int currentStreak;
  final int coinsEarned;
  final List<String> unlockedAchievements;
  final int shareCount;
  final bool audioCustomized;

  factory AchievementsScreenArgs.fromProfile(PlayerProfile profile) {
    return AchievementsScreenArgs(
      levelsCompleted: profile.levelsCompleted,
      currentStreak: profile.currentStreak,
      coinsEarned: profile.coinsEarned,
      unlockedAchievements: profile.unlockedAchievements,
      shareCount: profile.shareCount,
      audioCustomized: profile.audioCustomized,
    );
  }
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.currentValue,
    required this.goalValue,
    required this.reward,
    this.category,
    this.tip,
  });

  final String id;
  final String title;
  final String description;
  final int currentValue;
  final int goalValue;
  final int reward;
  final String? category;
  final String? tip;

  double get progress => (currentValue / goalValue).clamp(0, 1).toDouble();
  bool get isUnlocked => currentValue >= goalValue;
  int get remaining => (goalValue - currentValue).clamp(0, goalValue);
}

enum AchievementFilter { all, unlocked, inProgress }

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, required this.args});

  final AchievementsScreenArgs args;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late final AchievementsTrackerService _trackerService;
  late final PlayerProfileService _profileService;
  late AchievementsScreenArgs _args;
  AchievementFilter _filter = AchievementFilter.all;
  late final VoidCallback _trackerListener;
  late final VoidCallback _profileListener;

  @override
  void initState() {
    super.initState();
    _args = widget.args;
    _trackerService = AchievementsTrackerService.instance;
    _profileService = PlayerProfileService.instance;
    _trackerListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _trackerService.ensureInitialized().then((_) {
      if (!mounted) return;
      setState(() {});
    });
    _trackerService.trackedListenable.addListener(_trackerListener);
    _profileService.ensureInitialized().then((_) {
      if (!mounted) return;
      setState(() {
        _args = AchievementsScreenArgs.fromProfile(
          _profileService.currentProfile,
        );
      });
    });
    _profileListener = () {
      if (!mounted) return;
      setState(() {
        _args = AchievementsScreenArgs.fromProfile(
          _profileService.currentProfile,
        );
      });
    };
    _profileService.profileListenable.addListener(_profileListener);
  }

  @override
  void dispose() {
    _trackerService.trackedListenable.removeListener(_trackerListener);
    _profileService.profileListenable.removeListener(_profileListener);
    super.dispose();
  }

  List<Achievement> _buildAchievements() {
    final args = _args;
    return [
      Achievement(
        id: 'streak_master',
        title: 'Streak Master',
        description: 'Maintain a 10 day play streak.',
        currentValue: args.currentStreak,
        goalValue: 10,
        reward: 150,
        category: 'Consistency',
        tip:
            'Launch SortBliss at least once a day—daily challenges count towards the streak.',
      ),
      Achievement(
        id: 'coin_collector',
        title: 'Coin Collector',
        description: 'Earn a total of 5,000 coins.',
        currentValue: args.coinsEarned,
        goalValue: 5000,
        reward: 200,
        category: 'Economy',
        tip: 'Complete high-difficulty levels to maximize coin multipliers.',
      ),
      Achievement(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Finish a level in under 30 seconds.',
        currentValue:
            args.unlockedAchievements.contains('Speed Demon') ? 1 : 0,
        goalValue: 1,
        reward: 100,
        category: 'Skill',
        tip: 'Use quick-sort power ups to shave off precious seconds.',
      ),
      Achievement(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Achieve a flawless run with no mistakes.',
        currentValue:
            args.unlockedAchievements.contains('Perfectionist') ? 1 : 0,
        goalValue: 1,
        reward: 120,
        category: 'Skill',
        tip: 'Slow down and preview the full board before making your first move.',
      ),
      Achievement(
        id: 'level_grinder',
        title: 'Level Grinder',
        description: 'Complete 75 campaign levels.',
        currentValue: args.levelsCompleted,
        goalValue: 75,
        reward: 250,
        category: 'Progression',
        tip: 'Revisit starred levels on Hard mode for additional completions.',
      ),
      Achievement(
        id: 'daily_devotee',
        title: 'Daily Devotee',
        description: 'Finish 7 daily challenges in a row.',
        currentValue: args.currentStreak.clamp(0, 7),
        goalValue: 7,
        reward: 175,
        category: 'Consistency',
        tip: 'Enable notifications in Settings to get a nudge when a new challenge drops.',
      ),
      Achievement(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description: 'Share your progress with friends three times.',
        currentValue: args.shareCount.clamp(0, 3),
        goalValue: 3,
        reward: 90,
        category: 'Community',
        tip: 'Use the Share Progress shortcut on the main menu after every milestone.',
      ),
      Achievement(
        id: 'sound_maestro',
        title: 'Sound Maestro',
        description: 'Customize audio settings to perfection.',
        currentValue: args.audioCustomized ? 1 : 0,
        goalValue: 1,
        reward: 60,
        category: 'Customization',
        tip: 'Toggle both music and effects in Settings to find your perfect mix.',
      ),
    ];
  }

  List<Achievement> _filterAchievements(List<Achievement> achievements) {
    switch (_filter) {
      case AchievementFilter.unlocked:
        return achievements
            .where((achievement) => achievement.isUnlocked)
            .toList(growable: false);
      case AchievementFilter.inProgress:
        return achievements
            .where(
              (achievement) =>
                  !achievement.isUnlocked && achievement.currentValue > 0,
            )
            .toList(growable: false);
      case AchievementFilter.all:
      default:
        return achievements;
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements();
    final filteredAchievements = _filterAchievements(achievements);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryChips(),
              SizedBox(height: 2.h),
              _buildFilterToggle(),
              SizedBox(height: 2.h),
              Expanded(
                child: filteredAchievements.isEmpty
                    ? _buildEmptyState()
                    : Builder(
                        builder: (context) {
                          return ListView.separated(
                            itemBuilder: (context, index) {
                              final achievement = filteredAchievements[index];
                              return _AchievementCard(
                                achievement: achievement,
                                isTracked:
                                    _trackerService.isTracked(achievement.id),
                                onTap: () => _showAchievementDetails(achievement),
                                onToggleTracked: () => _trackerService
                                    .toggleTracked(achievement.id),
                              );
                            },
                            separatorBuilder: (_, __) => SizedBox(height: 1.8.h),
                            itemCount: filteredAchievements.length,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChips() {
    final args = _args;
    final colorScheme = AppTheme.lightTheme.colorScheme;
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: [
        _SummaryChip(
          icon: Icons.emoji_events,
          label: 'Levels: ${args.levelsCompleted}',
          backgroundColor: colorScheme.primary.withOpacity(0.12),
          foregroundColor: colorScheme.primary,
        ),
        _SummaryChip(
          icon: Icons.local_fire_department,
          label: 'Streak: ${args.currentStreak} days',
          backgroundColor: Colors.orange.withOpacity(0.12),
          foregroundColor: Colors.orange,
        ),
        _SummaryChip(
          icon: Icons.savings,
          label: 'Coins: ${args.coinsEarned}',
          backgroundColor: Colors.amber.withOpacity(0.12),
          foregroundColor: Colors.amber.shade800,
        ),
      ],
    );
  }

  Widget _buildFilterToggle() {
    final selectedIndex = AchievementFilter.values.indexOf(_filter);
    return SegmentedButton<int>(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.2.h),
        ),
      ),
      segments: const [
        ButtonSegment(value: 0, label: Text('All')),
        ButtonSegment(value: 1, label: Text('Unlocked')),
        ButtonSegment(value: 2, label: Text('In Progress')),
      ],
      selected: <int>{selectedIndex},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        setState(() {
          _filter = AchievementFilter.values[selection.first];
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 14.w, color: Colors.grey.shade500),
          SizedBox(height: 2.h),
          Text(
            'No achievements to show yet.',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Text(
            'Keep playing to unlock more milestones!',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showAchievementDetails(Achievement achievement) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isTracked = _trackerService.isTracked(achievement.id);
            return _AchievementDetailSheet(
              achievement: achievement,
              isTracked: isTracked,
              onToggleTracked: () async {
                await _trackerService.toggleTracked(achievement.id);
                if (mounted) {
                  setState(() {});
                }
                setSheetState(() {});
              },
            );
          },
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.isTracked,
    required this.onTap,
    required this.onToggleTracked,
  });

  final Achievement achievement;
  final bool isTracked;
  final VoidCallback onTap;
  final Future<void> Function() onToggleTracked;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnlocked = achievement.isUnlocked;
    final bool highlight = isTracked && !isUnlocked;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isUnlocked
                ? colorScheme.primary.withOpacity(0.12)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? colorScheme.secondary
                  : isUnlocked
                      ? colorScheme.primary.withOpacity(0.4)
                      : colorScheme.outlineVariant,
              width: highlight ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isUnlocked
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                child: Icon(
                  isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                  color: isUnlocked
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.title,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (achievement.category != null)
                          Chip(
                            padding: EdgeInsets.zero,
                            label: Text(
                              achievement.category!,
                              style: TextStyle(fontSize: 9.sp),
                            ),
                          ),
                        IconButton(
                          tooltip: isTracked
                              ? 'Remove from focus list'
                              : 'Track this achievement',
                          iconSize: 18,
                          onPressed: () async {
                            await onToggleTracked();
                          },
                          icon: Icon(
                            isTracked
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 0.6.h),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: achievement.progress,
              minHeight: 0.9.h,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                isUnlocked ? colorScheme.primary : colorScheme.secondary,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnlocked
                    ? 'Completed'
                    : '${achievement.currentValue}/${achievement.goalValue}',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.savings_outlined, size: 16),
                  SizedBox(width: 1.w),
                  Text('+${achievement.reward}')
                ],
              ),
            ],
          ),
          if (!isUnlocked)
            Padding(
              padding: EdgeInsets.only(top: 0.8.h),
              child: Text(
                '${achievement.remaining} more to unlock',
                style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
              ),
            )
        ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor, size: 16),
          SizedBox(width: 1.5.w),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
          )
        ],
      ),
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  const _AchievementDetailSheet({
    required this.achievement,
    required this.isTracked,
    required this.onToggleTracked,
  });

  final Achievement achievement;
  final bool isTracked;
  final Future<void> Function() onToggleTracked;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 5.w,
        right: 5.w,
        top: 3.h,
        bottom: MediaQuery.of(context).padding.bottom + 3.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (achievement.category != null)
                Chip(
                  label: Text(achievement.category!),
                ),
            ],
          ),
          SizedBox(height: 1.2.h),
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 10.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: achievement.progress,
            minHeight: 1.1.h,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(
              achievement.isUnlocked
                  ? colorScheme.primary
                  : colorScheme.secondary,
            ),
          ),
          SizedBox(height: 1.2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                achievement.isUnlocked
                    ? 'Completed'
                    : '${achievement.currentValue}/${achievement.goalValue}',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10.sp),
              ),
              Row(
                children: [
                  const Icon(Icons.savings_outlined, size: 18),
                  SizedBox(width: 1.w),
                  Text('+${achievement.reward}')
                ],
              )
            ],
          ),
          if (!achievement.isUnlocked)
            Padding(
              padding: EdgeInsets.only(top: 1.5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined, size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      achievement.tip ??
                          'Keep playing regularly to make progress towards this goal.',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  )
                ],
              ),
            ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final status = achievement.isUnlocked
                        ? 'I just unlocked the "${achievement.title}" achievement in SortBliss!'
                        : 'I\'m chasing the "${achievement.title}" achievement in SortBliss! '
                            '${achievement.remaining > 0 ? 'Only ${achievement.remaining} more to go.' : 'Almost there!'}';
                    Share.share(
                      status,
                      subject: 'SortBliss achievement update',
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share progress'),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton.filledTonal(
                tooltip: isTracked
                    ? 'Remove from focus list'
                    : 'Track this achievement',
                onPressed: () async {
                  await onToggleTracked();
                },
                icon: Icon(
                  isTracked ? Icons.push_pin : Icons.push_pin_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
