import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/powerup_service.dart';
import '../../core/services/animation_coordinator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/analytics_logger.dart';

/// Power-up shop widget for purchasing and managing power-ups
///
/// Displays:
/// - Individual power-up purchase options (with coins)
/// - Power-up bundles (IAP)
/// - Current power-up inventory
/// - Descriptions and use cases
class PowerUpShopWidget extends StatefulWidget {
  final int currentCoins;
  final Function(int coinCost)? onPurchaseWithCoins;
  final Function(PowerUpBundle bundle)? onPurchaseWithMoney;

  const PowerUpShopWidget({
    Key? key,
    required this.currentCoins,
    this.onPurchaseWithCoins,
    this.onPurchaseWithMoney,
  }) : super(key: key);

  @override
  State<PowerUpShopWidget> createState() => _PowerUpShopWidgetState();
}

class _PowerUpShopWidgetState extends State<PowerUpShopWidget>
    with SingleTickerProviderStateMixin {
  final PowerUpService _powerUpService = PowerUpService.instance;
  final AnimationCoordinator _animator = AnimationCoordinator.instance;

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
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Power-Up Shop',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await _animator.popupClose();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Coin balance
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on, color: Colors.amber, size: 6.w),
                SizedBox(width: 2.w),
                Text(
                  '${widget.currentCoins} coins',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.lightTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.lightTheme.primaryColor,
            tabs: const [
              Tab(text: 'Coin Shop'),
              Tab(text: 'Bundles'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoinShopTab(),
                _buildBundlesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinShopTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _PowerUpShopItem(
          icon: Icons.undo,
          name: 'Undo',
          description: 'Undo your last move',
          cost: PowerUpService.undoCost,
          owned: _powerUpService.getUndoCount(),
          currentCoins: widget.currentCoins,
          onPurchase: () => _purchaseWithCoins(PowerUpService.undoCost, 'undo'),
        ),
        SizedBox(height: 2.h),
        _PowerUpShopItem(
          icon: Icons.lightbulb,
          name: 'Hint',
          description: 'Show the best next move',
          cost: PowerUpService.hintCost,
          owned: _powerUpService.getHintCount(),
          currentCoins: widget.currentCoins,
          onPurchase: () => _purchaseWithCoins(PowerUpService.hintCost, 'hint'),
        ),
        SizedBox(height: 2.h),
        _PowerUpShopItem(
          icon: Icons.shuffle,
          name: 'Shuffle',
          description: 'Rearrange pieces randomly',
          cost: PowerUpService.shuffleCost,
          owned: _powerUpService.getShuffleCount(),
          currentCoins: widget.currentCoins,
          onPurchase: () => _purchaseWithCoins(PowerUpService.shuffleCost, 'shuffle'),
        ),
        SizedBox(height: 2.h),
        _PowerUpShopItem(
          icon: Icons.auto_fix_high,
          name: 'Auto-Sort',
          description: 'Automatically solve next sequence',
          cost: PowerUpService.autoSortCost,
          owned: _powerUpService.getAutoSortCount(),
          currentCoins: widget.currentCoins,
          onPurchase: () => _purchaseWithCoins(PowerUpService.autoSortCost, 'autosort'),
        ),
        SizedBox(height: 2.h),
        _PowerUpShopItem(
          icon: Icons.add_circle,
          name: 'Extra Moves',
          description: 'Add 5 moves to current level',
          cost: PowerUpService.extraMovesCost,
          owned: _powerUpService.getExtraMovesCount(),
          currentCoins: widget.currentCoins,
          onPurchase: () => _purchaseWithCoins(PowerUpService.extraMovesCost, 'extramoves'),
        ),
      ],
    );
  }

  Widget _buildBundlesTab() {
    final bundles = PowerUpService.getBundles();

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: bundles.length,
      itemBuilder: (context, index) {
        final bundle = bundles[index];
        return _BundleShopItem(
          bundle: bundle,
          onPurchase: () => _purchaseBundle(bundle),
        );
      },
    );
  }

  Future<void> _purchaseWithCoins(int cost, String powerUpType) async {
    if (widget.currentCoins < cost) {
      _showInsufficientCoinsDialog();
      return;
    }

    await _animator.buttonPress();

    // Notify parent to deduct coins
    widget.onPurchaseWithCoins?.call(cost);

    // Add power-up
    switch (powerUpType) {
      case 'undo':
        await _powerUpService.addUndo(1);
        break;
      case 'hint':
        await _powerUpService.addHint(1);
        break;
      case 'shuffle':
        await _powerUpService.addShuffle(1);
        break;
      case 'autosort':
        await _powerUpService.addAutoSort(1);
        break;
      case 'extramoves':
        await _powerUpService.addExtraMoves(1);
        break;
    }

    setState(() {}); // Refresh UI

    AnalyticsLogger.logEvent('powerup_purchased_with_coins', parameters: {
      'type': powerUpType,
      'cost': cost,
    });

    _showPurchaseSuccessDialog();
  }

  Future<void> _purchaseBundle(PowerUpBundle bundle) async {
    await _animator.buttonPress();

    // TODO: Trigger IAP purchase flow
    // await InAppPurchaseService.instance.purchaseProduct(bundle.id);

    widget.onPurchaseWithMoney?.call(bundle);

    AnalyticsLogger.logEvent('powerup_bundle_purchase_initiated', parameters: {
      'bundle_id': bundle.id,
      'price': bundle.price,
    });
  }

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Enough Coins'),
        content: const Text(
          'You don\'t have enough coins to purchase this power-up. '
          'Complete more levels or purchase coin packs to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Successful!'),
        content: const Text('Power-up added to your inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Individual power-up shop item
class _PowerUpShopItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final int cost;
  final int owned;
  final int currentCoins;
  final VoidCallback onPurchase;

  const _PowerUpShopItem({
    required this.icon,
    required this.name,
    required this.description,
    required this.cost,
    required this.owned,
    required this.currentCoins,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = currentCoins >= cost;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Icon(icon, size: 6.w, color: AppTheme.lightTheme.primaryColor),
          ),

          SizedBox(width: 3.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        'Owned: $owned',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 3.w),

          // Purchase button
          ElevatedButton(
            onPressed: canAfford ? onPurchase : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              disabledBackgroundColor: Colors.grey[300],
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, size: 4.w, color: Colors.white),
                SizedBox(width: 1.w),
                Text(
                  '$cost',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bundle shop item
class _BundleShopItem extends StatelessWidget {
  final PowerUpBundle bundle;
  final VoidCallback onPurchase;

  const _BundleShopItem({
    required this.bundle,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: Colors.purple.shade200, width: 2),
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
                  color: Colors.purple.shade900,
                ),
              ),
              if (bundle.savings > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    'SAVE ${bundle.savings}%',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 1.h),

          Text(
            bundle.description,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
          ),

          SizedBox(height: 2.h),

          // Items included
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: bundle.items.entries.map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  '${entry.value}× ${_getPowerUpName(entry.key)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[800],
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 2.h),

          // Purchase button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              child: Text(
                'Purchase for \$${bundle.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPowerUpName(String type) {
    switch (type) {
      case 'undo':
        return 'Undo';
      case 'hint':
        return 'Hint';
      case 'shuffle':
        return 'Shuffle';
      case 'autosort':
        return 'Auto-Sort';
      case 'extramoves':
        return 'Extra Moves';
      default:
        return type;
    }
  }
}
