import 'dart:math' as math;

/// Data class for realistic 3D game items following hypercasual trends
class GameItemsData {
  GameItemsData._();

  // Item categories inspired by trending hypercasual games
  static const Map<String, List<Map<String, dynamic>>> itemCategories = {
    "food": [
      {
        "name": "Apple",
        "emoji": "🍎",
        "color": 0xFFE53E3E,
        "category": "fruit",
        "description": "Fresh red apple"
      },
      {
        "name": "Banana",
        "emoji": "🍌",
        "color": 0xFFD69E2E,
        "category": "fruit",
        "description": "Ripe yellow banana"
      },
      {
        "name": "Pizza",
        "emoji": "🍕",
        "color": 0xFFE53E3E,
        "category": "meal",
        "description": "Delicious pizza slice"
      },
      {
        "name": "Burger",
        "emoji": "🍔",
        "color": 0xFF8B4513,
        "category": "meal",
        "description": "Tasty burger"
      },
      {
        "name": "Donut",
        "emoji": "🍩",
        "color": 0xFFD2691E,
        "category": "dessert",
        "description": "Sweet glazed donut"
      },
      {
        "name": "Ice Cream",
        "emoji": "🍦",
        "color": 0xFF8B5CF6,
        "category": "dessert",
        "description": "Cool ice cream cone"
      },
      {
        "name": "Cookie",
        "emoji": "🍪",
        "color": 0xFFCD853F,
        "category": "dessert",
        "description": "Chocolate chip cookie"
      },
      {
        "name": "Orange",
        "emoji": "🍊",
        "color": 0xFFFF8C00,
        "category": "fruit",
        "description": "Juicy orange"
      }
    ],
    "toys": [
      {
        "name": "Teddy Bear",
        "emoji": "🧸",
        "color": 0xFF8B4513,
        "category": "plush",
        "description": "Cute teddy bear"
      },
      {
        "name": "Ball",
        "emoji": "⚽",
        "color": 0xFF000000,
        "category": "sport",
        "description": "Soccer ball"
      },
      {
        "name": "Car",
        "emoji": "🚗",
        "color": 0xFF3182CE,
        "category": "vehicle",
        "description": "Toy car"
      },
      {
        "name": "Robot",
        "emoji": "🤖",
        "color": 0xFF718096,
        "category": "tech",
        "description": "Cool robot toy"
      },
      {
        "name": "Puzzle",
        "emoji": "🧩",
        "color": 0xFF38A169,
        "category": "brain",
        "description": "Jigsaw puzzle piece"
      },
      {
        "name": "Kite",
        "emoji": "🪁",
        "color": 0xFFE53E3E,
        "category": "outdoor",
        "description": "Flying kite"
      },
      {
        "name": "Yo-yo",
        "emoji": "🪀",
        "color": 0xFF8B5CF6,
        "category": "classic",
        "description": "Classic yo-yo"
      },
      {
        "name": "Drum",
        "emoji": "🥁",
        "color": 0xFF8B4513,
        "category": "music",
        "description": "Musical drum"
      }
    ],
    "home": [
      {
        "name": "Chair",
        "emoji": "🪑",
        "color": 0xFF8B4513,
        "category": "furniture",
        "description": "Comfortable chair"
      },
      {
        "name": "Lamp",
        "emoji": "💡",
        "color": 0xFFD69E2E,
        "category": "lighting",
        "description": "Bright lamp"
      },
      {
        "name": "Plant",
        "emoji": "🪴",
        "color": 0xFF38A169,
        "category": "decor",
        "description": "Green houseplant"
      },
      {
        "name": "Book",
        "emoji": "📚",
        "color": 0xFF3182CE,
        "category": "reading",
        "description": "Stack of books"
      },
      {
        "name": "Clock",
        "emoji": "⏰",
        "color": 0xFF718096,
        "category": "time",
        "description": "Alarm clock"
      },
      {
        "name": "Pillow",
        "emoji": "🛏️",
        "color": 0xFF8B5CF6,
        "category": "comfort",
        "description": "Soft pillow"
      },
      {
        "name": "Candle",
        "emoji": "🕯️",
        "color": 0xFFF59E0B,
        "category": "ambiance",
        "description": "Scented candle"
      },
      {
        "name": "Vase",
        "emoji": "🏺",
        "color": 0xFF8B4513,
        "category": "decor",
        "description": "Decorative vase"
      }
    ],
    "animals": [
      {
        "name": "Cat",
        "emoji": "🐱",
        "color": 0xFF8B4513,
        "category": "pet",
        "description": "Cute cat"
      },
      {
        "name": "Dog",
        "emoji": "🐶",
        "color": 0xFFD2691E,
        "category": "pet",
        "description": "Loyal dog"
      },
      {
        "name": "Fish",
        "emoji": "🐠",
        "color": 0xFF3182CE,
        "category": "aquatic",
        "description": "Tropical fish"
      },
      {
        "name": "Bird",
        "emoji": "🐦",
        "color": 0xFFD69E2E,
        "category": "flying",
        "description": "Little bird"
      },
      {
        "name": "Butterfly",
        "emoji": "🦋",
        "color": 0xFF8B5CF6,
        "category": "insect",
        "description": "Beautiful butterfly"
      },
      {
        "name": "Rabbit",
        "emoji": "🐰",
        "color": 0xFFE5E5E5,
        "category": "small",
        "description": "Fluffy rabbit"
      },
      {
        "name": "Panda",
        "emoji": "🐼",
        "color": 0xFF000000,
        "category": "exotic",
        "description": "Adorable panda"
      },
      {
        "name": "Frog",
        "emoji": "🐸",
        "color": 0xFF38A169,
        "category": "amphibian",
        "description": "Green frog"
      }
    ]
  };

