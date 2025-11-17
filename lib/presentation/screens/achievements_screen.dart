import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/achievement_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';

/// Achievements screen displaying all achievements
///
/// Features:
/// - Grid/list view toggle
/// - Category filtering
/// - Tier filtering (Bronze, Silver, Gold, Platinum)
/// - Progress tracking
/// - Locked/unlocked states
/// - Share achievement button
/// - Statistics summary
///
/// Categories:
/// - All
/// - Progression
/// - Mastery
/// - Collection
/// - Social
/// - Dedication
/// - Special
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final AchievementService _achievements = AchievementService.instance;

  late TabController _tabController;
  bool _gridView = true;
  AchievementCategory? _selectedCategory;
  AchievementTier? _selectedTier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with stats
            _buildHeader(),

            // Category tabs
            _buildCategoryTabs(),

            // View toggle and filters
            _buildControls(),

            // Achievements list/grid
            Expanded(
              child: _buildAchievementsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final summary = _achievements.getSummary();
    final progress = summary.total > 0 ? summary.unlocked / summary.total : 0.0;

    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade600],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // TODO: Share achievements progress
                },
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Progress card
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill(
                      '🏆',
                      '${summary.unlocked}',
                      'Unlocked',
                    ),
                    _buildStatPill(
                      '📊',
                      '${summary.total}',
                      'Total',
                    ),
                    _buildStatPill(
                      '💎',
                      '${(progress * 100).toStringAsFixed(0)}%',
                      'Complete',
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                ClipRRect(
                  borderRadius: BorderRadius.circular(2.w),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 1.5.h,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 5.w)),
            SizedBox(width: 1.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: AppTheme.lightTheme.primaryColor,
      labelColor: AppTheme.lightTheme.primaryColor,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: 'All'),
        Tab(text: 'Progression'),
        Tab(text: 'Mastery'),
        Tab(text: 'Collection'),
        Tab(text: 'Social'),
        Tab(text: 'Dedication'),
        Tab(text: 'Special'),
      ],
      onTap: (index) {
        setState(() {
          if (index == 0) {
            _selectedCategory = null;
          } else {
            _selectedCategory = AchievementCategory.values[index - 1];
          }
        });
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tier filter
          DropdownButton<AchievementTier?>(
            value: _selectedTier,
            hint: const Text('All Tiers'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Tiers')),
              ...AchievementTier.values.map(
                (tier) => DropdownMenuItem(
                  value: tier,
                  child: Text(_getTierName(tier)),
                ),
              ),
            ],
            onChanged: (tier) {
              setState(() {
                _selectedTier = tier;
              });
            },
          ),

          // View toggle
          IconButton(
            icon: Icon(_gridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _gridView = !_gridView;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    var achievements = _achievements.getAllAchievements();

    // Apply filters
    if (_selectedCategory != null) {
      achievements = achievements
          .where((a) => a.category == _selectedCategory)
          .toList();
    }

    if (_selectedTier != null) {
      achievements =
          achievements.where((a) => a.tier == _selectedTier).toList();
    }

    if (achievements.isEmpty) {
      return EmptyStateWidget.noAchievements(
        onAction: () => Navigator.of(context).pushNamed('/game'),
      );
    }

    return _gridView
        ? _buildGridView(achievements)
        : _buildListView(achievements);
  }

  Widget _buildGridView(List<Achievement> achievements) {
    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 3.w,
        crossAxisSpacing: 3.w,
        childAspectRatio: 0.8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index]);
      },
    );
  }

  Widget _buildListView(List<Achievement> achievements) {
    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: achievements.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        return _buildAchievementListTile(achievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final tierColor = _getTierColor(achievement.tier);

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isUnlocked
              ? tierColor.withOpacity(0.1)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(
            color: isUnlocked ? tierColor : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? tierColor.withOpacity(0.2)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 10.w,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),

            SizedBox(height: 2.h),

            // Name
            Text(
              achievement.name,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.grey[900] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 1.h),

            // Tier or progress
            if (isUnlocked)
              Text(
                _getTierName(achievement.tier),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: tierColor,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (achievement.currentProgress != null &&
                achievement.targetValue != null)
              Text(
                '${achievement.currentProgress}/${achievement.targetValue}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementListTile(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final tierColor = _getTierColor(achievement.tier);
    final hasProgress =
        achievement.currentProgress != null && achievement.targetValue != null;
    final progress = hasProgress
        ? achievement.currentProgress! / achievement.targetValue!
        : 0.0;

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isUnlocked
              ? tierColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(
            color: isUnlocked ? tierColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? tierColor.withOpacity(0.2)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 8.w,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),

            SizedBox(width: 4.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.grey[900] : Colors.grey[600],
                          ),
                        ),
                      ),
                      Text(
                        _getTierName(achievement.tier),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: tierColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 0.5.h),

                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (hasProgress) ...[
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1.w),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 1.h,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${achievement.currentProgress}/${achievement.targetValue}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            if (isUnlocked) ...[
              SizedBox(width: 2.w),
              Icon(Icons.check_circle, color: tierColor, size: 6.w),
            ],
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 80.w,
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Text(achievement.icon, style: TextStyle(fontSize: 20.w)),

              SizedBox(height: 2.h),

              // Name
              Text(
                achievement.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 1.h),

              // Tier
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _getTierColor(achievement.tier).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  _getTierName(achievement.tier),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _getTierColor(achievement.tier),
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Description
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              if (achievement.currentProgress != null &&
                  achievement.targetValue != null) ...[
                SizedBox(height: 2.h),
                Text(
                  'Progress: ${achievement.currentProgress}/${achievement.targetValue}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              if (achievement.isUnlocked && achievement.unlockedDate != null) ...[
                SizedBox(height: 2.h),
                Text(
                  'Unlocked: ${_formatDate(achievement.unlockedDate!)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (achievement.isUnlocked)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Share achievement
              },
              child: const Text('Share'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown;
      case AchievementTier.silver:
        return Colors.grey.shade600;
      case AchievementTier.gold:
        return Colors.amber;
      case AchievementTier.platinum:
        return Colors.blue.shade700;
    }
  }

  String _getTierName(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
