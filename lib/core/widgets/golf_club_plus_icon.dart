import 'package:flutter/material.dart';

/// A custom-painted diagonal golf club icon with a small "+" badge.
/// Inspired by Flaticon's "golf club variant in diagonal position" style.
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
        painter: _GolfClubPlusPainter(
          clubColor: clubColor,
          plusColor: plusColor,
        ),
      ),
    );
  }
}

class _GolfClubPlusPainter extends CustomPainter {
  final Color clubColor;
  final Color plusColor;

  _GolfClubPlusPainter({required this.clubColor, required this.plusColor});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // --- Shaft: diagonal line from upper-right to lower-left ---
    final shaftPaint = Paint()
      ..color = clubColor
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Shaft runs from top-right area down to club head area.
    final shaftStart = Offset(s * 0.75, s * 0.08);
    final shaftEnd = Offset(s * 0.22, s * 0.62);
    canvas.drawLine(shaftStart, shaftEnd, shaftPaint);

    // --- Grip: small wrap lines near top of shaft ---
    final gripPaint = Paint()
      ..color = clubColor
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 3; i++) {
      final t1 = 0.04 + i * 0.06;
      final t2 = t1 + 0.03;
      final p1 = Offset(
        shaftStart.dx + (shaftEnd.dx - shaftStart.dx) * t1 - s * 0.04,
        shaftStart.dy + (shaftEnd.dy - shaftStart.dy) * t1 + s * 0.02,
      );
      final p2 = Offset(
        shaftStart.dx + (shaftEnd.dx - shaftStart.dx) * t2 + s * 0.04,
        shaftStart.dy + (shaftEnd.dy - shaftStart.dy) * t2 - s * 0.02,
      );
      canvas.drawLine(p1, p2, gripPaint);
    }

    // --- Club head: an angled wedge/iron shape at the bottom of the shaft ---
    final headPaint = Paint()
      ..color = clubColor
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final headFill = Paint()
      ..color = clubColor
      ..style = PaintingStyle.fill;

    final headPath = Path()
      ..moveTo(s * 0.22, s * 0.62)
      ..lineTo(s * 0.08, s * 0.72)
      ..lineTo(s * 0.18, s * 0.80)
      ..close();

    canvas.drawPath(headPath, headFill);
    canvas.drawPath(headPath, headPaint);

    // --- Plus badge (bottom-right) ---
    final badgeCenter = Offset(s * 0.76, s * 0.78);
    final badgeRadius = s * 0.18;

    // Badge background circle.
    final badgeBg = Paint()
      ..color = plusColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, badgeBg);

    // Plus sign.
    final plusPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = s * 0.06
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
  bool shouldRepaint(covariant _GolfClubPlusPainter oldDelegate) =>
      clubColor != oldDelegate.clubColor || plusColor != oldDelegate.plusColor;
}