  // Container configurations for different item types
  static const Map<String, Map<String, dynamic>> containerConfigs = {
    "food": {
      "name": "Kitchen",
      "emoji": "🍽️",
      "color": 0xFFE53E3E,
      "gradient": [0xFFE53E3E, 0xFFFF6B6B],
      "description": "Sort food items here"
    },
    "toys": {
      "name": "Toy Box",
      "emoji": "🎲",
      "color": 0xFF3182CE,
      "gradient": [0xFF3182CE, 0xFF4299E1],
      "description": "Sort toys here"
    },
    "home": {
      "name": "Living Room",
      "emoji": "🏠",
      "color": 0xFF38A169,
      "gradient": [0xFF38A169, 0xFF48BB78],
      "description": "Sort home items here"
    },
    "animals": {
      "name": "Pet Zone",
      "emoji": "🐾",
      "color": 0xFFD69E2E,
      "gradient": [0xFFD69E2E, 0xFFF6E05E],
      "description": "Sort animals here"
    }
  };

  /// Generate diverse items for a specific level
  static List<Map<String, dynamic>> generateLevelItems(int level) {
    try {
      final random = math.Random(DateTime.now().millisecondsSinceEpoch + level);
      final List<Map<String, dynamic>> levelItems = [];

      // Calculate item count based on level (8-20 items)
      int itemCount = (8 + (level * 1.5)).clamp(8, 20).toInt();

      // Ensure variety by selecting from different categories
      final categories = itemCategories.keys.toList()..shuffle(random);
      final itemsPerCategory = (itemCount / categories.length).ceil();

      for (String category in categories) {
        final categoryItems = itemCategories[category]!;
        final shuffledItems = List<Map<String, dynamic>>.from(categoryItems)
          ..shuffle(random);

        // Add 2-5 items from each category
        final countForCategory = math.min(
            itemsPerCategory + random.nextInt(2), shuffledItems.length);

        for (int i = 0;
            i < countForCategory && levelItems.length < itemCount;
            i++) {
          final item = Map<String, dynamic>.from(shuffledItems[i]);
          item["id"] = "level${level}_${category}_${item['name']}_${i}";
          item["targetContainer"] = category;
          item["level"] = level;
          item["rotation"] =
              random.nextDouble() * 360; // Random rotation for 3D effect
          item["scale"] =
              0.8 + (random.nextDouble() * 0.4); // Slight size variation
          item["shadowIntensity"] = 0.3 + (random.nextDouble() * 0.4);
          levelItems.add(item);
        }
      }

      // Fallback: Ensure minimum item count
      if (levelItems.length < 8) {
        _addFallbackItems(levelItems, level, 8 - levelItems.length);
      }

      // Shuffle final list for randomness
      levelItems.shuffle(random);

      return levelItems;
    } catch (e) {
      print('Error generating level items: $e');
      return _generateFallbackItems(level);
    }
  }

