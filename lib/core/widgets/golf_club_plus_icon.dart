import 'package:flutter/material.dart';

/// A custom-painted golf bag icon with three clubs and a "+" badge.
/// Trapezoidal bag body with three curved club heads protruding from top.
class GolfClubPlusIcon extends StatelessWidget {
  final double size;
  final Color clubColor;
  final Color plusColor;

  const GolfClubPlusIcon({
    super.key,
    this.size = 24,
    required this.clubColor,
    required this.plusColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GolfBagPainter(
          clubColor: clubColor,
          plusColor: plusColor,
        ),
      ),
    );
  }
}

class _GolfBagPainter extends CustomPainter {
  final Color clubColor;
  final Color plusColor;

  _GolfBagPainter({required this.clubColor, required this.plusColor});

  @override
  void paint(Canvas canvas, Size size) {
    // SVG viewBox 200×200, normalise all coordinates to canvas size.
    final s = size.width;

    // --- Bag body: trapezoid with rounded bottom ---
    final bagFill = Paint()
      ..color = clubColor
      ..style = PaintingStyle.fill;

    final bagPath = Path()
      ..moveTo(s * 0.35, s * 0.30) // top-left
      ..lineTo(s * 0.65, s * 0.30) // top-right
      ..lineTo(s * 0.625, s * 0.85) // right side tapers in
      ..cubicTo(
        s * 0.625, s * 0.875,
        s * 0.60, s * 0.90,
        s * 0.575, s * 0.90,
      )
      ..lineTo(s * 0.425, s * 0.90) // bottom
      ..cubicTo(
        s * 0.40, s * 0.90,
        s * 0.375, s * 0.875,
        s * 0.375, s * 0.85,
      )
      ..close();

    canvas.drawPath(bagPath, bagFill);

    // --- Bag collar band ---
    final bandFill = Paint()
      ..color = clubColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(s * 0.375, s * 0.325, s * 0.25, s * 0.05),
      bandFill,
    );

    // --- Club stems and heads ---
    final stemPaint = Paint()
      ..color = clubColor.withValues(alpha: 0.6)
      ..strokeWidth = s * 0.02
      ..strokeCap = StrokeCap.round;

    final headPaint = Paint()
      ..color = clubColor.withValues(alpha: 0.5)
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Club 1 (left): angled left.
    canvas.drawLine(Offset(s * 0.425, s * 0.30), Offset(s * 0.40, s * 0.15), stemPaint);
    final head1 = Path()
      ..moveTo(s * 0.39, s * 0.14)
      ..quadraticBezierTo(s * 0.425, s * 0.10, s * 0.46, s * 0.14);
    canvas.drawPath(head1, headPaint);

    // Club 2 (centre): straight up.
    canvas.drawLine(Offset(s * 0.50, s * 0.30), Offset(s * 0.50, s * 0.125), stemPaint);
    final head2 = Path()
      ..moveTo(s * 0.49, s * 0.115)
      ..quadraticBezierTo(s * 0.525, s * 0.075, s * 0.56, s * 0.115);
    canvas.drawPath(head2, headPaint);

    // Club 3 (right): angled right.
    canvas.drawLine(Offset(s * 0.575, s * 0.30), Offset(s * 0.60, s * 0.175), stemPaint);
    final head3 = Path()
      ..moveTo(s * 0.59, s * 0.165)
      ..quadraticBezierTo(s * 0.625, s * 0.125, s * 0.66, s * 0.165);
    canvas.drawPath(head3, headPaint);

    // --- Plus badge (bottom-right) ---
    final badgeCenter = Offset(s * 0.70, s * 0.70);
    final badgeRadius = s * 0.125;

    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()
        ..color = plusColor
        ..style = PaintingStyle.fill,
    );

    final plusPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;

    final arm = badgeRadius * 0.55;
    canvas.drawLine(
      Offset(badgeCenter.dx - arm, badgeCenter.dy),
      Offset(badgeCenter.dx + arm, badgeCenter.dy),
      plusPaint,
    );
    canvas.drawLine(
      Offset(badgeCenter.dx, badgeCenter.dy - arm),
      Offset(badgeCenter.dx, badgeCenter.dy + arm),
      plusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GolfBagPainter oldDelegate) =>
      clubColor != oldDelegate.clubColor || plusColor != oldDelegate.plusColor;
}
