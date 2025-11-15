import 'package:flutter/material.dart';
import 'package:sortbliss/core/monetization/monetization_manager.dart';
import 'package:sortbliss/core/analytics/analytics_logger.dart';

/// Complete storefront implementation connected to MonetizationManager
/// CRITICAL FOR: ARPU validation, IAP revenue demonstration
class CompleteStorefrontScreen extends StatefulWidget {
  const CompleteStorefrontScreen({super.key});

  @override
  State<CompleteStorefrontScreen> createState() => _CompleteStorefrontScreenState();
}

class _CompleteStorefrontScreenState extends State<CompleteStorefrontScreen> {
  late MonetizationManager _monetization;
  bool _isLoading = false;
  String? _purchaseInProgress;

  @override
  void initState() {
    super.initState();
    _monetization = MonetizationManager.instance;
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    setState(() {
      _isLoading = true;
    });

    await _monetization.initialize();

    setState(() {
      _isLoading = false;
    });

    // Track storefront view
    AnalyticsLogger.logEvent('storefront_viewed', parameters: {
      'products_available': _monetization.products.length,
      'is_available': _monetization.isAvailable,
    });
  }

  Future<void> _purchaseProduct(String productId) async {
    setState(() {
      _purchaseInProgress = productId;
    });

    try {
      await _monetization.buyProduct(productId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase initiated! Please complete in the system dialog.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _purchaseInProgress = null;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    await _monetization.restorePurchases();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore Purchases',
            onPressed: _isLoading ? null : _restorePurchases,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_monetization.isAvailable
                ? _buildUnavailableState()
                : _buildProductList(),
      ),
    );
  }

  Widget _buildUnavailableState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'Store not available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Purchases are not available on this device. Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with coin balance
        _buildCoinBalance(),
        const SizedBox(height: 24),

        // Remove Ads (Premium)
        _buildProductCard(
          productId: MonetizationProducts.removeAds,
          title: 'Remove Ads',
          description: 'Enjoy uninterrupted gameplay with no advertisements',
          icon: Icons.block,
          color: Colors.purple,
          isPremium: true,
        ),

        const SizedBox(height: 16),

        // Sort Pass (Subscription)
        _buildProductCard(
          productId: MonetizationProducts.sortPass,
          title: 'Sort Pass Premium',
          description: 'Unlimited hints, exclusive levels, and premium rewards',
          icon: Icons.workspace_premium,
          color: Colors.amber,
          isPremium: true,
          isSubscription: true,
        ),

        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 8),

        // Section header: Coin Packs
        const Text(
          'Coin Packs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Coin Pack Small
        _buildProductCard(
          productId: MonetizationProducts.coinPackSmall,
          title: 'Small Coin Pack',
          description: '250 coins - Perfect for a few hints',
          icon: Icons.monetization_on,
          color: Colors.green,
          coinAmount: 250,
        ),

        const SizedBox(height: 12),

        // Coin Pack Large
        _buildProductCard(
          productId: MonetizationProducts.coinPackLarge,
          title: 'Large Coin Pack',
          description: '750 coins - Best value!',
          icon: Icons.monetization_on,
          color: Colors.blue,
          coinAmount: 750,
          isBestValue: true,
        ),

        const SizedBox(height: 12),

        // Coin Pack Epic
        _buildProductCard(
          productId: MonetizationProducts.coinPackEpic,
          title: 'Epic Coin Pack',
          description: '2000 coins - For serious players',
          icon: Icons.diamond,
          color: Colors.orange,
          coinAmount: 2000,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCoinBalance() {
    return ListenableBuilder(
      listenable: _monetization.coinBalance,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade700,
                Colors.orange.shade700,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Coins',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_monetization.coinBalance.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard({
    required String productId,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool isPremium = false,
    bool isSubscription = false,
    bool isBestValue = false,
    int? coinAmount,
  }) {
    final product = _monetization.productForId(productId);
    final isOwned = (productId == MonetizationProducts.removeAds && _monetization.isAdFree) ||
                    (productId == MonetizationProducts.sortPass && _monetization.hasSortPass);
    final isPurchasing = _purchaseInProgress == productId;

    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isBestValue ? Colors.amber : Colors.white.withOpacity(0.2),
          width: isBestValue ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Best value badge
          if (isBestValue)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          if (coinAmount != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$coinAmount coins',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isOwned || isPurchasing
                        ? null
                        : () => _purchaseProduct(productId),
                    style: FilledButton.styleFrom(
                      backgroundColor: isOwned ? Colors.grey : color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isPurchasing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isOwned
                                ? 'Owned'
                                : product != null
                                    ? '${product.price}${isSubscription ? '/month' : ''}'
                                    : 'Purchase',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
