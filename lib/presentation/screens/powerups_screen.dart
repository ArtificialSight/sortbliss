import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/powerup_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';

/// Power-ups shop and inventory screen
///
/// Features:
/// - 2 tabs: Shop & My Power-Ups
/// - Individual power-up purchase
/// - Bundle deals
/// - Coin balance display
/// - IAP integration ready
/// - Purchase confirmation
/// - Inventory management
///
/// Power-Ups:
/// - Undo (3 coins)
/// - Hint (5 coins)
/// - Shuffle (10 coins)
/// - Auto-Sort (15 coins)
/// - Extra Moves (20 coins)
class PowerUpsScreen extends StatefulWidget {
  const PowerUpsScreen({Key? key}) : super(key: key);

  @override
  State<PowerUpsScreen> createState() => _PowerUpsScreenState();
}

class _PowerUpsScreenState extends State<PowerUpsScreen>
    with SingleTickerProviderStateMixin {
  final PowerUpService _powerUps = PowerUpService.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinBalance = _powerUps.getCoinBalance();

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with coin balance
            _buildHeader(coinBalance),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.lightTheme.primaryColor,
              labelColor: AppTheme.lightTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Shop'),
                Tab(text: 'My Power-Ups'),
              ],
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildShopTab(),
                  _buildInventoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int coinBalance) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.deepPurple.shade700],
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
                'Power-Ups',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: () => _showPowerUpsHelp(),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Coin balance card
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💰', style: TextStyle(fontSize: 8.w)),
                SizedBox(width: 2.w),
                Text(
                  coinBalance.toString(),
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Coins',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Individual power-ups
        Text(
          'Power-Ups',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),

        SizedBox(height: 2.h),

        _buildPowerUpItem(
          'Undo',
          '↩️',
          'Reverse your last move',
          3,
          Colors.blue,
        ),
        SizedBox(height: 2.h),

        _buildPowerUpItem(
          'Hint',
          '💡',
          'Get a helpful hint',
          5,
          Colors.amber,
        ),
        SizedBox(height: 2.h),

        _buildPowerUpItem(
          'Shuffle',
          '🔀',
          'Reorganize the items',
          10,
          Colors.purple,
        ),
        SizedBox(height: 2.h),

        _buildPowerUpItem(
          'Auto-Sort',
          '✨',
          'Auto-complete one section',
          15,
          Colors.green,
        ),
        SizedBox(height: 2.h),

        _buildPowerUpItem(
          'Extra Moves',
          '➕',
          'Add 5 extra moves',
          20,
          Colors.orange,
        ),

        SizedBox(height: 3.h),

        // Bundles
        Text(
          'Bundles',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),

        SizedBox(height: 2.h),

        ..._buildBundles(),

        SizedBox(height: 3.h),

        // Get more coins
        _buildGetMoreCoinsButton(),
      ],
    );
  }

  Widget _buildInventoryTab() {
    final inventory = _powerUps.getInventory();
    final hasAnyPowerUps = inventory.values.any((count) => count > 0);

    if (!hasAnyPowerUps) {
      return EmptyStateWidget.noPowerUps(
        onAction: () => _tabController.animateTo(0),
      );
    }

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Your Power-Ups',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),

        SizedBox(height: 2.h),

        _buildInventoryItem('Undo', '↩️', inventory['undo'] ?? 0, Colors.blue),
        SizedBox(height: 2.h),

        _buildInventoryItem('Hint', '💡', inventory['hint'] ?? 0, Colors.amber),
        SizedBox(height: 2.h),

        _buildInventoryItem(
            'Shuffle', '🔀', inventory['shuffle'] ?? 0, Colors.purple),
        SizedBox(height: 2.h),

        _buildInventoryItem(
            'Auto-Sort', '✨', inventory['autosort'] ?? 0, Colors.green),
        SizedBox(height: 2.h),

        _buildInventoryItem(
            'Extra Moves', '➕', inventory['extramoves'] ?? 0, Colors.orange),
      ],
    );
  }

  Widget _buildPowerUpItem(
    String name,
    String emoji,
    String description,
    int cost,
    Color color,
  ) {
    final canAfford = _powerUps.getCoinBalance() >= cost;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: TextStyle(fontSize: 8.w)),
          ),

          SizedBox(width: 4.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 2.w),

          // Buy button
          ElevatedButton(
            onPressed: canAfford
                ? () => _purchasePowerUp(name.toLowerCase(), cost)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cost.toString(),
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 1.w),
                Text('💰', style: TextStyle(fontSize: 4.w)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBundles() {
    final bundles = PowerUpService.getBundles();
    return bundles.map((bundle) => _buildBundleCard(bundle)).toList();
  }

  Widget _buildBundleCard(PowerUpBundle bundle) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.deepPurple.shade100],
        ),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: Colors.purple.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bundle.name,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              if (bundle.discount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    '${bundle.discount}% OFF',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 1.h),

          // Bundle items
          Wrap(
            spacing: 3.w,
            children: bundle.items.entries.map((entry) {
              return Text(
                '${entry.value}x ${entry.key}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 2.h),

          // Price and buy button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${bundle.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              ElevatedButton(
                onPressed: () => _purchaseBundle(bundle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
                child: Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(String name, String emoji, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: count > 0 ? color.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: count > 0 ? color.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: count > 0 ? color.withOpacity(0.2) : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 8.w, color: count > 0 ? null : Colors.grey),
            ),
          ),

          SizedBox(width: 4.w),

          // Name
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: count > 0 ? Colors.grey[900] : Colors.grey[500],
              ),
            ),
          ),

          // Count
          Text(
            'x$count',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: count > 0 ? color : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetMoreCoinsButton() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('💰', style: TextStyle(fontSize: 12.w)),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need More Coins?',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Play levels, complete achievements, and participate in events!',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.white, size: 6.w),
        ],
      ),
    );
  }

  Future<void> _purchasePowerUp(String powerUpId, int cost) async {
    final canAfford = await _powerUps.spendCoins(cost);

    if (!canAfford) {
      _showSnackBar('Not enough coins!');
      return;
    }

    await _powerUps.addPowerUp(powerUpId, 1);

    _showSnackBar('Purchased 1x ${powerUpId.capitalize()}!');
    setState(() {});
  }

  Future<void> _purchaseBundle(PowerUpBundle bundle) async {
    // TODO: Integrate with IAP
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bundle.name),
        content: Text(
          'Purchase ${bundle.name} for \$${bundle.price.toStringAsFixed(2)}?\n\n'
          'You will receive:\n${bundle.items.entries.map((e) => '• ${e.value}x ${e.key}').join('\n')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Process IAP
              _showSnackBar('Bundle purchase coming soon!');
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  void _showPowerUpsHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Power-Ups Guide'),
        content: const SingleChildScrollView(
          child: Text(
            'Power-Ups help you complete difficult levels!\n\n'
            '↩️ Undo: Reverse your last move\n\n'
            '💡 Hint: Get a suggestion for your next move\n\n'
            '🔀 Shuffle: Reorganize items for a fresh perspective\n\n'
            '✨ Auto-Sort: Automatically complete one section\n\n'
            '➕ Extra Moves: Add 5 extra moves to the level\n\n'
            'Earn coins by:\n'
            '• Completing levels\n'
            '• Unlocking achievements\n'
            '• Participating in events\n'
            '• Daily login rewards',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
