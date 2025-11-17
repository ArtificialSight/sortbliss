import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/analytics_logger.dart';

/// A/B Testing framework for running experiments
///
/// Features:
/// - Multiple concurrent experiments
/// - Variant assignment with consistent hashing
/// - Analytics integration
/// - Experiment activation/deactivation
/// - Traffic allocation control
/// - Local persistence of assignments
///
/// Usage:
/// ```dart
/// // Define experiment
/// final experiment = Experiment(
///   id: 'onboarding_v2',
///   variants: ['control', 'variant_a', 'variant_b'],
///   trafficAllocation: 1.0, // 100% of users
/// );
///
/// // Register and get variant
/// await ABTestingService.instance.registerExperiment(experiment);
/// final variant = ABTestingService.instance.getVariant('onboarding_v2');
///
/// // Track conversion
/// await ABTestingService.instance.trackConversion('onboarding_v2', 'completed');
/// ```
class ABTestingService {
  static final ABTestingService instance = ABTestingService._();
  ABTestingService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  final Map<String, Experiment> _experiments = {};
  final Map<String, String> _assignments = {}; // experimentId -> variant
  final Map<String, ExperimentMetrics> _metrics = {};

  static const String _keyAssignments = 'ab_test_assignments';
  static const String _keyMetrics = 'ab_test_metrics';
  static const String _keyUserId = 'ab_test_user_id';

  String? _userId;

  /// Initialize A/B testing service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Get or create user ID for consistent assignment
    _userId = _prefs?.getString(_keyUserId);
    if (_userId == null) {
      _userId = _generateUserId();
      await _prefs?.setString(_keyUserId, _userId!);
    }

    // Load saved assignments
    await _loadAssignments();

    // Load metrics
    await _loadMetrics();

    _initialized = true;

