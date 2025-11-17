import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/combo_tracker_service.dart';
import '../../core/theme/app_theme.dart';

/// Combo display widget showing current combo and multiplier
///
/// Displays:
/// - Combo counter with animated scaling
/// - Score multiplier (x1.5, x2, x3, etc.)
/// - Combo tier badge (Bronze, Silver, Gold, Platinum, Diamond)
/// - Progress bar to next multiplier
/// - Pulsing animation when active
class ComboDisplayWidget extends StatefulWidget {
  final ComboTrackerService comboTracker;

  const ComboDisplayWidget({
    Key? key,
    required this.comboTracker,
  }) : super(key: key);

  @override
  State<ComboDisplayWidget> createState() => _ComboDisplayWidgetState();
}

class _ComboDisplayWidgetState extends State<ComboDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.comboTracker.addListener(_onComboChanged);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.comboTracker.removeListener(_onComboChanged);
    super.dispose();
  }

  void _onComboChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.comboTracker.currentCombo;
    final multiplier = widget.comboTracker.currentMultiplier;
    final isActive = widget.comboTracker.isComboActive;
    final tier = widget.comboTracker.getComboTier();

    if (combo == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedScale(
      scale: isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(tier),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10.w),
          boxShadow: [
            BoxShadow(
              color: _getTierColor(tier).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Combo icon
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department,
                  size: 6.w,
                  color: Colors.white,
                ),
              ),

              SizedBox(width: 2.w),

              // Combo info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Combo counter
                  Text(
                    '$combo COMBO',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),

                  // Multiplier
                  if (multiplier > 1.0)
                    Text(
                      '${multiplier.toStringAsFixed(1)}x SCORE',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                ],
              ),

              SizedBox(width: 2.w),

              // Tier badge
              if (tier > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    widget.comboTracker.getComboTierName(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int tier) {
    switch (tier) {
      case 5: // Diamond
        return [Colors.cyan.shade400, Colors.blue.shade600];
      case 4: // Platinum
        return [Colors.grey.shade300, Colors.grey.shade600];
      case 3: // Gold
        return [Colors.amber.shade300, Colors.orange.shade600];
      case 2: // Silver
        return [Colors.grey.shade100, Colors.grey.shade400];
      case 1: // Bronze
        return [Colors.brown.shade300, Colors.brown.shade600];
      default:
        return [Colors.green.shade300, Colors.green.shade600];
    }
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 5:
        return Colors.cyan;
      case 4:
        return Colors.grey;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 1:
        return Colors.brown;
      default:
        return Colors.green;
    }
  }
}

/// Compact combo counter for top of screen
class ComboCounterWidget extends StatelessWidget {
  final ComboTrackerService comboTracker;

  const ComboCounterWidget({
    Key? key,
    required this.comboTracker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: comboTracker,
      builder: (context, child) {
        final combo = comboTracker.currentCombo;
        final multiplier = comboTracker.currentMultiplier;

        if (combo == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: _getComboColor(comboTracker.getComboTier()),
            borderRadius: BorderRadius.circular(5.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 5.w,
                color: Colors.white,
              ),
              SizedBox(width: 1.w),
              Text(
                '$combo',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (multiplier > 1.0) ...[
                SizedBox(width: 2.w),
                Text(
                  '×${multiplier.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getComboColor(int tier) {
    switch (tier) {
      case 5:
        return Colors.cyan.shade500;
      case 4:
        return Colors.grey.shade500;
      case 3:
        return Colors.amber.shade500;
      case 2:
        return Colors.grey.shade400;
      case 1:
        return Colors.brown.shade400;
      default:
        return Colors.green.shade500;
    }
  }
}

/// Combo milestone popup (shown when reaching milestone)
class ComboMilestonePopup extends StatefulWidget {
  final int combo;
  final double multiplier;
  final int bonusCoins;

  const ComboMilestonePopup({
    Key? key,
    required this.combo,
    required this.multiplier,
    required this.bonusCoins,
  }) : super(key: key);

  @override
  State<ComboMilestonePopup> createState() => _ComboMilestonePopupState();
}

class _ComboMilestonePopupState extends State<ComboMilestonePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(5.w),
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
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 15.w,
                        color: Colors.white,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${widget.combo} COMBO!',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '${widget.multiplier}x Multiplier',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      if (widget.bonusCoins > 0) ...[
                        SizedBox(height: 2.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 6.w,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '+${widget.bonusCoins} Bonus Coins!',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
