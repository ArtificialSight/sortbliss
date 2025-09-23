import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/daily_challenge_service.dart';

class DailyChallengeScreenArgs {
  const DailyChallengeScreenArgs({
    required this.service,
    required this.initialChallenge,
  });

  final DailyChallengeService service;
  final DailyChallengePayload initialChallenge;
}

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({
    super.key,
    required this.service,
    required this.initialChallenge,
  });

  final DailyChallengeService service;
  final DailyChallengePayload initialChallenge;

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  late DailyChallengePayload _challenge;
  WeeklyEventSchedule? _weeklySchedule;
  Duration _timeRemaining = Duration.zero;
  bool _loadingWeeklyEvents = true;
  bool _launchingLevel = false;
  bool _claimingRewards = false;

  StreamSubscription<DailyChallengePayload>? _challengeSub;
  StreamSubscription<Duration>? _countdownSub;

  @override
  void initState() {
    super.initState();
    _challenge = widget.initialChallenge;
    _timeRemaining = _challenge.timeUntilReset;
    _challengeSub = widget.service.challengeStream.listen((payload) {
      if (!mounted) return;
      setState(() {
        _challenge = payload;
      });
    });
    _countdownSub = widget.service
        .countdownStream(_challenge.resetAt)
        .listen((duration) {
      if (!mounted) return;
      setState(() {
        _timeRemaining = duration;
      });
    });
    _loadWeeklyEvents();
  }

  Future<void> _loadWeeklyEvents() async {
    setState(() {
      _loadingWeeklyEvents = true;
    });
    try {
      final schedule = await widget.service.loadWeeklyEvents();
      if (!mounted) return;
      setState(() {
        _weeklySchedule = schedule;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load weekly events: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingWeeklyEvents = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _challengeSub?.cancel();
    _countdownSub?.cancel();
    super.dispose();
  }

  Future<void> _startChallenge() async {
    setState(() {
      _launchingLevel = true;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final config = _challenge.levelConfig;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Launching ${config.layoutId} at difficulty ${config.difficulty}...'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _launchingLevel = false;
        });
      }
    }
  }

  Future<void> _claimRewards() async {
    if (!_challenge.isCompleted || _challenge.rewardsClaimed) {
      return;
    }
    setState(() {
      _claimingRewards = true;
    });
    try {
      final updated = await widget.service.claimRewards();
      if (!mounted) return;
      setState(() {
        _challenge = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rewards sent to your inbox!')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _claimingRewards = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  Widget _buildRewardChip(ChallengeReward reward) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      backgroundColor:
          reward.isExclusive ? colorScheme.secondaryContainer : colorScheme.surfaceVariant,
      label: Text(
        reward.isExclusive
            ? 'Exclusive ${reward.type} x${reward.amount}'
            : '${reward.type} x${reward.amount}',
        style: TextStyle(
          color: reward.isExclusive
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildWeeklySection() {
    if (_loadingWeeklyEvents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_weeklySchedule == null) {
      return const Text('Weekly events will appear here soon.');
    }
    final current = _weeklySchedule!.currentEvent;
    final next = _weeklySchedule!.nextEvent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (current != null) ...[
          Text(
            'Live Event: ${current.name}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text('Theme: ${current.theme}'),
          Text(
            'Ends ${_formatDuration(current.endAt.difference(DateTime.now().toUtc()))} from now',
          ),
          SizedBox(height: 1.h),
        ],
        if (next != null) ...[
          Text(
            'Next Event: ${next.name}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text('Kicks off ${next.startAt.toLocal().toString().split('.').first}'),
        ],
        if (current == null && next == null)
          const Text('No live ops scheduled for this week just yet.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenge'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await widget.service.loadDailyChallenge(forceRefresh: true);
          await _loadWeeklyEvents();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _challenge.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _challenge.description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    LinearProgressIndicator(
                      value: _challenge.progressRatio,
                      minHeight: 1.2.h,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _challenge.isCompleted
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress: ${_challenge.currentStars}/${_challenge.targetStars} ⭐'),
                        Text('Resets in ${_formatDuration(_timeRemaining)}'),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children:
                          _challenge.rewards.map(_buildRewardChip).toList(growable: false),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchingLevel ? null : _startChallenge,
                            icon: _launchingLevel
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              _launchingLevel ? 'Preparing...' : 'Launch Challenge',
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: (_claimingRewards ||
                                    !_challenge.isCompleted ||
                                    _challenge.rewardsClaimed)
                                ? null
                                : _claimRewards,
                            child: _claimingRewards
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _challenge.rewardsClaimed
                                        ? 'Rewards Claimed'
                                        : 'Claim Rewards',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Weekly Live Ops',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.5.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: _buildWeeklySection(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
