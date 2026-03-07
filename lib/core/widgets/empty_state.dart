import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// Shared empty state placeholder used when lists have no data.

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String message;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: ColorTokens.textTertiary),
            const SizedBox(height: SpacingTokens.md),
          ],
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: ColorTokens.textSecondary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: ColorTokens.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
