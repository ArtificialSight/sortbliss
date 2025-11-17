import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature tour/coach marks widget for highlighting new features
///
/// Features:
/// - Spotlight on target widget
/// - Customizable tooltip
/// - Sequential steps
/// - Skip option
/// - Progress indicator
/// - Persistent completion tracking
///
/// Usage:
/// ```dart
/// await FeatureTourWidget.show(
///   context: context,
///   steps: [
///     TourStep(
///       targetKey: _achievementsButtonKey,
///       title: 'Achievements',
///       description: 'Track your progress and unlock rewards!',
///     ),
///     TourStep(
///       targetKey: _leaderboardButtonKey,
///       title: 'Leaderboards',
///       description: 'Compete with players worldwide!',
///     ),
///   ],
///   tourId: 'home_features_v1',
/// );
/// ```
class FeatureTourWidget extends StatefulWidget {
  final List<TourStep> steps;
  final String tourId;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const FeatureTourWidget({
    Key? key,
    required this.steps,
    required this.tourId,
    this.onComplete,
    this.onSkip,
  }) : super(key: key);

  /// Show feature tour
  static Future<void> show({
    required BuildContext context,
    required List<TourStep> steps,
    required String tourId,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
  }) async {
    // Check if tour already completed
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('tour_completed_$tourId') ?? false;

    if (completed) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => FeatureTourWidget(
        steps: steps,
        tourId: tourId,
        onComplete: onComplete,
        onSkip: onSkip,
      ),
    );
  }

  @override
  State<FeatureTourWidget> createState() => _FeatureTourWidgetState();
}

class _FeatureTourWidgetState extends State<FeatureTourWidget>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final targetRect = _getTargetRect(step.targetKey);

    if (targetRect == null) {
      // Target not found, skip to next or close
      _nextStep();
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Spotlight overlay
          CustomPaint(
            painter: SpotlightPainter(
              targetRect: targetRect,
              spotlightRadius: step.spotlightRadius,
            ),
            child: Container(),
          ),

          // Tooltip
          _buildTooltip(step, targetRect),

          // Progress and controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildTooltip(TourStep step, Rect targetRect) {
    // Determine tooltip position (above or below target)
    final screenHeight = MediaQuery.of(context).size.height;
    final showAbove = targetRect.bottom > screenHeight * 0.6;

    double tooltipTop;
    if (showAbove) {
      tooltipTop = targetRect.top - 250; // Position above
    } else {
      tooltipTop = targetRect.bottom + 20; // Position below
    }

    return Positioned(
      top: tooltipTop,
      left: 5.w,
      right: 5.w,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon (if provided)
                if (step.icon != null)
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: step.iconColor?.withOpacity(0.1) ??
                          Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Icon(
                      step.icon,
                      color: step.iconColor ?? Colors.blue,
                      size: 8.w,
                    ),
                  ),

                if (step.icon != null) SizedBox(height: 2.h),

                // Title
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),

                SizedBox(height: 1.h),

                // Description
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 3.h),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress indicator
                    Text(
                      '${_currentStep + 1} of ${widget.steps.length}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),

                    // Navigation buttons
                    Row(
                      children: [
                        // Skip button
                        if (_currentStep == 0)
                          TextButton(
                            onPressed: _skip,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),

                        SizedBox(width: 2.w),

                        // Next/Done button
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: step.iconColor ?? Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 1.5.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3.w),
                            ),
                          ),
                          child: Text(
                            _currentStep == widget.steps.length - 1
                                ? 'Done'
                                : 'Next',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 2.h,
      right: 5.w,
      child: IconButton(
        onPressed: _skip,
        icon: Icon(
          Icons.close,
          color: Colors.white,
          size: 7.w,
        ),
      ),
    );
  }

  void _nextStep() async {
    if (_currentStep < widget.steps.length - 1) {
      // Move to next step
      await _animationController.reverse();

      setState(() {
        _currentStep++;
      });

      await _animationController.forward();
    } else {
      // Tour complete
      await _completeTour();
    }
  }

  void _skip() async {
    widget.onSkip?.call();
    await _completeTour();
  }

  Future<void> _completeTour() async {
    // Mark tour as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_completed_${widget.tourId}', true);

    widget.onComplete?.call();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Rect? _getTargetRect(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return null;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }
}

/// Tour step definition
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData? icon;
  final Color? iconColor;
  final double spotlightRadius;

  TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.icon,
    this.iconColor,
    this.spotlightRadius = 80.0,
  });
}

/// Spotlight painter for highlighting target
class SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double spotlightRadius;

  SpotlightPainter({
    required this.targetRect,
    this.spotlightRadius = 80.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create spotlight hole
    final spotlightCenter = Offset(
      targetRect.left + targetRect.width / 2,
      targetRect.top + targetRect.height / 2,
    );

    final spotlightPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: spotlightCenter,
          radius: spotlightRadius,
        ),
      );

    // Subtract spotlight from overlay
    final finalPath =
        Path.combine(PathOperation.difference, overlayPath, spotlightPath);

    canvas.drawPath(finalPath, overlayPaint);

    // Draw spotlight border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(spotlightCenter, spotlightRadius, borderPaint);
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.spotlightRadius != spotlightRadius;
  }
}

/// Predefined tours for SortBliss
class SortBlissTours {
  /// Home screen features tour
  static List<TourStep> homeTour({
    required GlobalKey achievementsKey,
    required GlobalKey leaderboardKey,
    required GlobalKey eventsKey,
    required GlobalKey powerUpsKey,
  }) {
    return [
      TourStep(
        targetKey: achievementsKey,
        title: 'Achievements',
        description:
            'Complete challenges and unlock amazing achievements as you play!',
        icon: Icons.emoji_events,
        iconColor: Colors.amber,
      ),
      TourStep(
        targetKey: leaderboardKey,
        title: 'Leaderboards',
        description:
            'Compete with players worldwide and climb to the top of the rankings!',
        icon: Icons.leaderboard,
        iconColor: Colors.green,
      ),
      TourStep(
        targetKey: eventsKey,
        title: 'Seasonal Events',
        description:
            'Join limited-time events for exclusive rewards and challenges!',
        icon: Icons.celebration,
        iconColor: Colors.orange,
      ),
      TourStep(
        targetKey: powerUpsKey,
        title: 'Power-Ups',
        description:
            'Use power-ups strategically to overcome difficult levels!',
        icon: Icons.power,
        iconColor: Colors.purple,
      ),
    ];
  }

  /// Game screen power-ups tour
  static List<TourStep> powerUpsTour({
    required GlobalKey undoKey,
    required GlobalKey hintKey,
    required GlobalKey shuffleKey,
  }) {
    return [
      TourStep(
        targetKey: undoKey,
        title: 'Undo',
        description: 'Made a mistake? Use Undo to reverse your last move!',
        icon: Icons.undo,
        iconColor: Colors.blue,
      ),
      TourStep(
        targetKey: hintKey,
        title: 'Hint',
        description: 'Stuck? Get a helpful hint to find the best move!',
        icon: Icons.lightbulb,
        iconColor: Colors.amber,
      ),
      TourStep(
        targetKey: shuffleKey,
        title: 'Shuffle',
        description: 'Reorganize the items for a fresh perspective!',
        icon: Icons.shuffle,
        iconColor: Colors.purple,
      ),
    ];
  }
}

/// Helper to check if tour has been shown
class TourManager {
  static Future<bool> hasShownTour(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tour_completed_$tourId') ?? false;
  }

  static Future<void> resetTour(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tour_completed_$tourId');
  }

  static Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('tour_completed_')) {
        await prefs.remove(key);
      }
    }
  }
}
