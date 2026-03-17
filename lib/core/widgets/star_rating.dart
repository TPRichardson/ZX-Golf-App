import 'package:flutter/material.dart';

/// Renders 5 stars with fractional fill (0.1 granularity) for a 0.0–5.0 value.
class StarRating extends StatelessWidget {
  final double stars;
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.stars,
    this.size = 24.0,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final fill = (stars - index).clamp(0.0, 1.0);

        if (fill >= 1.0) {
          return Icon(Icons.star, size: size, color: color);
        } else if (fill <= 0.0) {
          return Icon(Icons.star_border, size: size, color: color);
        }

        // Partial fill: stack a clipped filled star over an empty star.
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Icon(Icons.star_border, size: size, color: color),
              ClipRect(
                clipper: _StarClipper(fill),
                child: Icon(Icons.star, size: size, color: color),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fraction;
  _StarClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) => fraction != oldClipper.fraction;
}
