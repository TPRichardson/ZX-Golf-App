// Phase 4 — Execution Header widget.
// S13 §13.6 — Drill name with set progress in top right.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';

/// S13 §13.6 — Header showing drill name and set progress.
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: ColorTokens.textSecondary),
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
    );
  }
}
