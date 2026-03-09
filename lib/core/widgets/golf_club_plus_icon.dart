import 'package:flutter/material.dart';

/// A custom-painted golf bag icon with three clubs, strap, and "+" badge.
/// Angled bag silhouette with clubs fanning out from the tilted opening.
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
    // All coordinates normalised from a 200×200 SVG viewBox.
    final s = size.width;

    // --- Bag body: angled asymmetric silhouette ---
    final bagFill = Paint()
      ..color = clubColor
      ..style = PaintingStyle.fill;

    final bagPath = Path()
      ..moveTo(s * 0.45, s * 0.30)
      ..lineTo(s * 0.625, s * 0.375)
      ..lineTo(s * 0.575, s * 0.85)
      ..cubicTo(
        s * 0.575, s * 0.875,
        s * 0.55, s * 0.90,
        s * 0.50, s * 0.925,
      )
      ..lineTo(s * 0.40, s * 0.875)
      ..lineTo(s * 0.35, s * 0.70)
      ..cubicTo(
        s * 0.325, s * 0.65,
        s * 0.375, s * 0.55,
        s * 0.425, s * 0.525,
      )
      ..close();

    canvas.drawPath(bagPath, bagFill);

    // --- Collar band: darker parallelogram near opening ---
    final collarFill = Paint()
      ..color = clubColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final collarPath = Path()
      ..moveTo(s * 0.46, s * 0.31)
      ..lineTo(s * 0.615, s * 0.38)
      ..lineTo(s * 0.59, s * 0.45)
      ..lineTo(s * 0.44, s * 0.375)
      ..close();

    canvas.drawPath(collarPath, collarFill);

    // --- Three club stems with curved heads ---
    final clubPaint = Paint()
      ..color = clubColor
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Club 1 (left-most): curves up-right.
    final club1 = Path()
      ..moveTo(s * 0.51, s * 0.325)
      ..lineTo(s * 0.54, s * 0.15)
      ..quadraticBezierTo(s * 0.625, s * 0.125, s * 0.65, s * 0.20);
    canvas.drawPath(club1, clubPaint);

    // Club 2 (middle): further right.
    final club2 = Path()
      ..moveTo(s * 0.575, s * 0.35)
      ..lineTo(s * 0.625, s * 0.225)
      ..quadraticBezierTo(s * 0.725, s * 0.20, s * 0.75, s * 0.275);
    canvas.drawPath(club2, clubPaint);

    // Club 3 (right-most): most angled.
    final club3 = Path()
      ..moveTo(s * 0.59, s * 0.365)
      ..lineTo(s * 0.70, s * 0.30)
      ..quadraticBezierTo(s * 0.775, s * 0.275, s * 0.80, s * 0.35);
    canvas.drawPath(club3, clubPaint);

    // --- Carry strap curves ---
    final strapPaint = Paint()
      ..color = clubColor
      ..strokeWidth = s * 0.02
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Long strap across bag body.
    final strap1 = Path()
      ..moveTo(s * 0.45, s * 0.35)
      ..quadraticBezierTo(s * 0.25, s * 0.50, s * 0.575, s * 0.80);
    canvas.drawPath(strap1, strapPaint);

    // Short strap loop near top.
    final strap2 = Path()
      ..moveTo(s * 0.50, s * 0.375)
      ..quadraticBezierTo(s * 0.425, s * 0.425, s * 0.475, s * 0.50);
    canvas.drawPath(strap2, strapPaint);

    // --- Plus sign: two rounded rectangles ---
    final plusFill = Paint()
      ..color = plusColor
      ..style = PaintingStyle.fill;

    // Horizontal bar.
    canvas.drawRRect(
      RRect.fromLTRBR(
        s * 0.65, s * 0.775,
        s * 0.875, s * 0.835,
        Radius.circular(s * 0.03),
      ),
      plusFill,
    );

    // Vertical bar.
    canvas.drawRRect(
      RRect.fromLTRBR(
        s * 0.7325, s * 0.6925,
        s * 0.7925, s * 0.9175,
        Radius.circular(s * 0.03),
      ),
      plusFill,
    );
  }

  @override
  bool shouldRepaint(covariant _GolfBagPainter oldDelegate) =>
      clubColor != oldDelegate.clubColor || plusColor != oldDelegate.plusColor;
}
