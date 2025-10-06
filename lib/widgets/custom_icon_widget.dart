import 'package:flutter/material.dart';

/// A lightweight wrapper around [Icon] that resolves icons from a curated
/// lookup table using human-readable string identifiers.
class CustomIconWidget extends StatelessWidget {
  static const Map<String, IconData> _iconLookup = {
    'arrow_forward': Icons.arrow_forward,
    'bolt': Icons.bolt,
    'check_circle': Icons.check_circle,
    'chevron_right': Icons.chevron_right,
    'emoji_events': Icons.emoji_events,
    'hourglass_empty': Icons.hourglass_empty,
    'inbox': Icons.inbox,
    'lightbulb_outline': Icons.lightbulb_outline,
    'local_fire_department': Icons.local_fire_department,
    'lock': Icons.lock,
    'monetization_on': Icons.monetization_on,
    'pause': Icons.pause,
    'play_arrow': Icons.play_arrow,
    'play_circle_filled': Icons.play_circle_filled,
    'refresh': Icons.refresh,
    'replay': Icons.replay,
    'share': Icons.share,
    'shop': Icons.shop,
    'sort': Icons.sort,
    'star': Icons.star,
    'star_border': Icons.star_border,
    'timer': Icons.timer,
    'today': Icons.today,
    'touch_app': Icons.touch_app,
    'trophy': Icons.emoji_events,
    // Aliases
    'play_circle_fill': Icons.play_circle_filled,
  };

  final String iconName;
  final double size;
  final Color? color;

  const CustomIconWidget({
    Key? key,
    required this.iconName,
    this.size = 24,
    this.color,
  }) : super(key: key);

  static IconData _resolveIcon(String name) {
    final normalizedName = name.trim();
    return _iconLookup[normalizedName] ?? Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _resolveIcon(iconName);

    return Icon(
      iconData,
      size: size,
      color: color ?? Theme.of(context).iconTheme.color,
      semanticLabel: iconName,
    );
  }
}
