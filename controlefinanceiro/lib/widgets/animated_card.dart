import 'package:flutter/material.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final List<Color>? gradient;
  final double? elevation;

  const AnimatedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.gradient,
    this.elevation,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        } : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.color ?? Theme.of(context).colorScheme.surface,
              gradient: widget.gradient != null
                  ? LinearGradient(
                      colors: widget.gradient!,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  blurRadius: widget.elevation ?? 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
