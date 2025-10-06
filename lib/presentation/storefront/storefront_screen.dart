import 'package:flutter/material.dart';

/// Displays available premium content and purchase options for SortBliss.
class StorefrontScreen extends StatelessWidget {
  const StorefrontScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storefront'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock premium audio sets and seasonal themes to personalize your experience.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: const [
                    _StorefrontTile(
                      icon: Icons.music_note,
                      title: 'Ambient soundscapes',
                      subtitle:
                          'Immerse yourself with adaptive audio tailored to each puzzle mood.',
                    ),
                    _StorefrontTile(
                      icon: Icons.color_lens,
                      title: 'Seasonal themes',
                      subtitle:
                          'Refresh SortBliss with limited-time palettes inspired by the calendar.',
                    ),
                    _StorefrontTile(
                      icon: Icons.bolt,
                      title: 'Productivity boosts',
                      subtitle:
                          'Reduce cooldown timers and access expert-ranked puzzle variants.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchases are not yet available.'),
                      ),
                    );
                  },
                  child: const Text('Coming soon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
