import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/drill_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import 'package:zx_golf_app/features/bag/bag_screen.dart';

import 'drill_detail_screen.dart';
import 'widgets/drill_card.dart';

// Phase 3 — System Drill Library. Browse all 28 system drills grouped by SkillArea.
// S14 §14.1 — System drill catalogue.

class DrillLibraryScreen extends ConsumerWidget {
  /// When true, tapping a drill pops with the drillId instead of navigating.
  final bool pickMode;

  const DrillLibraryScreen({super.key, this.pickMode = false});

  // Phase 3 stub — replaced when auth is wired.
  static const _userId = kDevUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemDrillsAsync = ref.watch(systemDrillsProvider);
    final adoptedAsync = ref.watch(adoptedDrillsProvider(_userId));

    return Scaffold(
      appBar: const ZxAppBar(title: 'System Library'),
      body: systemDrillsAsync.when(
        data: (drills) {
          final adopted = adoptedAsync.valueOrNull ?? [];
          final adoptedIds =
              adopted.map((a) => a.drill.drillId).toSet();

          // Group by SkillArea.
          final grouped = <SkillArea, List<Drill>>{};
          for (final drill in drills) {
            grouped.putIfAbsent(drill.skillArea, () => []).add(drill);
          }

          return ListView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            children: [
              for (final area in SkillArea.values)
                if (grouped.containsKey(area)) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: SpacingTokens.md,
                      bottom: SpacingTokens.sm,
                    ),
                    child: Text(
                      area.dbValue,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: ColorTokens.textPrimary,
                              ),
                    ),
                  ),
                  for (final drill in grouped[area]!)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: SpacingTokens.sm,
                      ),
                      child: DrillCard(
                        drill: drill,
                        onTap: () {
                          if (pickMode) {
                            Navigator.of(context).pop(drill.drillId);
                            return;
                          }
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => DrillDetailScreen(
                              drillId: drill.drillId,
                              isCustom: false,
                            ),
                          ));
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StartDrillButton(
                              drillId: drill.drillId,
                              userId: _userId,
                            ),
                            _AdoptToggle(
                              isAdopted: adoptedIds.contains(drill.drillId),
                              onToggle: () async {
                                final drillRepo =
                                    ref.read(drillRepositoryProvider);
                                if (adoptedIds.contains(drill.drillId)) {
                                  await drillRepo.retireAdoption(
                                      _userId, drill.drillId);
                                } else {
                                  try {
                                    await drillRepo.adoptDrill(
                                        _userId, drill.drillId);
                                  } on ValidationException catch (e) {
                                    if (!context.mounted) return;
                                    showDialog(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        backgroundColor: ColorTokens.surfaceModal,
                                        title: const Text('Missing Clubs',
                                            style: TextStyle(
                                                color: ColorTokens.textPrimary)),
                                        content: Text(
                                          e.message,
                                          style: const TextStyle(
                                              color: ColorTokens.textSecondary),
                                        ),
                                        actions: [
                                          ZxPillButton(
                                            label: 'Return to Drills',
                                            variant: ZxPillVariant.tertiary,

                                            onTap: () =>
                                                Navigator.pop(dialogCtx),
                                          ),
                                          ZxPillButton(
                                            label: 'Customise Golf Bag',
                                            variant: ZxPillVariant.primary,

                                            onTap: () {
                                              Navigator.pop(dialogCtx);
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const BagScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: ColorTokens.errorDestructive),
          ),
        ),
      ),
    );
  }
}

class _StartDrillButton extends ConsumerWidget {
  final String drillId;
  final String userId;

  const _StartDrillButton({required this.drillId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        Icons.play_circle_outline,
        color: ColorTokens.successDefault,
      ),
      onPressed: () async {
        // Auto-adopt the drill if not already adopted.
        final drillRepo = ref.read(drillRepositoryProvider);
        try {
          await drillRepo.adoptDrill(userId, drillId);
        } on ValidationException {
          // Missing clubs — proceed anyway, user can still practice.
        } catch (_) {
          // Already adopted or other non-fatal error.
        }

        if (!context.mounted) return;
        final envSurface = await showEnvironmentSurfacePicker(context);
        if (envSurface == null || !context.mounted) return;

        final actions = ref.read(practiceActionsProvider);
        final pb = await actions.startPracticeBlock(
          userId,
          initialDrillIds: [drillId],
          surfaceType: envSurface.surface,
        );

        if (context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PracticeQueueScreen(
              practiceBlockId: pb.practiceBlockId,
              userId: userId,
            ),
          ));
        }
      },
      tooltip: 'Start practice with this drill',
    );
  }
}

class _AdoptToggle extends StatelessWidget {
  final bool isAdopted;
  final VoidCallback onToggle;

  const _AdoptToggle({required this.isAdopted, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isAdopted ? Icons.check_circle : Icons.add_circle_outline,
        color: isAdopted
            ? ColorTokens.successDefault
            : ColorTokens.textTertiary,
      ),
      onPressed: onToggle,
      tooltip: isAdopted ? 'Remove from pool' : 'Add to pool',
    );
  }
}