    debugPrint('✅ A/B Testing Service initialized (userId: $_userId)');
  }

  /// Register an experiment
  Future<void> registerExperiment(Experiment experiment) async {
    if (!_initialized) await initialize();

    _experiments[experiment.id] = experiment;

    // Assign variant if not already assigned
    if (!_assignments.containsKey(experiment.id)) {
      final variant = _assignVariant(experiment);
      _assignments[experiment.id] = variant;
      await _saveAssignments();

      // Initialize metrics for this experiment
      _metrics[experiment.id] = ExperimentMetrics(experimentId: experiment.id);
      await _saveMetrics();

      // Log assignment
      AnalyticsLogger.logEvent(
        'ab_test_assigned',
        parameters: {
          'experiment_id': experiment.id,
          'variant': variant,
          'traffic_allocation': experiment.trafficAllocation,
        },
      );

      debugPrint(
          '🧪 A/B Test: ${experiment.id} -> $variant (${experiment.variants.length} variants)');
    }
  }

  /// Get variant for an experiment
  String? getVariant(String experimentId) {
    return _assignments[experimentId];
  }

  /// Check if user is in experiment
  bool isInExperiment(String experimentId) {
    return _assignments.containsKey(experimentId);
  }

  /// Check if user is in specific variant
  bool isInVariant(String experimentId, String variant) {
    return _assignments[experimentId] == variant;
  }

  /// Track an event for an experiment
  Future<void> trackEvent(
    String experimentId,
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    final variant = _assignments[experimentId];
    if (variant == null) return;

    // Update metrics
    final metrics = _metrics[experimentId];
    if (metrics != null) {
      metrics.incrementEvent(variant, eventName);
      await _saveMetrics();
    }

    // Log to analytics
    AnalyticsLogger.logEvent(
      'ab_test_event',
      parameters: {
        'experiment_id': experimentId,
        'variant': variant,
        'event_name': eventName,
        ...?parameters,
      },
    );
  }

  /// Track conversion for an experiment
  Future<void> trackConversion(
    String experimentId,
    String conversionType, {
    double? value,
  }) async {
    final variant = _assignments[experimentId];
    if (variant == null) return;

    // Update metrics
    final metrics = _metrics[experimentId];
    if (metrics != null) {
      metrics.incrementConversion(variant, conversionType, value: value);
      await _saveMetrics();
    }

    // Log to analytics
    AnalyticsLogger.logEvent(
      'ab_test_conversion',
      parameters: {
        'experiment_id': experimentId,
        'variant': variant,
        'conversion_type': conversionType,
        if (value != null) 'value': value,
      },
    );

    debugPrint(
        '🎯 A/B Test Conversion: $experimentId ($variant) -> $conversionType${value != null ? ' (\$$value)' : ''}');
  }

  /// Get experiment metrics
  ExperimentMetrics? getMetrics(String experimentId) {
    return _metrics[experimentId];
  }

  /// Get all experiments
  Map<String, Experiment> getAllExperiments() {
    return Map.unmodifiable(_experiments);
  }

  /// Get all assignments
  Map<String, String> getAllAssignments() {
    return Map.unmodifiable(_assignments);
  }

  /// Reset experiment (for testing only)
  Future<void> resetExperiment(String experimentId) async {
    _assignments.remove(experimentId);
    _metrics.remove(experimentId);
    await _saveAssignments();
    await _saveMetrics();

    debugPrint('🔄 A/B Test reset: $experimentId');
  }

  /// Clear all experiments (for testing only)
  Future<void> clearAll() async {
    _experiments.clear();
    _assignments.clear();
    _metrics.clear();
    await _prefs?.remove(_keyAssignments);
    await _prefs?.remove(_keyMetrics);

    debugPrint('🗑️  A/B Tests cleared');
  }

  /// Assign variant to user
  String _assignVariant(Experiment experiment) {
    // Check if user should be in experiment based on traffic allocation
    final random = Random(_userId.hashCode);
    final randomValue = random.nextDouble();

    if (randomValue > experiment.trafficAllocation) {
      // User not in experiment, assign control
      return experiment.variants.first;
    }

    // Hash user ID to get consistent variant assignment
    final variantHash = _hashString('${experiment.id}_$_userId');
    final variantIndex = variantHash % experiment.variants.length;

    return experiment.variants[variantIndex];
  }

  /// Generate unique user ID
  String _generateUserId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return '${timestamp}_$randomPart';
  }

  /// Hash string to integer
  int _hashString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs();
  }

  /// Load assignments from storage
  Future<void> _loadAssignments() async {
    final assignmentsJson = _prefs?.getString(_keyAssignments);
    if (assignmentsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(assignmentsJson);
        _assignments.addAll(decoded.cast<String, String>());
      } catch (e) {
        debugPrint('❌ Error loading A/B test assignments: $e');
      }
    }
  }

  /// Save assignments to storage
  Future<void> _saveAssignments() async {
    final assignmentsJson = jsonEncode(_assignments);
    await _prefs?.setString(_keyAssignments, assignmentsJson);
  }

  /// Load metrics from storage
  Future<void> _loadMetrics() async {
    final metricsJson = _prefs?.getString(_keyMetrics);
    if (metricsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(metricsJson);
        for (final entry in decoded.entries) {
          _metrics[entry.key] =
              ExperimentMetrics.fromJson(entry.value as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('❌ Error loading A/B test metrics: $e');
      }
    }
  }

  /// Save metrics to storage
  Future<void> _saveMetrics() async {
    final metricsMap = <String, dynamic>{};
    for (final entry in _metrics.entries) {
      metricsMap[entry.key] = entry.value.toJson();
    }
    final metricsJson = jsonEncode(metricsMap);
    await _prefs?.setString(_keyMetrics, metricsJson);
  }
}

/// Experiment definition
class Experiment {
  final String id;
  final String name;
  final String description;
  final List<String> variants;
  final double trafficAllocation; // 0.0 to 1.0
  final DateTime? startDate;
  final DateTime? endDate;

  Experiment({
    required this.id,
    String? name,
    String? description,
    required this.variants,
    this.trafficAllocation = 1.0,
    this.startDate,
    this.endDate,
  })  : name = name ?? id,
        description = description ?? '',
        assert(variants.isNotEmpty, 'Must have at least one variant'),
        assert(trafficAllocation >= 0.0 && trafficAllocation <= 1.0);

  bool get isActive {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}

/// Experiment metrics tracking
class ExperimentMetrics {
  final String experimentId;
  final Map<String, VariantMetrics> variantMetrics = {};

  ExperimentMetrics({required this.experimentId});

  void incrementEvent(String variant, String eventName) {
    _getOrCreateVariantMetrics(variant).incrementEvent(eventName);
  }

  void incrementConversion(String variant, String conversionType,
      {double? value}) {
    _getOrCreateVariantMetrics(variant)
        .incrementConversion(conversionType, value: value);
  }

  VariantMetrics _getOrCreateVariantMetrics(String variant) {
    return variantMetrics.putIfAbsent(
      variant,
      () => VariantMetrics(variant: variant),
    );
  }

