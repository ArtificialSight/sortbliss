import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/audio_manager.dart';
import '../../../core/haptic_manager.dart';

class AnimatedButtonWidget extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isExpanded;
  final ButtonStyle style;
  final bool isEnabled;

  const AnimatedButtonWidget({
    Key? key,
    required this.text,
    this.icon,
    this.onPressed,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.isExpanded = false,
    this.style = ButtonStyle.primary,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<AnimatedButtonWidget> createState() => _AnimatedButtonWidgetState();
}

class _AnimatedButtonWidgetState extends State<AnimatedButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;

    setState(() {
      _isPressed = true;
    });
    _controller.forward();

    // Play sound and haptic feedback
    AudioManager().playButtonTapSound();
    HapticManager().lightTap();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;

    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  Color _getButtonColor() {
    if (!widget.isEnabled) {
      return Colors.grey.shade300;
    }

    if (widget.color != null) {
      return widget.color!;
    }

    switch (widget.style) {
      case ButtonStyle.primary:
        return Colors.blue.shade600;
      case ButtonStyle.secondary:
        return Colors.grey.shade600;
      case ButtonStyle.success:
        return Colors.green.shade600;
      case ButtonStyle.warning:
        return Colors.orange.shade600;
      case ButtonStyle.danger:
        return Colors.red.shade600;
      case ButtonStyle.gradient:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (!widget.isEnabled) {
      return Colors.grey.shade500;
    }

    return widget.textColor ?? Colors.white;
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: _getTextColor(),
            size: 6.w,
          )
              .animate()
              .scale(
                duration: 200.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(),
          SizedBox(width: 2.w),
        ],
        Text(
          widget.text,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: _getTextColor(),
          ),
        )
            .animate()
            .slideX(
              duration: 300.ms,
              curve: Curves.easeOutBack,
              begin: widget.icon != null ? 0.3 : 0,
              end: 0,
            )
            .fadeIn(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:
                  widget.width ?? (widget.isExpanded ? double.infinity : null),
              height: widget.height ?? 12.h,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isExpanded ? 6.w : 8.w,
                vertical: 3.h,
              ),
              decoration: BoxDecoration(
                gradient: widget.style == ButtonStyle.gradient
                    ? LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.purple.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.style != ButtonStyle.gradient
                    ? _getButtonColor()
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: _getButtonColor().withValues(alpha: 0.3),
                          blurRadius: _isPressed ? 8 : 15,
                          offset: Offset(0, _isPressed ? 2 : 8),
                        ),
                        if (!_isPressed)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                      ]
                    : null,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: _buildButtonContent(),
            ),
          );
        },
      ),
    )
        .animate()
        .slideY(
          duration: 400.ms,
          curve: Curves.easeOutBack,
          begin: 0.3,
          end: 0,
        )
        .fadeIn(duration: 300.ms);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

enum ButtonStyle {
  primary,
  secondary,
  success,
  warning,
  danger,
  gradient,
}
