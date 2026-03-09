import 'package:flutter/material.dart';

/// Renders 5 stars (filled, half, empty) for a 1.0–5.0 star value.
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
        final IconData icon;
        if (stars >= starNumber) {
          icon = Icons.star;
        } else if (stars >= starNumber - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}
