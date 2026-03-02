// Phase 4 — Score Flash animation widget.
// S15 §15.8.3 — 120ms success flash on hit.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// S15 §15.8.3 — Brief color flash after recording an instance.
/// Flashes successDefault for 120ms on hit, stays neutral on miss.
class ScoreFlash extends StatefulWidget {
  final bool isHit;
  final Widget child;

  const ScoreFlash({
    super.key,
    required this.isHit,
    required this.child,
  });

  @override
  State<ScoreFlash> createState() => _ScoreFlashState();
}

class _ScoreFlashState extends State<ScoreFlash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    // S15 §15.10 — fast motion: 120ms.
    _controller = AnimationController(
      duration: MotionTokens.fast,
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: widget.isHit
          ? ColorTokens.successDefault
          : ColorTokens.missDefault,
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ScoreFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHit != widget.isHit) {
      _colorAnimation = ColorTween(
        begin: widget.isHit
            ? ColorTokens.successDefault
            : ColorTokens.missDefault,
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
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
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          color: _colorAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
