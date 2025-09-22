import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressTransitionWidget extends StatefulWidget {
  final bool isVisible;
  final int currentLevel;
  final int nextLevel;
  final int score;
  final int stars;
  final String achievement;
  final VoidCallback? onComplete;
  final List<String> unlockedFeatures;

  const ProgressTransitionWidget({
    Key? key,
    required this.isVisible,
    required this.currentLevel,
    required this.nextLevel,
    required this.score,
    required this.stars,
    required this.achievement,
    this.onComplete,
    this.unlockedFeatures = const [],
  }) : super(key: key);

  @override
  State<ProgressTransitionWidget> createState() =>
      _ProgressTransitionWidgetState();
}

class _ProgressTransitionWidgetState extends State<ProgressTransitionWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  bool _showScore = false;
  bool _showStars = false;
  bool _showAchievement = false;
  bool _showUnlocked = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _mainController.addListener(() {
      final progress = _mainController.value;

      if (progress > 0.2 && !_showScore) {
        setState(() => _showScore = true);
      }
      if (progress > 0.4 && !_showStars) {
        setState(() => _showStars = true);
      }
      if (progress > 0.6 && !_showAchievement) {
        setState(() => _showAchievement = true);
      }
      if (progress > 0.8 && !_showUnlocked) {
        setState(() => _showUnlocked = true);
      }
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete?.call();
        });
      }
    });

    if (widget.isVisible) {
      _startTransition();
    }
  }

  void _startTransition() {
    _progressController.forward();
    _mainController.forward();
  }

  @override
  void didUpdateWidget(ProgressTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _resetState();
      _startTransition();
    }
  }

  void _resetState() {
    _showScore = false;
    _showStars = false;
    _showAchievement = false;
    _showUnlocked = false;
    _mainController.reset();
    _progressController.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.blue.shade900.withValues(alpha: 0.95),
            Colors.purple.shade900.withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.98),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Level Transition Header
            Text(
              'Level ${widget.currentLevel} Complete!',
              style: GoogleFonts.inter(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                .animate()
                .slideY(
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                  begin: -0.5,
                  end: 0,
                )
                .fadeIn(),

            SizedBox(height: 4.h),

            // Progress Bar
            Container(
              width: 80.w,
              height: 1.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 80.w * _progressAnimation.value,
                      height: 1.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.yellow.shade400,
                            Colors.orange.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.yellow.shade400.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().slideX(
                  duration: 600.ms,
                  curve: Curves.easeOut,
                  begin: -1,
                  end: 0,
                ),

            SizedBox(height: 6.h),

            // Score Display
            if (_showScore)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Score',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '${widget.score}',
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow.shade400,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                  )
                  .fadeIn(),

            SizedBox(height: 4.h),

            // Stars Display
            if (_showStars)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    child: Icon(
                      index < widget.stars ? Icons.star : Icons.star_border,
                      color: index < widget.stars
                          ? Colors.yellow.shade400
                          : Colors.white.withValues(alpha: 0.3),
                      size: 12.w,
                    ),
                  );
                })
                    .map((star) => star
                        .animate()
                        .scale(
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                          delay: (100 * (3 - widget.stars)).ms,
                        )
                        .shimmer(
                          duration: 1000.ms,
                          color: Colors.white.withValues(alpha: 0.5),
                        ))
                    .toList(),
              ),

            SizedBox(height: 4.h),

            // Achievement
            if (_showAchievement && widget.achievement.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400.withValues(alpha: 0.3),
                      Colors.pink.shade400.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.yellow.shade400,
                      size: 8.w,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      widget.achievement,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .slideY(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                    begin: 0.5,
                    end: 0,
                  )
                  .fadeIn(),

            SizedBox(height: 4.h),

            // Unlocked Features
            if (_showUnlocked && widget.unlockedFeatures.isNotEmpty)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade400.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.green.shade400.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Unlocked!',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade400,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ...widget.unlockedFeatures.map(
                      (feature) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.5.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade400,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              feature,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .slideX(
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                    begin: 1,
                    end: 0,
                  )
                  .fadeIn(),

            const Spacer(),

            // Next Level Preview
            Text(
              'Next: Level ${widget.nextLevel}',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            )
                .animate()
                .slideY(
                  duration: 600.ms,
                  curve: Curves.easeOut,
                  begin: 0.3,
                  end: 0,
                  delay: 2000.ms,
                )
                .fadeIn(delay: 2000.ms),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}
