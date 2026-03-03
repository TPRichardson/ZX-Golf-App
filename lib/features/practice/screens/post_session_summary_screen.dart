// Phase 4 — Post-Session Summary Screen.
// S13 §13.13 — Summary after session close: score, delta, integrity.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';

/// S13 §13.13 — Post-session summary showing score and performance data.
class PostSessionSummaryScreen extends ConsumerWidget {
  final Drill drill;
  final Session session;
  final double? sessionScore;
  final bool integrityBreach;

  const PostSessionSummaryScreen({
    super.key,
    required this.drill,
    required this.session,
    this.sessionScore,
    this.integrityBreach = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = sessionScore;
    final hasIntegrityFlag = integrityBreach;

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header.
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: const BoxDecoration(
                color: ColorTokens.surfaceRaised,
                border: Border(
                  bottom: BorderSide(color: ColorTokens.surfaceBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session Complete',
                      style: TextStyle(
                        fontSize: TypographyTokens.headerSize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: ColorTokens.textSecondary,
                    // Fix 11 — Route back to Home, not just pop one screen.
                    // S12 §12.2 — Set showHome before pop so ShellScreen shows Home Dashboard.
                    onPressed: () {
                      ref.read(showHomeProvider.notifier).state = true;
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  children: [
                    const SizedBox(height: SpacingTokens.xl),
                    // Drill name.
                    Text(
                      drill.name,
                      style: TextStyle(
                        fontSize: TypographyTokens.displayLgSize,
                        fontWeight: TypographyTokens.displayLgWeight,
                        color: ColorTokens.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Text(
                      drill.skillArea.dbValue,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xxl),
                    // Score display.
                    if (score != null) ...[
                      Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w600,
                          color: _scoreColor(score),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        'out of 5.0',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodyLgSize,
                          color: ColorTokens.textSecondary,
                        ),
                      ),
                    ] else
                      Text(
                        'No Score',
                        style: TextStyle(
                          fontSize: TypographyTokens.displayLgSize,
                          fontWeight: TypographyTokens.displayLgWeight,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                    const SizedBox(height: SpacingTokens.xl),
                    // Integrity flag warning.
                    if (hasIntegrityFlag)
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.md),
                        decoration: BoxDecoration(
                          color: ColorTokens.warningIntegrity
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(ShapeTokens.radiusCard),
                          border: Border.all(
                            color: ColorTokens.warningIntegrity
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: ColorTokens.warningIntegrity,
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Expanded(
                              child: Text(
                                'Integrity flag: some values were outside expected bounds.',
                                style: TextStyle(
                                  fontSize: TypographyTokens.bodySize,
                                  color: ColorTokens.warningIntegrity,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: SpacingTokens.xl),
                    // Session details.
                    _DetailRow(
                      label: 'Drill Type',
                      value: drill.drillType.dbValue,
                    ),
                    _DetailRow(
                      label: 'Input Mode',
                      value: drill.inputMode.dbValue,
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: session.status.dbValue,
                    ),
                  ],
                ),
              ),
            ),
            // Done button.
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // Fix 11 — Route back to Home, not just pop one screen.
                  // S12 §12.2 — Set showHome before pop so ShellScreen shows Home Dashboard.
                  onPressed: () {
                    ref.read(showHomeProvider.notifier).state = true;
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorTokens.primaryDefault,
                    padding:
                        const EdgeInsets.symmetric(vertical: SpacingTokens.md),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 3.5) return ColorTokens.successDefault;
    if (score >= 2.0) return ColorTokens.primaryDefault;
    return ColorTokens.warningIntegrity;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
