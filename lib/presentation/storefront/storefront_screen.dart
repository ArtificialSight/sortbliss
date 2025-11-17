import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/monetization/monetization_manager.dart';

/// Displays available premium content and purchase options for SortBliss.
class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({super.key});

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  final MonetizationManager _monetizationManager = MonetizationManager.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    await _monetizationManager.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          TextButton.icon(
            onPressed: _restorePurchases,
            icon: const Icon(Icons.restore),
            label: const Text('Restore'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildStoreContent(),
      ),
    );
  }

  Widget _buildStoreContent() {
    if (!_monetizationManager.isAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Store Unavailable',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'In-app purchases are not available on this device. Please try again later.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _monetizationManager,
      builder: (context, _) {
        final products = _monetizationManager.products;

        if (products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Loading products...'),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Coins & Upgrades',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Purchase coins to unlock more content and customize your experience.'),
            const SizedBox(height: 24),
            ...products.entries.map((entry) => _buildProductTile(entry.value)),
          ],
        );
      },
    );
  }

  Widget _buildProductTile(ProductDetails product) {
    final icon = _getProductIcon(product.id);
    final description = _getProductDescription(product.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(product.title.replaceAll(' (SortBliss)', '')),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: () => _purchaseProduct(product),
          child: Text(product.price),
        ),
      ),
    );
  }

  IconData _getProductIcon(String productId) {
    switch (productId) {
      case MonetizationProducts.removeAds:
        return Icons.block;
      case MonetizationProducts.coinPackSmall:
        return Icons.monetization_on;
      case MonetizationProducts.coinPackLarge:
        return Icons.monetization_on_outlined;
      case MonetizationProducts.coinPackEpic:
        return Icons.diamond;
      case MonetizationProducts.sortPass:
        return Icons.stars;
      default:
        return Icons.shopping_bag;
    }
  }

  String _getProductDescription(String productId) {
    switch (productId) {
      case MonetizationProducts.removeAds:
        return 'Remove all interstitial ads';
      case MonetizationProducts.coinPackSmall:
        return 'Get 250 coins';
      case MonetizationProducts.coinPackLarge:
        return 'Get 750 coins';
      case MonetizationProducts.coinPackEpic:
        return 'Get 2,000 coins - Best Value!';
      case MonetizationProducts.sortPass:
        return 'Premium features and exclusive content';
      default:
        return '';
    }
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    try {
      await _monetizationManager.buyProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase initiated...')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _monetizationManager.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchases restored!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: ${e.toString()}')),
      );
    }
  }
}

class _StorefrontTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StorefrontTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