  factory ExperimentMetrics.fromJson(Map<String, dynamic> json) {
    final metrics = ExperimentMetrics(
      experimentId: json['experimentId'] as String,
    );

    final variantsJson = json['variants'] as Map<String, dynamic>? ?? {};
    for (final entry in variantsJson.entries) {
      metrics.variantMetrics[entry.key] =
          VariantMetrics.fromJson(entry.value as Map<String, dynamic>);
    }

    return metrics;
  }

  Map<String, dynamic> toJson() {
    return {
      'experimentId': experimentId,
      'variants': variantMetrics.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Experiment: $experimentId');
    for (final entry in variantMetrics.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }
}

/// Metrics for a specific variant
class VariantMetrics {
  final String variant;
  int impressions = 0;
  final Map<String, int> events = {};
  final Map<String, ConversionMetrics> conversions = {};

  VariantMetrics({required this.variant});

  void incrementEvent(String eventName) {
    impressions++;
    events[eventName] = (events[eventName] ?? 0) + 1;
  }

  void incrementConversion(String conversionType, {double? value}) {
    final metrics = conversions.putIfAbsent(
      conversionType,
      () => ConversionMetrics(),
    );
    metrics.count++;
    if (value != null) {
      metrics.totalValue += value;
    }
  }

  double getConversionRate(String conversionType) {
    if (impressions == 0) return 0.0;
    final count = conversions[conversionType]?.count ?? 0;
    return count / impressions;
  }

  factory VariantMetrics.fromJson(Map<String, dynamic> json) {
    final metrics = VariantMetrics(variant: json['variant'] as String);
    metrics.impressions = json['impressions'] as int? ?? 0;

    final eventsJson = json['events'] as Map<String, dynamic>? ?? {};
    for (final entry in eventsJson.entries) {
      metrics.events[entry.key] = entry.value as int;
    }

    final conversionsJson = json['conversions'] as Map<String, dynamic>? ?? {};
    for (final entry in conversionsJson.entries) {
      metrics.conversions[entry.key] =
          ConversionMetrics.fromJson(entry.value as Map<String, dynamic>);
    }

    return metrics;
  }

  Map<String, dynamic> toJson() {
    return {
      'variant': variant,
      'impressions': impressions,
      'events': events,
      'conversions': conversions.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  @override
  String toString() {
    return 'impressions: $impressions, conversions: ${conversions.length}';
  }
}

/// Conversion metrics
class ConversionMetrics {
  int count = 0;
  double totalValue = 0.0;

  ConversionMetrics();

  double get averageValue => count > 0 ? totalValue / count : 0.0;

  factory ConversionMetrics.fromJson(Map<String, dynamic> json) {
    final metrics = ConversionMetrics();
    metrics.count = json['count'] as int? ?? 0;
    metrics.totalValue = (json['totalValue'] as num?)?.toDouble() ?? 0.0;
    return metrics;
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'totalValue': totalValue,
    };
  }
}

/// Predefined experiments for SortBliss
class SortBlissExperiments {
  /// Onboarding flow experiment
  static Experiment get onboardingFlow => Experiment(
        id: 'onboarding_v2',
        name: 'Onboarding Flow V2',
        description: 'Test new onboarding flow with interactive tutorial',
        variants: ['control', 'variant_a'],
        trafficAllocation: 0.5, // 50% of users
      );

  /// Level difficulty experiment
  static Experiment get levelDifficulty => Experiment(
        id: 'level_difficulty',
        name: 'Level Difficulty Curve',
        description: 'Test different difficulty progressions',
        variants: ['standard', 'easier', 'harder'],
        trafficAllocation: 1.0,
      );

  /// Power-up pricing experiment
  static Experiment get powerUpPricing => Experiment(
        id: 'powerup_pricing',
        name: 'Power-Up Pricing',
        description: 'Test different power-up prices',
        variants: ['control', 'lower', 'higher'],
        trafficAllocation: 1.0,
      );

  /// Reward frequency experiment
  static Experiment get rewardFrequency => Experiment(
        id: 'reward_frequency',
        name: 'Reward Frequency',
        description: 'Test different reward schedules',
        variants: ['standard', 'frequent', 'milestone'],
        trafficAllocation: 1.0,
      );

  /// UI theme experiment
  static Experiment get uiTheme => Experiment(
        id: 'ui_theme',
        name: 'UI Theme',
        description: 'Test different color schemes',
        variants: ['default', 'vibrant', 'pastel'],
        trafficAllocation: 0.3, // 30% of users
      );

  /// Get all predefined experiments
  static List<Experiment> get all => [
        onboardingFlow,
        levelDifficulty,
        powerUpPricing,
        rewardFrequency,
        uiTheme,
      ];
}
