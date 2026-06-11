import 'package:flutter/material.dart';

/// Animated number counter that counts from 0 to target with easing.
///
/// Usage:
///   AnimatedCounter(value: 1247, prefix: '₹', suffix: 'K')
///   AnimatedCounter(value: 42, duration: Duration(milliseconds: 800))
class AnimatedCounter extends StatefulWidget {
  final num value;
  final String prefix;
  final String suffix;
  final Duration duration;
  final TextStyle? style;
  final int decimals;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.decimals = 0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  num _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue =
            _previousValue +
            (_animation.value * (widget.value - _previousValue));

        String formatted;
        if (widget.decimals > 0) {
          formatted = currentValue.toDouble().toStringAsFixed(widget.decimals);
        } else {
          formatted = currentValue.round().toString();
        }

        return Text(
          '${widget.prefix}$formatted${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// Animated counter that formats large numbers in Indian style (L/K)
class AnimatedIndianCounter extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedIndianCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<AnimatedIndianCounter> createState() => _AnimatedIndianCounterState();
}

class _AnimatedIndianCounterState extends State<AnimatedIndianCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatIndian(num value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value * widget.value;
        return Text(_formatIndian(currentValue), style: widget.style);
      },
    );
  }
}
