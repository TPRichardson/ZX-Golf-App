import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/review/widgets/analysis_filters.dart';
import 'package:zx_golf_app/features/review/widgets/performance_chart.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S12 §12.6.2 — Analysis tab: filter row + chart toggle + chart surface.
// Filter-driven scope with Performance | Volume | Both toggle.

/// S12 §12.6.2 — Time resolution.
enum TimeResolution { daily, weekly, monthly }

/// S12 §12.6.2 — Date range presets.
enum DateRangePreset { fourWeeks, threeMonths, sixMonths, twelveMonths }

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _sessionScrollController = ScrollController();
  SkillArea? _selectedSkillArea;
  DrillType? _drillTypeFilter;
  TimeResolution _resolution = TimeResolution.weekly;
  DateRangePreset _dateRange = DateRangePreset.threeMonths;
  // S05 §5.2 — Date range persistence: 1 hour, then reset.
  DateTime? _lastFilterChange;

  @override
  void initState() {
    super.initState();
    _lastFilterChange = DateTime.now();
  }

  @override
  void dispose() {
    _sessionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    // Check if filter persistence has expired (1 hour).
    if (_lastFilterChange != null &&
        DateTime.now().difference(_lastFilterChange!) >
            const Duration(hours: 1)) {
      _resetFilters();
    }

    final userId = ref.watch(currentUserIdProvider);
    final sessionsAsync = ref.watch(closedSessionsProvider(userId));

    return Column(
      children: [
        // Filter row.
        AnalysisFilters(
          selectedSkillArea: _selectedSkillArea,
          drillTypeFilter: _drillTypeFilter,
          onSkillAreaChanged: (sa) =>
              _updateFilter(() => _selectedSkillArea = sa),
          onDrillTypeChanged: (dt) =>
              _updateFilter(() => _drillTypeFilter = dt),
        ),

        // Charts.
        Expanded(
          child: sessionsAsync.when(
            data: (sessions) {
              final filtered = _filterSessions(sessions);
              final cutoff = _dateRangeCutoff();
              final inRange = filtered
                  .where((s) =>
                      s.session.completionTimestamp != null &&
                      s.session.completionTimestamp!.isAfter(cutoff))
                  .toList();

              // Use cached score map instead of parsing JSON in build.
              final scoreMapAsync =
                  ref.watch(sessionScoreMapProvider(userId));
              final scoreMap = scoreMapAsync.valueOrNull ?? {};

              if (inRange.isEmpty) {
                return Center(
                  child: Text(
                    'No session data for this filter',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodyLgSize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Charts + resolution/range bar (fixed at top).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingTokens.md, SpacingTokens.md,
                      SpacingTokens.md, 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 200,
                          child: PerformanceChart(
                            sessions: inRange,
                            resolution: _resolution,
                            sessionScoreMap: scoreMap,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        // Resolution + Range inline filter bar.
                        _ResolutionRangeBar(
                          resolution: _resolution,
                          dateRange: _dateRange,
                          onResolutionChanged: (r) =>
                              _updateFilter(() => _resolution = r),
                          onDateRangeChanged: (dr) =>
                              _updateFilter(() => _dateRange = dr),
                        ),
                      ],
                    ),
                  ),
                  // Session list (scrollable).
                  Expanded(
                    child: Scrollbar(
                      controller: _sessionScrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                      controller: _sessionScrollController,
                      padding: const EdgeInsets.fromLTRB(
                        SpacingTokens.md, SpacingTokens.sm,
                        SpacingTokens.md, SpacingTokens.md,
                      ),
                      itemCount: inRange.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: SpacingTokens.sm),
                            child: Text(
                              'Recent Sessions',
                              style: TextStyle(
                                fontSize: TypographyTokens.headerSize,
                                fontWeight: TypographyTokens.headerWeight,
                                color: ColorTokens.textPrimary,
                              ),
                            ),
                          );
                        }
                        final s = inRange[index - 1];
                        final score =
                            scoreMap[s.session.sessionId] ?? 0.0;
                        final stars = scoreToStars(score);
                        return _SessionTile(
                          drillName: s.drill.name,
                          date: s.session.completionTimestamp,
                          stars: stars,
                          drillType: s.drill.drillType,
                        );
                      },
                    ),
                    ),
                  ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error loading sessions',
                style: TextStyle(color: ColorTokens.errorDestructive),
              ),
            ),
          ),
        ),

      ],
    );
  }

  List<SessionWithDrill> _filterSessions(
      List<SessionWithDrill> sessions) {
    return sessions.where((s) {
      // Skill area filter.
      if (_selectedSkillArea != null &&
          s.drill.skillArea != _selectedSkillArea) {
        return false;
      }

      // Drill type filter.
      if (_drillTypeFilter != null &&
          s.drill.drillType != _drillTypeFilter) {
        return false;
      }

      // Exclude technique blocks when no type filter is active.
      if (_drillTypeFilter == null &&
          s.drill.drillType == DrillType.techniqueBlock) {
        return false;
      }

      return true;
    }).toList();
  }

  DateTime _dateRangeCutoff() {
    final now = DateTime.now();
    switch (_dateRange) {
      case DateRangePreset.fourWeeks:
        return now.subtract(const Duration(days: 28));
      case DateRangePreset.threeMonths:
        return now.subtract(const Duration(days: 90));
      case DateRangePreset.sixMonths:
        return now.subtract(const Duration(days: 180));
      case DateRangePreset.twelveMonths:
        return now.subtract(const Duration(days: 365));
    }
  }

  void _updateFilter(VoidCallback apply) {
    setState(() {
      apply();
      _lastFilterChange = DateTime.now();
    });
  }

  void _resetFilters() {
    _selectedSkillArea = null;
    _drillTypeFilter = null;
    _resolution = TimeResolution.weekly;
    _dateRange = DateRangePreset.threeMonths;
  }
}

