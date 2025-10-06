import 'package:flutter/material.dart';

/// Lightweight model describing an item in the gameplay central pile.
class SortItem {
  const SortItem({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    required this.sortValue,
    this.onTap,
  });

  /// Unique identifier for the item.
  final String id;

  /// Display name shown to the player.
  final String name;

  /// Icon registered in [CustomIconWidget]'s icon map.
  final String iconName;

  /// Color used when rendering the icon.
  final Color color;

  /// Value used for sorting or scoring feedback.
  final int sortValue;

  /// Optional tap handler for responding to item interactions.
  final VoidCallback? onTap;
}
