import 'package:flutter/material.dart';

/// Staggered fade + slide-up animation wrapper.
///
/// Wraps a child widget and applies a delayed entrance animation.
/// Use inside lists and grids for premium on-load animations.
///
/// Usage:
///   ListView.builder(
///     itemBuilder: (ctx, i) => StaggeredFadeSlide(
///       index: i,
///       child: MyListTile(...),
///     ),
///   )
class StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration staggerDelay;
  final Duration animationDuration;
  final double verticalOffset;
  final Curve curve;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.animationDuration = const Duration(milliseconds: 400),
    this.verticalOffset = 30.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.verticalOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Stagger the delay based on index (cap at 10 to avoid long waits)
    final cappedIndex = widget.index.clamp(0, 10);
    Future.delayed(widget.staggerDelay * cappedIndex, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Staggered section animation for larger blocks (dashboard sections).
/// Slightly different timing — slower, more dramatic.
class StaggeredSection extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredSection({super.key, required this.index, required this.child});

  @override
  State<StaggeredSection> createState() => _StaggeredSectionState();
}

class _StaggeredSectionState extends State<StaggeredSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: 120 * widget.index);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
