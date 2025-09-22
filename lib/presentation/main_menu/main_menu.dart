import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/animated_background_widget.dart';
import './widgets/daily_challenge_widget.dart';
import './widgets/level_progress_widget.dart';
import './widgets/menu_action_button_widget.dart';
import './widgets/play_button_widget.dart';
import './widgets/player_stats_widget.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final MonetizationManager _monetizationManager =
      MonetizationManager.instance;

  // Mock data for the main menu
  final Map<String, dynamic> playerData = {
    "levelsCompleted": 47,
    "currentStreak": 12,
    "coinsEarned": 2850,
    "currentLevel": 48,
    "levelProgress": 0.65,
    "dailyChallengeCompleted": false,
    "timeUntilReset": "14h 32m",
    "recentAchievements": ["Speed Demon", "Perfectionist"],
    "showRatePrompt": false,
    "hasRemoveAdsPurchase": false,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    playerData["coinsEarned"] = _monetizationManager.coinBalance.value;
    playerData["hasRemoveAdsPurchase"] = _monetizationManager.isAdFree;

    _monetizationManager.coinBalance.addListener(_onCoinBalanceChanged);
    _monetizationManager.addListener(_onMonetizationChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _monetizationManager.coinBalance.removeListener(_onCoinBalanceChanged);
    _monetizationManager.removeListener(_onMonetizationChanged);
    super.dispose();
  }

  void _onCoinBalanceChanged() {
    if (!mounted) return;
    setState(() {
      playerData["coinsEarned"] = _monetizationManager.coinBalance.value;
    });
  }

  void _onMonetizationChanged() {
    if (!mounted) return;
    setState(() {
      playerData["hasRemoveAdsPurchase"] = _monetizationManager.isAdFree;
    });
  }

  void _navigateToGameplay() {
    Navigator.pushNamed(context, '/gameplay-screen');
  }

  void _navigateToDailyChallenge() {
    // Navigate to daily challenge screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily Challenge coming soon!')),
    );
  }

  void _navigateToAchievements() {
    // Navigate to achievements screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Achievements screen coming soon!')),
    );
  }

  void _navigateToSettings() {
    // Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings screen coming soon!')),
    );
  }

  void _shareProgress() {
    final currentLevel = playerData["currentLevel"] as int;
    final coins = _monetizationManager.coinBalance.value;
    final shareUri = Uri.https('sortbliss.app.link', '/progress', {
      'level': '$currentLevel',
      'coins': '$coins',
      'utm_source': 'app',
      'utm_medium': 'share',
      'utm_campaign': 'progress_share',
    });

    AnalyticsLogger.logEvent('share_progress_initiated',
        parameters: {'level': currentLevel, 'coins': coins});

    Share.share(
      'I just completed level $currentLevel in SortBliss with $coins coins! Join me: $shareUri',
      subject: 'SortBliss progress',
    );
  }

  void _rateApp() {
    final inAppReview = InAppReview.instance;
    AnalyticsLogger.logEvent('rate_prompt_requested');

    inAppReview.isAvailable().then((available) async {
      if (!mounted) return;
      if (available) {
        await inAppReview.requestReview();
        AnalyticsLogger.logEvent('rate_prompt_shown');
      } else {
        await inAppReview.openStoreListing();
        AnalyticsLogger.logEvent('rate_store_listing_opened');
      }
    }).catchError((error) {
      AnalyticsLogger.logEvent('rate_prompt_error',
          parameters: {'error': '$error'});
    });
  }

  void _purchaseRemoveAds() {
    if (_monetizationManager.isAdFree) {
      AnalyticsLogger.logEvent('remove_ads_already_owned');
      return;
    }

    AnalyticsLogger.logEvent('remove_ads_cta_tapped');
    _monetizationManager.buyProduct(MonetizationProducts.removeAds);
  }

  void _purchaseProduct(String productId) {
    if (productId == MonetizationProducts.sortPass &&
        _monetizationManager.hasSortPass) {
      AnalyticsLogger.logEvent('sort_pass_already_owned');
      return;
    }
    AnalyticsLogger.logEvent('storefront_product_tapped',
        parameters: {'productId': productId});
    _monetizationManager.buyProduct(productId);
  }

  String _priceForProduct(String productId, String fallback) {
    final details = _monetizationManager.productForId(productId);
    return details?.price ?? fallback;
  }

  Widget _buildPullDownMenu() {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 2.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Storefront',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
          ),
          SizedBox(height: 1.5.h),
          if (!(playerData["hasRemoveAdsPurchase"] as bool)) ...[
            MenuActionButtonWidget(
              iconName: 'block',
              title: 'Remove Ads',
              subtitle:
                  'One-time purchase - ${_priceForProduct(MonetizationProducts.removeAds, '\$2.99')}',
              onPressed: _purchaseRemoveAds,
              iconColor: Colors.red,
            ),
            SizedBox(height: 1.5.h),
          ] else ...[
            Container(
              width: 90.w,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Ads removed — thank you for supporting SortBliss!',
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.5.h),
          ],
          MenuActionButtonWidget(
            iconName: 'paid',
            title: 'Pocketful of Coins',
            subtitle:
                '250 coins - ${_priceForProduct(MonetizationProducts.coinPackSmall, '\$1.99')}',
            onPressed: () =>
                _purchaseProduct(MonetizationProducts.coinPackSmall),
            iconColor: Colors.amber,
          ),
          SizedBox(height: 1.5.h),
          MenuActionButtonWidget(
            iconName: 'savings',
            title: 'Treasure Trove',
            subtitle:
                '750 coins - ${_priceForProduct(MonetizationProducts.coinPackLarge, '\$4.99')}',
            onPressed: () =>
                _purchaseProduct(MonetizationProducts.coinPackLarge),
            iconColor: Colors.deepOrange,
          ),
          SizedBox(height: 1.5.h),
          MenuActionButtonWidget(
            iconName: 'diamond',
            title: 'Epic Hoard',
            subtitle:
                '2,000 coins - ${_priceForProduct(MonetizationProducts.coinPackEpic, '\$9.99')}',
            onPressed: () =>
                _purchaseProduct(MonetizationProducts.coinPackEpic),
            iconColor: Colors.purple,
          ),
          SizedBox(height: 1.5.h),
          MenuActionButtonWidget(
            iconName: 'workspace_premium',
            title: 'Sort Pass Premium',
            subtitle:
                'Unlock exclusive levels - ${_priceForProduct(MonetizationProducts.sortPass, '\$14.99')}',
            onPressed: () =>
                _purchaseProduct(MonetizationProducts.sortPass),
            iconColor: Colors.teal,
            showBadge: !_monetizationManager.hasSortPass,
          ),
          SizedBox(height: 2.h),
          MenuActionButtonWidget(
            iconName: 'share',
            title: 'Share Progress',
            subtitle: 'Tell friends about your achievements',
            onPressed: _shareProgress,
            iconColor: Colors.blue,
          ),
          SizedBox(height: 2.h),
          MenuActionButtonWidget(
            iconName: 'star',
            title: 'Rate SortBliss',
            subtitle: 'Help us improve the game',
            onPressed: _rateApp,
            iconColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const AnimatedBackgroundWidget(),
            FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh daily challenges and leaderboard data
                  await Future.delayed(const Duration(seconds: 1));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data refreshed!')),
                    );
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 2.h),
                      // App Logo/Title
                      Text(
                        'SortBliss',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Organize. Sort. Relax.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // Player Stats
                      PlayerStatsWidget(
                        levelsCompleted: playerData["levelsCompleted"] as int,
                        currentStreak: playerData["currentStreak"] as int,
                        coinsEarned: playerData["coinsEarned"] as int,
                      ),
                      SizedBox(height: 3.h),

                      // Level Progress
                      LevelProgressWidget(
                        currentLevel: playerData["currentLevel"] as int,
                        progressPercentage:
                            playerData["levelProgress"] as double,
                      ),
                      SizedBox(height: 4.h),

                      // Play Button
                      PlayButtonWidget(
                        onPressed: _navigateToGameplay,
                      ),
                      SizedBox(height: 4.h),

                      // Daily Challenge
                      DailyChallengeWidget(
                        timeRemaining: playerData["timeUntilReset"] as String,
                        isCompleted:
                            playerData["dailyChallengeCompleted"] as bool,
                        onPressed: _navigateToDailyChallenge,
                      ),
                      SizedBox(height: 3.h),

                      // Achievements
                      MenuActionButtonWidget(
                        iconName: 'emoji_events',
                        title: 'Achievements',
                        subtitle:
                            'Recent: ${(playerData["recentAchievements"] as List).join(", ")}',
                        onPressed: _navigateToAchievements,
                        iconColor: Colors.orange,
                        showBadge: (playerData["recentAchievements"] as List)
                            .isNotEmpty,
                      ),
                      SizedBox(height: 3.h),

                      // Settings
                      MenuActionButtonWidget(
                        iconName: 'settings',
                        title: 'Settings',
                        subtitle: 'Sound, vibration, tutorial',
                        onPressed: _navigateToSettings,
                        iconColor: Colors.grey,
                      ),
                      SizedBox(height: 6.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
