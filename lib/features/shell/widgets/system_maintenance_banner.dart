// Phase 4 — System Maintenance Banner.
// Gap 43 — Displays when systemMaintenanceActiveProvider is true.
// Trigger deferred to post-V1 (Gap 44).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

/// Gap 43 — Maintenance banner shown when system-initiated scoring is active.
class SystemMaintenanceBanner extends ConsumerWidget {
  const SystemMaintenanceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(systemMaintenanceActiveProvider);
    if (!isActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          bottom: BorderSide(color: ColorTokens.primaryDefault, width: 2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorTokens.primaryDefault,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              'Scores are being updated. You can continue practising \u2014 results will sync shortly.',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
