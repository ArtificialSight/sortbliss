import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedAchievementWidget extends StatefulWidget {
  final bool isVisible;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Duration displayDuration;

  const AnimatedAchievementWidget({
    Key? key,
    required this.isVisible,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
    this.displayDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<AnimatedAchievementWidget> createState() =>
      _AnimatedAchievementWidgetState();
}

class _AnimatedAchievementWidgetState extends State<AnimatedAchievementWidget> {
  @override
  void didUpdateWidget(AnimatedAchievementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible && !oldWidget.isVisible) {
      // Auto-hide after display duration
      Future.delayed(widget.displayDuration, () {
        if (mounted && widget.isVisible) {
          // Trigger parent to hide this achievement
          widget.onTap?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 15.h,
      left: 5.w,
      right: 5.w,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.9),
                widget.color.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Achievement Icon
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 8.w,
                ),
              )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                  )
                  .shimmer(
                    duration: 1500.ms,
                    color: Colors.white.withOpacity(0.5),
                  ),

              SizedBox(width: 4.w),

              // Achievement Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .slideX(
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                          begin: 1,
                          end: 0,
                        )
                        .fadeIn(duration: 500.ms),
                    SizedBox(height: 1.h),
                    Text(
                      widget.description,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                        .animate()
                        .slideX(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                          begin: 1,
                          end: 0,
                        )
                        .fadeIn(
                          duration: 600.ms,
                          delay: 100.ms,
                        ),
                  ],
                ),
              ),

              // Close Button
              GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.8),
                    size: 5.w,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 800.ms,
                    delay: 400.ms,
                  )
                  .scale(
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        )
            .animate()
            .slideY(
              duration: 800.ms,
              curve: Curves.elasticOut,
              begin: -1,
              end: 0,
            )
            .fadeIn(duration: 600.ms)
            .scale(
              duration: 600.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
            ),
      ),
    );
  }
}
