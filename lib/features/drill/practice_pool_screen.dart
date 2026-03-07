import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/drill_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';

import '../bag/bag_screen.dart';
import 'add_drills_screen.dart';
import 'drill_detail_screen.dart';
import 'widgets/drill_card.dart';

/// 5E — Persistent filter state for Practice Pool (survives navigation).
final practicePoolFilterProvider = StateProvider<SkillArea?>((ref) => null);

// Phase 3 — Practice Pool: user's active drill collection.
// Adopted system drills + active custom drills.
// S12 §12.3 — Track tab primary view.

class PracticePoolScreen extends ConsumerStatefulWidget {
  /// When true, tapping a drill pops with the drillId instead of navigating.
  final bool pickMode;

  /// When true, omits Scaffold/AppBar (embedded in a parent tab).
  final bool embedded;

  const PracticePoolScreen({
    super.key,
    this.pickMode = false,
    this.embedded = false,
  });

  @override
  ConsumerState<PracticePoolScreen> createState() =>
      _PracticePoolScreenState();
}

class _PracticePoolScreenState extends ConsumerState<PracticePoolScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.embedded;
  // Phase 3 stub — replaced when auth is wired.
  static const _userId = kDevUserId;

  Widget _buildBody(BuildContext context) {
    final selectedFilter = ref.watch(practicePoolFilterProvider);
    final poolAsync = ref.watch(practicePoolProvider(_userId));

    return Column(
      children: [
        // Page header + filter button.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.md, SpacingTokens.md, SpacingTokens.sm, 0,
          ),
          child: Row(
            children: [
              Text(
                'Your Drills',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ColorTokens.textPrimary,
                    ),
              ),
              const Spacer(),
              // 5E — Skill area filter persisted across navigation.
              _FilterButton(
                selected: selectedFilter,
                onChanged: (area) =>
                    ref.read(practicePoolFilterProvider.notifier).state = area,
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        // Drill list.
        Expanded(
          child: poolAsync.when(
            data: (drills) {
              final filtered = selectedFilter == null
                  ? drills
                  : drills
                      .where(
                          (d) => d.drill.skillArea == selectedFilter)
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_golf,
                        size: 48,
                        color: ColorTokens.textTertiary,
                      ),
                      const SizedBox(height: SpacingTokens.md),
                      Text(
                        'No drills in your drill library',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: ColorTokens.textSecondary),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Adopt drills from the System Library\nor create your own',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: ColorTokens.textTertiary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: SpacingTokens.sm),
                itemBuilder: (context, index) {
                  final dwa = filtered[index];
                  return DrillCard(
                    drill: dwa.drill,
                    onTap: () {
                      if (widget.pickMode) {
                        Navigator.of(context).pop(dwa.drill.drillId);
                        return;
                      }
                      _openDrillDetail(dwa);
                    },
                    trailing: widget.pickMode
                        ? null
                        : _PlayDrillButton(
                            drillId: dwa.drill.drillId,
                            userId: _userId,
                          ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
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
        ),
      ],
    );
  }

  Future<void> _startCleanPractice() async {
    final surface = await showSurfacePicker(context);
    if (surface == null || !mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(_userId, surfaceType: surface);

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: _userId,
        ),
      ));
    }
  }

  Widget _buildBottomBar() {
    final activePb = ref.watch(activePracticeBlockProvider(_userId));
    final hasActivePb = activePb.valueOrNull != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.sm,
        SpacingTokens.md,
        SpacingTokens.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasActivePb)
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startCleanPractice,
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  label: const Text(
                    'Start Clean Practice',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorTokens.primaryDefault,
                    padding: const EdgeInsets.symmetric(
                      vertical: SpacingTokens.sm,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AddDrillsScreen(),
                ));
              },
              icon: Icon(Icons.add, color: ColorTokens.primaryDefault, size: 18),
              label: Text(
                'Add drills to your library',
                style: TextStyle(color: ColorTokens.primaryDefault),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorTokens.primaryDefault),
                padding: const EdgeInsets.symmetric(
                  vertical: SpacingTokens.sm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    // Embedded mode: no Scaffold, used inside a parent TabBarView.
    if (widget.embedded) {
      return Column(
        children: [
          Expanded(child: _buildBody(context)),
          _buildBottomBar(),
        ],
      );
    }

    return Scaffold(
      appBar: ZxAppBar(
        title: widget.pickMode ? 'Select Drill' : 'Drill Library',
        actions: widget.pickMode
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  tooltip: 'Golf Bag',
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const BagScreen(),
                    ));
                  },
                ),
              ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: widget.pickMode ? null : _buildBottomBar(),
    );
  }

  void _openDrillDetail(DrillWithAdoption dwa) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DrillDetailScreen(
        drillId: dwa.drill.drillId,
        isCustom: dwa.drill.origin == DrillOrigin.userCustom,
      ),
    ));
  }
}

class _PlayDrillButton extends ConsumerWidget {
  final String drillId;
  final String userId;

  const _PlayDrillButton({required this.drillId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        Icons.play_circle_outline,
        size: 32,
        color: ColorTokens.primaryDefault,
      ),
      onPressed: () async {
        final surface = await showSurfacePicker(context);
        if (surface == null || !context.mounted) return;

        final actions = ref.read(practiceActionsProvider);
        final pb = await actions.startPracticeBlock(
          userId,
          initialDrillIds: [drillId],
          surfaceType: surface,
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

/// Filter button that shows current selection and opens a popup menu.
/// Uses a manual showMenu to support null (All) as a selectable value.
class _FilterButton extends StatelessWidget {
  final SkillArea? selected;
  final ValueChanged<SkillArea?> onChanged;

  const _FilterButton({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) async {
        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            const PopupMenuItem(value: 'all', child: Text('All')),
            for (final area in SkillArea.values)
              PopupMenuItem(value: area.dbValue, child: Text(area.dbValue)),
          ],
        );
        if (result == null) return; // dismissed
        if (result == 'all') {
          onChanged(null);
        } else {
          onChanged(SkillArea.values.firstWhere((a) => a.dbValue == result));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected?.dbValue ?? 'All',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.primaryDefault,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: SpacingTokens.xs),
            Icon(
              Icons.filter_list,
              size: 16,
              color: ColorTokens.primaryDefault,
            ),
          ],
        ),
      ),
    );
  }
}