  /// Generate fallback items if procedural generation fails
  static List<Map<String, dynamic>> _generateFallbackItems(int level) {
    final List<Map<String, dynamic>> fallbackItems = [];
    const basicItems = [
      {"name": "Apple", "emoji": "🍎", "color": 0xFFE53E3E, "category": "food"},
      {"name": "Ball", "emoji": "⚽", "color": 0xFF000000, "category": "toys"},
      {"name": "Chair", "emoji": "🪑", "color": 0xFF8B4513, "category": "home"},
      {
        "name": "Cat",
        "emoji": "🐱",
        "color": 0xFF8B4513,
        "category": "animals"
      },
      {"name": "Pizza", "emoji": "🍕", "color": 0xFFE53E3E, "category": "food"},
      {"name": "Car", "emoji": "🚗", "color": 0xFF3182CE, "category": "toys"},
      {"name": "Plant", "emoji": "🪴", "color": 0xFF38A169, "category": "home"},
      {
        "name": "Dog",
        "emoji": "🐶",
        "color": 0xFFD2691E,
        "category": "animals"
      },
    ];

    for (int i = 0; i < basicItems.length; i++) {
      final item = Map<String, dynamic>.from(basicItems[i]);
      item["id"] = "fallback_level${level}_${item['name']}_$i";
      item["targetContainer"] = item["category"];
      item["level"] = level;
      item["rotation"] = (i * 45.0) % 360;
      item["scale"] = 1.0;
      item["shadowIntensity"] = 0.5;
      item["description"] = "Fallback ${item['name']}";
      fallbackItems.add(item);
    }

    return fallbackItems;
  }

  /// Add additional fallback items to reach minimum count
  static void _addFallbackItems(
      List<Map<String, dynamic>> existingItems, int level, int countNeeded) {
    final random = math.Random();
    final allItems = <Map<String, dynamic>>[];

    itemCategories.forEach((category, items) {
      for (var item in items) {
        final enhancedItem = Map<String, dynamic>.from(item);
        enhancedItem["targetContainer"] = category;
        allItems.add(enhancedItem);
      }
    });

    allItems.shuffle(random);

    for (int i = 0; i < countNeeded && i < allItems.length; i++) {
      final item = Map<String, dynamic>.from(allItems[i]);
      item["id"] =
          "fallback_level${level}_${item['name']}_${existingItems.length + i}";
      item["level"] = level;
      item["rotation"] = random.nextDouble() * 360;
      item["scale"] = 0.8 + (random.nextDouble() * 0.4);
      item["shadowIntensity"] = 0.3 + (random.nextDouble() * 0.4);
      existingItems.add(item);
    }
  }

  /// Get container configuration for a category
  static Map<String, dynamic> getContainerConfig(String category) {
    return containerConfigs[category] ??
        {
          "name": "Mixed",
          "emoji": "📦",
          "color": 0xFF718096,
          "gradient": [0xFF718096, 0xFFA0AEC0],
          "description": "Sort items here"
        };
  }

  /// Get all available categories
  static List<String> getAllCategories() {
    return itemCategories.keys.toList();
  }

  /// Get random items from a specific category
  static List<Map<String, dynamic>> getItemsByCategory(
      String category, int count) {
    final categoryItems = itemCategories[category] ?? [];
    if (categoryItems.isEmpty) return [];

    final random = math.Random();
    final shuffledItems = List<Map<String, dynamic>>.from(categoryItems)
      ..shuffle(random);

    return shuffledItems.take(count).toList();
  }

  /// Check if an item belongs to a category
  static bool itemBelongsToCategory(
      Map<String, dynamic> item, String category) {
    return item["targetContainer"] == category;
  }

  /// Get 3D visual properties for enhanced rendering
  static Map<String, dynamic> get3DVisualProperties(Map<String, dynamic> item) {
    final random = math.Random(item["id"].hashCode);

    return {
      "rotation": item["rotation"] ?? (random.nextDouble() * 360),
      "scale": item["scale"] ?? (0.8 + (random.nextDouble() * 0.4)),
      "shadowIntensity":
          item["shadowIntensity"] ?? (0.3 + (random.nextDouble() * 0.4)),
      "glowEffect": random.nextBool(),
      "pulseAnimation": random.nextDouble() > 0.7,
      "bounceOnDrag": true,
      "particleTrail": random.nextDouble() > 0.8,
    };
  }
}
