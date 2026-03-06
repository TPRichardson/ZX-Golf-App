// Phase M8 — Matrix review screen.
// Shows completed matrix run history with distance summaries and snapshot management.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/matrix/screens/matrix_completion_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// Phase M8 — Matrix review: run history, distance ladder, snapshot management.
class MatrixReviewScreen extends ConsumerStatefulWidget {
  const MatrixReviewScreen({super.key});

  @override
  ConsumerState<MatrixReviewScreen> createState() =>
      _MatrixReviewScreenState();
}

class _MatrixReviewScreenState extends ConsumerState<MatrixReviewScreen>
    with AutomaticKeepAliveClientMixin {
  MatrixType? _filterType;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final runsAsync = ref.watch(matrixRunsProvider(kDevUserId));
    final snapshotsAsync = ref.watch(snapshotsProvider(kDevUserId));

    return Column(
      children: [
        // Filter row.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          decoration: const BoxDecoration(
            color: ColorTokens.surfacePrimary,
            border: Border(
              bottom: BorderSide(color: ColorTokens.surfaceBorder),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Type: ',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                ),
              ),
              _buildFilterChip('All', null),
              const SizedBox(width: SpacingTokens.xs),
              _buildFilterChip('Gapping', MatrixType.gappingChart),
              const SizedBox(width: SpacingTokens.xs),
              _buildFilterChip('Wedge', MatrixType.wedgeMatrix),
              const SizedBox(width: SpacingTokens.xs),
              _buildFilterChip('Chipping', MatrixType.chippingMatrix),
            ],
          ),
        ),

        // Primary snapshot banner.
        snapshotsAsync.when(
          data: (snapshots) {
            final primary =
                snapshots.where((s) => s.isPrimary).firstOrNull;
            if (primary == null) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              color: ColorTokens.primaryDefault.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.star,
                      size: 16, color: ColorTokens.primaryDefault),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'Primary: ${primary.label ?? "Snapshot ${primary.snapshotId.substring(0, 8)}"}',
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        color: ColorTokens.primaryDefault,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Run list.
        Expanded(
          child: runsAsync.when(
            data: (runs) {
              final filtered = _filterType != null
                  ? runs
                      .where((r) => r.matrixType == _filterType)
                      .toList()
                  : runs;

              if (filtered.isEmpty) {
                return _buildZeroState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(SpacingTokens.md),
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: SpacingTokens.sm),
                itemBuilder: (_, index) =>
                    _buildRunCard(filtered[index]),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, MatrixType? type) {
    final selected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _filterType = v ? type : null),
      selectedColor: ColorTokens.primaryDefault,
      backgroundColor: ColorTokens.surfaceRaised,
      labelStyle: TextStyle(
        fontSize: TypographyTokens.microSize,
        color: selected ? Colors.white : ColorTokens.textSecondary,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildRunCard(MatrixRun run) {
    final typeLabel = _matrixTypeLabel(run.matrixType);
    final stateLabel = run.runState == RunState.completed
        ? 'Completed'
        : run.runState.dbValue;

    return GestureDetector(
      onTap: () {
        if (run.runState == RunState.completed) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MatrixCompletionScreen(
                matrixRunId: run.matrixRunId,
                userId: kDevUserId,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius:
              BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _matrixTypeIcon(run.matrixType),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    '$typeLabel #${run.runNumber}',
                    style: const TextStyle(
                      fontSize: TypographyTokens.bodyLgSize,
                      fontWeight: FontWeight.w500,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: run.runState == RunState.completed
                        ? ColorTokens.successDefault
                            .withValues(alpha: 0.15)
                        : ColorTokens.textTertiary
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                        ShapeTokens.radiusGrid),
                  ),
                  child: Text(
                    stateLabel,
                    style: TextStyle(
                      fontSize: TypographyTokens.microSize,
                      fontWeight: FontWeight.w500,
                      color: run.runState == RunState.completed
                          ? ColorTokens.successDefault
                          : ColorTokens.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            Row(
              children: [
                Text(
                  '${run.sessionShotTarget} shots/cell',
                  style: const TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: ColorTokens.textSecondary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                if (run.endTimestamp != null)
                  Text(
                    _formatDate(run.endTimestamp!),
                    style: const TextStyle(
                      fontSize: TypographyTokens.microSize,
                      color: ColorTokens.textTertiary,
                    ),
                  )
                else
                  Text(
                    'Started ${_formatDate(run.startTimestamp)}',
                    style: const TextStyle(
                      fontSize: TypographyTokens.microSize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_on,
              size: 48, color: ColorTokens.textTertiary),
          const SizedBox(height: SpacingTokens.md),
          const Text(
            'No matrix runs yet',
            style: TextStyle(
              fontSize: TypographyTokens.headerSize,
              fontWeight: TypographyTokens.headerWeight,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          const Text(
            'Start a Gapping Chart, Wedge Matrix,\nor Chipping Matrix from the Home screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Icon _matrixTypeIcon(MatrixType type) {
    switch (type) {
      case MatrixType.gappingChart:
        return const Icon(Icons.grid_on,
            size: 20, color: ColorTokens.primaryDefault);
      case MatrixType.wedgeMatrix:
        return const Icon(Icons.grid_view,
            size: 20, color: ColorTokens.primaryDefault);
      case MatrixType.chippingMatrix:
        return const Icon(Icons.grid_3x3,
            size: 20, color: ColorTokens.primaryDefault);
    }
  }

  String _matrixTypeLabel(MatrixType type) {
    switch (type) {
      case MatrixType.gappingChart:
        return 'Gapping Chart';
      case MatrixType.wedgeMatrix:
        return 'Wedge Matrix';
      case MatrixType.chippingMatrix:
        return 'Chipping Matrix';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
