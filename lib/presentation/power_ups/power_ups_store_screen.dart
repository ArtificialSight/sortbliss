import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/power_ups_service.dart';
import '../../core/monetization/monetization_manager.dart';

/// Power-Ups Store - Purchase and manage consumable boosts
/// CRITICAL FOR: Additional monetization (+$0.15 ARPU), engagement depth
class PowerUpsStoreScreen extends StatefulWidget {
  const PowerUpsStoreScreen({super.key});

  @override
  State<PowerUpsStoreScreen> createState() => _PowerUpsStoreScreenState();
}

class _PowerUpsStoreScreenState extends State<PowerUpsStoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize services if needed
    PowerUpsService.instance.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Power-Ups Store',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Shop', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Inventory', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Coin balance display
          _buildCoinBalanceHeader(),

          // Tab content
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
    );
  }

  Widget _buildCoinBalanceHeader() {
    return ValueListenableBuilder<int>(
      valueListenable: MonetizationManager.instance.coinBalance,
      builder: (context, balance, child) {
        return Container(
          margin: EdgeInsets.all(2.h),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.white, size: 32),
              SizedBox(width: 2.w),
              Text(
                '$balance Coins',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopTab() {
    return AnimatedBuilder(
      animation: PowerUpsService.instance,
      builder: (context, child) {
        return ListView(
          padding: EdgeInsets.all(2.h),
          children: PowerUpsService.catalog.values.map((definition) {
            return _buildPowerUpCard(definition, isShop: true);
          }).toList(),
        );
      },
    );
  }

  Widget _buildInventoryTab() {
    return AnimatedBuilder(
      animation: PowerUpsService.instance,
      builder: (context, child) {
        final inventory = PowerUpsService.instance.inventory;

        if (inventory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(height: 2.h),
                Text(
                  'No Power-Ups Yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Purchase from the Shop tab',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.all(2.h),
          children: inventory.entries.map((entry) {
            final definition = PowerUpsService.catalog[entry.key]!;
            return _buildPowerUpCard(definition, isShop: false);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPowerUpCard(PowerUpDefinition definition, {required bool isShop}) {
    final quantity = PowerUpsService.instance.getQuantity(definition.type);
    final isActive = PowerUpsService.instance.isActive(definition.type);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A),
            const Color(0xFF2A2F4A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.amber : Colors.white.withOpacity(0.1),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? Colors.amber.withOpacity(0.3) : Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getColorForEffect(definition.effect).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      definition.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),

                SizedBox(width: 3.w),

                // Name and duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            definition.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isActive) ...[
                            SizedBox(width: 2.w),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        definition.durationText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price or quantity
                if (isShop)
                  _buildPriceTag(definition.price)
                else
                  _buildQuantityBadge(quantity),
              ],
            ),

            SizedBox(height: 1.5.h),

            // Description
            Text(
              definition.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),

            SizedBox(height: 2.h),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: isShop
                  ? _buildPurchaseButton(definition)
                  : _buildActivateButton(definition),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTag(int price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '$price',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBadge(int quantity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'x$quantity',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(PowerUpDefinition definition) {
    return ValueListenableBuilder<int>(
      valueListenable: MonetizationManager.instance.coinBalance,
      builder: (context, balance, child) {
        final canAfford = balance >= definition.price;

        return ElevatedButton.icon(
          onPressed: canAfford ? () => _handlePurchase(definition) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getColorForEffect(definition.effect),
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: canAfford ? 4 : 0,
          ),
          icon: const Icon(Icons.shopping_cart),
          label: Text(
            canAfford ? 'Buy Now' : 'Insufficient Coins',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivateButton(PowerUpDefinition definition) {
    final quantity = PowerUpsService.instance.getQuantity(definition.type);
    final isActive = PowerUpsService.instance.isActive(definition.type);

    return ElevatedButton.icon(
      onPressed: (!isActive && quantity > 0) ? () => _handleActivate(definition) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getColorForEffect(definition.effect),
        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: (!isActive && quantity > 0) ? 4 : 0,
      ),
      icon: Icon(isActive ? Icons.check_circle : Icons.play_arrow),
      label: Text(
        isActive ? 'Active' : 'Activate',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handlePurchase(PowerUpDefinition definition) async {
    final result = await PowerUpsService.instance.purchase(definition.type);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(result.message),
            ),
          ],
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // If successful, optionally switch to inventory tab
    if (result.success) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _tabController.animateTo(1);
        }
      });
    }
  }

  Future<void> _handleActivate(PowerUpDefinition definition) async {
    final result = await PowerUpsService.instance.activate(definition.type);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(result.message),
            ),
          ],
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // If successful and instant-use, show additional feedback
    if (result.success && definition.duration == null) {
      _showActivationAnimation(definition);
    }
  }

  void _showActivationAnimation(PowerUpDefinition definition) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getColorForEffect(definition.effect),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    definition.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${definition.name} Activated!',
                    style: TextStyle(
                      color: _getColorForEffect(definition.effect),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColorForEffect(PowerUpEffect effect) {
    switch (effect) {
      case PowerUpEffect.timeBonus:
        return Colors.purple;
      case PowerUpEffect.accuracyForgiveness:
        return Colors.blue;
      case PowerUpEffect.comboDouble:
        return Colors.orange;
      case PowerUpEffect.coinBoost:
        return Colors.amber;
      case PowerUpEffect.freeHints:
        return Colors.green;
      case PowerUpEffect.undoLast:
        return Colors.red;
    }
  }
}
