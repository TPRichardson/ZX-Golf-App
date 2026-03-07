import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// Shared label-value row used on detail screens (drill detail, session detail).

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
