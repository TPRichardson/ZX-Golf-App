// Phase 4 — Execution Header widget.
// S13 §13.6 — Drill name, set progress, instance count.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';

/// S13 §13.6 — Header showing drill name, set progress, and instance count.
class ExecutionHeader extends StatelessWidget {
  final Drill drill;
  final int currentSetIndex;
  final int requiredSetCount;
  final int currentInstanceCount;
  final int? requiredAttemptsPerSet;

  const ExecutionHeader({
    super.key,
    required this.drill,
    required this.currentSetIndex,
    required this.requiredSetCount,
    required this.currentInstanceCount,
    this.requiredAttemptsPerSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: SpacingTokens.xs,
        right: SpacingTokens.md,
        top: SpacingTokens.sm,
        bottom: SpacingTokens.sm,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          bottom: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: ColorTokens.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              Expanded(
                child: Text(
                  drill.name,
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Row(
            children: [
              Text(
                'Set ${currentSetIndex + 1}/$requiredSetCount',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              if (requiredAttemptsPerSet != null)
                Text(
                  '$currentInstanceCount/$requiredAttemptsPerSet',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.textSecondary,
                  ),
                )
              else
                Text(
                  '$currentInstanceCount shots',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.textSecondary,
                  ),
                ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}