class _ResolutionRangeBar extends StatelessWidget {
  final TimeResolution resolution;
  final DateRangePreset dateRange;
  final ValueChanged<TimeResolution> onResolutionChanged;
  final ValueChanged<DateRangePreset> onDateRangeChanged;

  const _ResolutionRangeBar({
    required this.resolution,
    required this.dateRange,
    required this.onResolutionChanged,
    required this.onDateRangeChanged,
  });

  static String _resolutionLabel(TimeResolution r) => switch (r) {
        TimeResolution.daily => 'Daily',
        TimeResolution.weekly => 'Weekly',
        TimeResolution.monthly => 'Monthly',
      };

  static String _rangeLabel(DateRangePreset d) => switch (d) {
        DateRangePreset.fourWeeks => '4 Weeks',
        DateRangePreset.threeMonths => '3 Months',
        DateRangePreset.sixMonths => '6 Months',
        DateRangePreset.twelveMonths => '12 Months',
      };

  static Widget _divider() => Container(
        width: 1,
        height: 24,
        color: ColorTokens.textTertiary,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          // Resolution picker.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: ColorTokens.surfaceModal,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ShapeTokens.radiusModal),
                    ),
                    title: const Text(
                      'Resolution',
                      style: TextStyle(color: ColorTokens.textPrimary),
                    ),
                    contentPadding: const EdgeInsets.all(SpacingTokens.md),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final r in TimeResolution.values)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: SpacingTokens.sm),
                            child: ZxPillButton(
                              label: _resolutionLabel(r),
                              expanded: true,
                              centered: true,
                              variant: r == resolution
                                  ? ZxPillVariant.primary
                                  : ZxPillVariant.tertiary,
                              onTap: () => Navigator.pop(ctx, r.name),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
                if (result == null) return;
                onResolutionChanged(TimeResolution.values
                    .firstWhere((r) => r.name == result));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _resolutionLabel(resolution),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: ColorTokens.primaryDefault,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    const Icon(
                      Icons.filter_list,
                      size: 20,
                      color: ColorTokens.primaryDefault,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _divider(),
          // Date range picker.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: ColorTokens.surfaceModal,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ShapeTokens.radiusModal),
                    ),
                    title: const Text(
                      'Date Range',
                      style: TextStyle(color: ColorTokens.textPrimary),
                    ),
                    contentPadding: const EdgeInsets.all(SpacingTokens.md),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final d in DateRangePreset.values)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: SpacingTokens.sm),
                            child: ZxPillButton(
                              label: _rangeLabel(d),
                              expanded: true,
                              centered: true,
                              variant: d == dateRange
                                  ? ZxPillVariant.primary
                                  : ZxPillVariant.tertiary,
                              onTap: () => Navigator.pop(ctx, d.name),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
                if (result == null) return;
                onDateRangeChanged(DateRangePreset.values
                    .firstWhere((d) => d.name == result));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _rangeLabel(dateRange),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: ColorTokens.primaryDefault,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    const Icon(
                      Icons.filter_list,
                      size: 20,
                      color: ColorTokens.primaryDefault,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final String drillName;
  final DateTime? date;
  final double stars;
  final DrillType drillType;

  const _SessionTile({
    required this.drillName,
    required this.date,
    required this.stars,
    required this.drillType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drillName,
                  style: const TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null ? formatDate(date!) : '',
                  style: const TextStyle(
                    fontSize: TypographyTokens.bodySmSize,
                    color: ColorTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.sm,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: _scoreColor(stars).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusBadge),
            ),
            child: Text(
              '${stars.toStringAsFixed(1)}\u2605',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: FontWeight.w700,
                color: _scoreColor(stars),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _scoreColor(double stars) {
    if (stars >= 4.0) return ColorTokens.successDefault;
    if (stars >= 2.5) return ColorTokens.ragAmber;
    return ColorTokens.errorDestructive;
  }
}
