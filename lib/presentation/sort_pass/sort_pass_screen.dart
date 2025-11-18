import 'package:flutter/material.dart';
import 'package:sortbliss/core/monetization/monetization_manager.dart';
import 'package:sortbliss/core/analytics/analytics_logger.dart';

/// Sort Pass premium subscription screen
/// Premium tier: $4.99/month for power users
/// ARPU Impact: +$0.40-0.60 for 10-15% of users who subscribe
class SortPassScreen extends StatefulWidget {
  const SortPassScreen({super.key});

  @override
  State<SortPassScreen> createState() => _SortPassScreenState();
}

class _SortPassScreenState extends State<SortPassScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isLoading = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _checkSubscriptionStatus();

    AnalyticsLogger.logEvent('sort_pass_screen_viewed');
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _checkSubscriptionStatus() {
    setState(() {
      _isSubscribed = MonetizationManager.instance.hasSortPass;
    });
  }

  Future<void> _subscribe() async {
    setState(() {
      _isLoading = true;
    });

    AnalyticsLogger.logEvent('sort_pass_subscribe_initiated');

    try {
      await MonetizationManager.instance.buyProduct(
        MonetizationProducts.sortPass,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Welcome to Sort Pass Premium! 🎉'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Refresh subscription status
        await Future.delayed(const Duration(seconds: 1));
        _checkSubscriptionStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      AnalyticsLogger.logEvent('sort_pass_subscribe_failed', parameters: {
        'error': e.toString(),
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_isSubscribed) _buildActiveSubscriptionBanner(),
                  if (!_isSubscribed) ...[
                    _buildHeroSection(),
                    const SizedBox(height: 32),
                    _buildFeaturesList(),
                    const SizedBox(height: 32),
                    _buildPricingCard(),
                    const SizedBox(height: 24),
                    _buildSubscribeButton(),
                    const SizedBox(height: 16),
                    _buildLegalText(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Sort Pass Premium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade700.withOpacity(0.8),
                Colors.blue.shade700.withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.workspace_premium,
              size: 80,
              color: Colors.amber.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.teal.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'re a Premium Member!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoying unlimited hints, no ads, and exclusive content',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade400,
                    Colors.amber.shade600,
                    Colors.amber.shade400,
                  ],
                  stops: [
                    _shimmerController.value - 0.3,
                    _shimmerController.value,
                    _shimmerController.value + 0.3,
                  ],
                ).createShader(bounds);
              },
              child: const Icon(
                Icons.workspace_premium,
                size: 120,
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Unlock the Ultimate\nSorting Experience',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Everything you need to master every level',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      FeatureItem(
        icon: Icons.lightbulb_outline,
        title: 'Unlimited Smart Hints',
        description: 'AI-powered hints whenever you need them - no ads required',
        color: Colors.amber,
      ),
      FeatureItem(
        icon: Icons.block,
        title: 'Ad-Free Experience',
        description: 'Zero interruptions, pure gameplay focus',
        color: Colors.red,
      ),
      FeatureItem(
        icon: Icons.auto_awesome,
        title: 'Exclusive Levels',
        description: 'Access to premium levels and special challenges',
        color: Colors.purple,
      ),
      FeatureItem(
        icon: Icons.trending_up,
        title: '2x Coin Multiplier',
        description: 'Earn double coins on every level completion',
        color: Colors.green,
      ),
      FeatureItem(
        icon: Icons.emoji_events,
        title: 'Priority Support',
        description: 'Get help faster when you need it',
        color: Colors.blue,
      ),
      FeatureItem(
        icon: Icons.speed,
        title: 'Power-Up Bonuses',
        description: 'Extra speed boosts and accuracy helpers',
        color: Colors.orange,
      ),
    ];

    return Column(
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: feature.color.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature.icon,
                  color: feature.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade700,
            Colors.blue.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '4.99',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Text(
            'per month',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber,
                width: 2,
              ),
            ),
            child: const Text(
              '🔥 First 7 Days FREE',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _subscribe,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Text(
                'Start Free Trial',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLegalText() {
    return Text(
      'Cancel anytime. After free trial, subscription auto-renews at \$4.99/month unless cancelled. Terms apply.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 11,
      ),
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
