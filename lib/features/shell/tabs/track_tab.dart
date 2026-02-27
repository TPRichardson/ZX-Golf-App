import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_button.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/core/widgets/zx_input_field.dart';
import 'package:zx_golf_app/core/widgets/zx_segmented_control.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/providers/database_providers.dart';

// TD-06 §4.4 — Demo tab: seed data queryable, design components rendering.

final _systemDrillsProvider = StreamProvider<List<Drill>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.drills)
        ..where((t) => t.origin.equals('System'))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();
});

final _subskillCountProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.subskillRefs.count().getSingle();
});

final _allocationSumProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.selectOnly(db.subskillRefs)
        ..addColumns([db.subskillRefs.allocation.sum()]))
      .getSingle()
      .then((row) => row.read(db.subskillRefs.allocation.sum()) ?? 0);
});

final _eventTypeCountProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.eventTypeRefs.count().getSingle();
});

final _metricSchemaCountProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.metricSchemas.count().getSingle();
});

class TrackTab extends ConsumerWidget {
  const TrackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drills = ref.watch(_systemDrillsProvider);
    final subskillCount = ref.watch(_subskillCountProvider);
    final allocationSum = ref.watch(_allocationSumProvider);
    final eventTypeCount = ref.watch(_eventTypeCountProvider);
    final metricSchemaCount = ref.watch(_metricSchemaCountProvider);

    return Scaffold(
      appBar: const ZxAppBar(title: 'Track'),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          // Seed data verification section
          Text(
            'Seed Data Verification',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: SpacingTokens.sm),
          ZxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStat(
                  context,
                  'System Drills',
                  drills.when(
                    data: (d) => '${d.length} / 28',
                    loading: () => '...',
                    error: (e, _) => 'Error',
                  ),
                  drills.when(
                    data: (d) => d.length == 28,
                    loading: () => false,
                    error: (_, _) => false,
                  ),
                ),
                _buildStat(
                  context,
                  'Subskills',
                  subskillCount.when(
                    data: (c) => '$c / 19',
                    loading: () => '...',
                    error: (_, _) => 'Error',
                  ),
                  subskillCount.when(
                    data: (c) => c == 19,
                    loading: () => false,
                    error: (_, _) => false,
                  ),
                ),
                _buildStat(
                  context,
                  'Allocation Sum',
                  allocationSum.when(
                    data: (s) => '$s / 1000',
                    loading: () => '...',
                    error: (_, _) => 'Error',
                  ),
                  allocationSum.when(
                    data: (s) => s == 1000,
                    loading: () => false,
                    error: (_, _) => false,
                  ),
                ),
                _buildStat(
                  context,
                  'Event Types',
                  eventTypeCount.when(
                    data: (c) => '$c / 16',
                    loading: () => '...',
                    error: (_, _) => 'Error',
                  ),
                  eventTypeCount.when(
                    data: (c) => c == 16,
                    loading: () => false,
                    error: (_, _) => false,
                  ),
                ),
                _buildStat(
                  context,
                  'Metric Schemas',
                  metricSchemaCount.when(
                    data: (c) => '$c / 8',
                    loading: () => '...',
                    error: (_, _) => 'Error',
                  ),
                  metricSchemaCount.when(
                    data: (c) => c == 8,
                    loading: () => false,
                    error: (_, _) => false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),

          // Design components demo section
          Text(
            'Design Components',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: SpacingTokens.sm),
          ZxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ZxButton(
                  label: 'Primary Button',
                  onPressed: () {},
                ),
                const SizedBox(height: SpacingTokens.sm),
                ZxButton(
                  label: 'Secondary Button',
                  variant: ZxButtonVariant.secondary,
                  onPressed: () {},
                ),
                const SizedBox(height: SpacingTokens.sm),
                ZxButton(
                  label: 'Destructive Button',
                  variant: ZxButtonVariant.destructive,
                  onPressed: () {},
                ),
                const SizedBox(height: SpacingTokens.sm),
                ZxButton(
                  label: 'Text Button',
                  variant: ZxButtonVariant.text,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          ZxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ZxInputField(
                  label: 'Sample Input',
                  hintText: 'Enter text...',
                ),
                const SizedBox(height: SpacingTokens.md),
                ZxSegmentedControl<String>(
                  segments: const ['Plan', 'Track', 'Review'],
                  selected: 'Track',
                  onChanged: (_) {},
                  labelBuilder: (s) => s,
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),

          // System drills list
          Text(
            'System Drill Library',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: SpacingTokens.sm),
          drills.when(
            data: (drillList) => Column(
              children: drillList
                  .map((drill) => ZxCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    drill.name,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${drill.skillArea} · ${drill.drillType}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: ColorTokens.textTertiary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              drill.inputMode.toString().split('.').last,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: ColorTokens.primaryDefault,
                                  ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => ZxCard(
              child: Text(
                'Error loading drills: $e',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorTokens.errorDestructive,
                    ),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
        ],
      ),
    );
  }

  Widget _buildStat(
      BuildContext context, String label, String value, bool pass) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Icon(
                pass ? Icons.check_circle : Icons.radio_button_unchecked,
                color: pass
                    ? ColorTokens.successDefault
                    : ColorTokens.textTertiary,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
