import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/review/screens/session_history_screen.dart';
import 'package:zx_golf_app/features/review/widgets/analysis_filters.dart';
import 'package:zx_golf_app/features/review/widgets/performance_chart.dart';
import 'package:zx_golf_app/features/review/widgets/volume_chart.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S12 §12.6.2 — Analysis tab: filter row + chart toggle + chart surface.
// Filter-driven scope with Performance | Volume | Both toggle.

/// S12 §12.6.2 — Analysis filter scope.
enum AnalysisScope { overall, skillArea, drill }

/// S12 §12.6.2 — Time resolution.
enum TimeResolution { daily, weekly, monthly }

/// S12 §12.6.2 — Chart display mode.
enum ChartMode { performance, volume, both }

/// S12 §12.6.2 — Date range presets.
enum DateRangePreset { fourWeeks, threeMonths, sixMonths, twelveMonths }

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  AnalysisScope _scope = AnalysisScope.overall;
  SkillArea? _selectedSkillArea;
  String? _selectedSubskillId;
  String? _selectedDrillId;
  DrillType? _drillTypeFilter;
  TimeResolution _resolution = TimeResolution.weekly;
  DateRangePreset _dateRange = DateRangePreset.threeMonths;
  ChartMode _chartMode = ChartMode.performance;

  // S05 §5.2 — Date range persistence: 1 hour, then reset.
  DateTime? _lastFilterChange;

  @override
  void initState() {
    super.initState();
    _lastFilterChange = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // Check if filter persistence has expired (1 hour).
    if (_lastFilterChange != null &&
        DateTime.now().difference(_lastFilterChange!) >
            const Duration(hours: 1)) {
      _resetFilters();
    }

    final sessionsAsync = ref.watch(closedSessionsProvider(kDevUserId));

    return Column(
      children: [
        // Filter row.
        AnalysisFilters(
          scope: _scope,
          selectedSkillArea: _selectedSkillArea,
          selectedSubskillId: _selectedSubskillId,
          selectedDrillId: _selectedDrillId,
          drillTypeFilter: _drillTypeFilter,
          resolution: _resolution,
          dateRange: _dateRange,
          chartMode: _chartMode,
          onScopeChanged: (s) => _updateFilter(() => _scope = s),
          onSkillAreaChanged: (sa) =>
              _updateFilter(() => _selectedSkillArea = sa),
          onSubskillChanged: (ss) =>
              _updateFilter(() => _selectedSubskillId = ss),
          onDrillIdChanged: (d) =>
              _updateFilter(() => _selectedDrillId = d),
          onDrillTypeChanged: (dt) =>
              _updateFilter(() => _drillTypeFilter = dt),
          onResolutionChanged: (r) =>
              _updateFilter(() => _resolution = r),
          onDateRangeChanged: (dr) =>
              _updateFilter(() => _dateRange = dr),
          onChartModeChanged: (cm) =>
              _updateFilter(() => _chartMode = cm),
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
                  ref.watch(sessionScoreMapProvider(kDevUserId));
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

              return ListView(
                padding: const EdgeInsets.all(SpacingTokens.md),
                children: [
                  if (_chartMode == ChartMode.performance ||
                      _chartMode == ChartMode.both) ...[
                    Text(
                      'Performance',
                      style: TextStyle(
                        fontSize: TypographyTokens.headerSize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    SizedBox(
                      height: 200,
                      child: PerformanceChart(
                        sessions: inRange,
                        resolution: _resolution,
                        sessionScoreMap: scoreMap,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                  ],
                  if (_chartMode == ChartMode.volume ||
                      _chartMode == ChartMode.both) ...[
                    Text(
                      'Volume',
                      style: TextStyle(
                        fontSize: TypographyTokens.headerSize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    SizedBox(
                      height: 200,
                      child: VolumeChart(
                        sessions: inRange,
                        resolution: _resolution,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                  ],
                  // Session history CTA when Scope=Drill.
                  if (_scope == AnalysisScope.drill &&
                      _selectedDrillId != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => SessionHistoryScreen(
                            userId: kDevUserId,
                            drillId: _selectedDrillId!,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Session History'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorTokens.primaryDefault,
                        side: const BorderSide(
                            color: ColorTokens.primaryDefault),
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
      // Drill type filter.
      if (_drillTypeFilter != null &&
          s.drill.drillType != _drillTypeFilter) {
        return false;
      }

      // 5D — When "All" drill types selected (null filter) at Overall or
      // SkillArea scope, exclude Technique Block sessions from chart data.
      // At Drill scope, include them if the selected drill is techniqueBlock.
      if (_drillTypeFilter == null &&
          s.drill.drillType == DrillType.techniqueBlock &&
          _scope != AnalysisScope.drill) {
        return false;
      }

      // Scope filters.
      switch (_scope) {
        case AnalysisScope.overall:
          return true;
        case AnalysisScope.skillArea:
          if (_selectedSkillArea != null &&
              s.drill.skillArea != _selectedSkillArea) {
            return false;
          }
          if (_selectedSubskillId != null) {
            final mapping = s.drill.subskillMapping;
            if (!mapping.contains(_selectedSubskillId!)) return false;
          }
          return true;
        case AnalysisScope.drill:
          if (_selectedDrillId != null &&
              s.drill.drillId != _selectedDrillId) {
            return false;
          }
          return true;
      }
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
    _scope = AnalysisScope.overall;
    _selectedSkillArea = null;
    _selectedSubskillId = null;
    _selectedDrillId = null;
    _drillTypeFilter = null;
    _resolution = TimeResolution.weekly;
    _dateRange = DateRangePreset.threeMonths;
    _chartMode = ChartMode.performance;
  }
}
