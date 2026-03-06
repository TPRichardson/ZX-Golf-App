import 'package:flutter/material.dart';

/// A custom-painted golf bag icon with two clubs and optional "+" badge.
/// Based on Flaticon #1386676 — golf bag with putter + iron, carry strap.
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
    final s = size.width;
    final sw = s * 0.085; // stroke width

    final paint = Paint()
      ..color = clubColor
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // --- Bag body: rounded rectangle, slightly tapered at bottom ---
    final bagPath = Path();
    final bagLeft = s * 0.20;
    final bagRight = s * 0.72;
    final bagTop = s * 0.32;
    final bagBottom = s * 0.92;
    final bagRadius = s * 0.08;

    // Tapered bottom (narrower).
    final bottomLeft = bagLeft + s * 0.04;
    final bottomRight = bagRight - s * 0.04;

    bagPath.moveTo(bagLeft + bagRadius, bagTop);
    bagPath.lineTo(bagRight - bagRadius, bagTop);
    bagPath.arcToPoint(
      Offset(bagRight, bagTop + bagRadius),
      radius: Radius.circular(bagRadius),
    );
    bagPath.lineTo(bottomRight, bagBottom - bagRadius);
    bagPath.arcToPoint(
      Offset(bottomRight - bagRadius, bagBottom),
      radius: Radius.circular(bagRadius),
    );
    bagPath.lineTo(bottomLeft + bagRadius, bagBottom);
    bagPath.arcToPoint(
      Offset(bottomLeft, bagBottom - bagRadius),
      radius: Radius.circular(bagRadius),
    );
    bagPath.lineTo(bagLeft, bagTop + bagRadius);
    bagPath.arcToPoint(
      Offset(bagLeft + bagRadius, bagTop),
      radius: Radius.circular(bagRadius),
    );

    canvas.drawPath(bagPath, paint);

    // --- Bag collar: horizontal band near top ---
    final collarY = bagTop + s * 0.08;
    canvas.drawLine(
      Offset(bagLeft, collarY),
      Offset(bagRight, collarY),
      paint,
    );

    // --- Carry strap: diagonal across bag body ---
    final strapPaint = Paint()
      ..color = clubColor
      ..strokeWidth = sw * 0.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(bagLeft + s * 0.02, bagTop + s * 0.14),
      Offset(bagRight - s * 0.02, bagBottom - s * 0.10),
      strapPaint,
    );

    // --- Handle on right side ---
    final handlePath = Path();
    final handleX = bagRight + s * 0.01;
    handlePath.moveTo(handleX, bagTop + s * 0.12);
    handlePath.quadraticBezierTo(
      handleX + s * 0.10, (bagTop + bagBottom) * 0.5,
      handleX, bagBottom - s * 0.20,
    );
    canvas.drawPath(handlePath, paint);

    // --- Club 1 (left): Putter — flat rectangular head ---
    // Shaft.
    final putter1Bottom = Offset(s * 0.34, bagTop + s * 0.02);
    final putter1Top = Offset(s * 0.26, s * 0.06);
    canvas.drawLine(putter1Bottom, putter1Top, paint);

    // Putter head: small horizontal rectangle at top.
    final putterHeadPaint = Paint()
      ..color = clubColor
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final phLeft = putter1Top.dx - s * 0.08;
    final phRight = putter1Top.dx + s * 0.02;
    final phTop = putter1Top.dy - s * 0.06;
    final phBottom = putter1Top.dy - s * 0.01;
    final phR = s * 0.02;

    final putterHead = Path()
      ..addRRect(RRect.fromLTRBR(phLeft, phTop, phRight, phBottom, Radius.circular(phR)));
    canvas.drawPath(putterHead, putterHeadPaint);

    // --- Club 2 (right): Iron — angled head ---
    // Shaft.
    final iron2Bottom = Offset(s * 0.52, bagTop + s * 0.02);
    final iron2Top = Offset(s * 0.60, s * 0.06);
    canvas.drawLine(iron2Bottom, iron2Top, paint);

    // Iron head: small hook/angle.
    final ironHeadPath = Path()
      ..moveTo(iron2Top.dx, iron2Top.dy)
      ..lineTo(iron2Top.dx + s * 0.08, iron2Top.dy - s * 0.05)
      ..lineTo(iron2Top.dx + s * 0.10, iron2Top.dy - s * 0.01);
    canvas.drawPath(ironHeadPath, paint);

    // --- Plus badge (bottom-right corner) ---
    final badgeCenter = Offset(s * 0.82, s * 0.82);
    final badgeRadius = s * 0.15;

    final badgeBg = Paint()
      ..color = plusColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, badgeBg);

    final plusPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = s * 0.055
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
