import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActionButtonsWidget extends StatefulWidget {
  final VoidCallback onNextLevel;
  final VoidCallback onReplayLevel;
  final VoidCallback onShareScore;
  final VoidCallback? onWatchAd;
  final bool showAdButton;

  const ActionButtonsWidget({
    Key? key,
    required this.onNextLevel,
    required this.onReplayLevel,
    required this.onShareScore,
    this.onWatchAd,
    this.showAdButton = true,
  }) : super(key: key);

  @override
  State<ActionButtonsWidget> createState() => _ActionButtonsWidgetState();
}

class _ActionButtonsWidgetState extends State<ActionButtonsWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      _slideController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
    bool isPulsing = false,
  }) {
    Widget button = SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 4,
          shadowColor: backgroundColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
        ),
        child: Text(
          text,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return isPulsing
        ? AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: button,
              );
            },
          )
        : button;
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    required String iconName,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 5.h,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 4.w,
        ),
        label: Text(
          text,
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppTheme.lightTheme.colorScheme.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.5.w),
          ),
        ),
      ),
    );
  }

  Widget _buildAdButton() {
    return Container(
      width: double.infinity,
      height: 5.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.tertiary,
            AppTheme.lightTheme.colorScheme.tertiary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(2.5.w),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.tertiary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onWatchAd,
          borderRadius: BorderRadius.circular(2.5.w),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'play_circle_filled',
                  color: Colors.white,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Watch Ad for 2x Coins',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            _buildPrimaryButton(
              text: 'Next Level',
              onPressed: widget.onNextLevel,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              textColor: Colors.white,
              isPulsing: true,
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryButton(
                    text: 'Replay',
                    onPressed: widget.onReplayLevel,
                    iconName: 'replay',
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildSecondaryButton(
                    text: 'Share',
                    onPressed: widget.onShareScore,
                    iconName: 'share',
                  ),
                ),
              ],
            ),
            if (widget.showAdButton && widget.onWatchAd != null) ...[
              SizedBox(height: 3.h),
              _buildAdButton(),
            ],
          ],
        ),
      ),
    );
  }
}
