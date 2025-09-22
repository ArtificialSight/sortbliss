import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingUIPanelWidget extends StatefulWidget {
  final bool isVisible;
  final String title;
  final Widget content;
  final VoidCallback? onClose;
  final EdgeInsets? margin;
  final Alignment alignment;
  final Duration animationDuration;

  const FloatingUIPanelWidget({
    Key? key,
    required this.isVisible,
    required this.title,
    required this.content,
    this.onClose,
    this.margin,
    this.alignment = Alignment.center,
    this.animationDuration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  State<FloatingUIPanelWidget> createState() => _FloatingUIPanelWidgetState();
}

class _FloatingUIPanelWidgetState extends State<FloatingUIPanelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingUIPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.isVisible && _controller.isDismissed) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Background overlay
            if (_opacityAnimation.value > 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.5 * _opacityAnimation.value,
                    ),
                  ),
                ),
              ),

            // Floating panel
            Align(
              alignment: widget.alignment,
              child: Container(
                margin: widget.margin ?? EdgeInsets.all(5.w),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Material(
                        elevation: 20,
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.transparent,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: 85.w,
                            maxHeight: 70.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                Colors.white.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Panel Header
                              Container(
                                padding: EdgeInsets.all(5.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400
                                          .withValues(alpha: 0.1),
                                      Colors.purple.shade400
                                          .withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    topRight: Radius.circular(25),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    if (widget.onClose != null)
                                      GestureDetector(
                                        onTap: widget.onClose,
                                        child: Container(
                                          padding: EdgeInsets.all(2.w),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.grey.shade600,
                                            size: 6.w,
                                          ),
                                        ),
                                      )
                                          .animate()
                                          .scale(
                                            duration: 200.ms,
                                            curve: Curves.easeOut,
                                          )
                                          .fadeIn(delay: 200.ms),
                                  ],
                                ),
                              ),

                              // Panel Content
                              Flexible(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.all(5.w),
                                  child: widget.content,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
