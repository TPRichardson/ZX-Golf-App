// Phase M10 — Matrix analytics Riverpod providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/analytics/analytics_types.dart';
import 'package:zx_golf_app/features/matrix/analytics/insight_generator.dart';
import 'package:zx_golf_app/features/matrix/analytics/matrix_analytics_engine.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

/// Whether analytics should use weighted aggregation (§9.4.4).
/// Session-scoped — does not persist across app restarts.
final analyticsWeightedProvider = StateProvider<bool>((ref) => true);

/// Shared loader: filter runs by type, load details, apply analytics function.
Future<List<T>> _loadMatrixAnalytics<T>(
  Ref ref,
  String userId,
  MatrixType matrixType,
  List<T> Function(List<MatrixRunWithDetails>, {required bool weighted})
      analyticsFunc,
) async {
  final runsAsync = ref.watch(matrixRunsProvider(userId));
  final weighted = ref.watch(analyticsWeightedProvider);

  return runsAsync.when(
    data: (runs) async {
      final filtered =
          runs.where((r) => r.matrixType == matrixType).toList();
      if (filtered.isEmpty) return [];

      final details = <MatrixRunWithDetails>[];
      final repo = ref.read(matrixRepositoryProvider);
      for (final run in filtered) {
        final d = await repo.getMatrixRunWithDetails(run.matrixRunId);
        if (d != null) details.add(d);
      }

      return analyticsFunc(details, weighted: weighted);
    },
    loading: () => <T>[],
    error: (e, s) => <T>[],
  );
}

/// Club distance analytics for all gapping runs (§9.6).
final clubDistanceAnalyticsProvider = FutureProvider.family<
    List<ClubDistanceResult>, String>((ref, userId) =>
    _loadMatrixAnalytics(ref, userId, MatrixType.gappingChart,
        clubDistanceAnalytics));

/// Wedge coverage analytics for all wedge runs (§9.7).
final wedgeCoverageAnalyticsProvider = FutureProvider.family<
    List<WedgeCoverageResult>, String>((ref, userId) =>
    _loadMatrixAnalytics(ref, userId, MatrixType.wedgeMatrix,
        wedgeCoverageAnalytics));

/// Chipping accuracy analytics for all chipping runs (§9.8).
final chippingAccuracyAnalyticsProvider = FutureProvider.family<
    List<ChippingAccuracyResult>, String>((ref, userId) =>
    _loadMatrixAnalytics(ref, userId, MatrixType.chippingMatrix,
        chippingAccuracyAnalytics));

/// Distance trend for a specific cell across runs (§9.9).
final distanceTrendProvider = FutureProvider.family<List<TrendPoint>,
    ({String userId, MatrixType matrixType, String cellKey})>(
    (ref, params) async {
  final runsAsync = ref.watch(matrixRunsProvider(params.userId));
  final weighted = ref.watch(analyticsWeightedProvider);

  return runsAsync.when(
    data: (runs) async {
      final filtered = runs
          .where((r) => r.matrixType == params.matrixType)
          .toList();

      if (filtered.isEmpty) return [];

      final details = <MatrixRunWithDetails>[];
      final repo = ref.read(matrixRepositoryProvider);
      for (final run in filtered) {
        final d = await repo.getMatrixRunWithDetails(run.matrixRunId);
        if (d != null) details.add(d);
      }

      return distanceTrend(details, params.cellKey, weighted: weighted);
    },
    loading: () => <TrendPoint>[],
    error: (e, s) => <TrendPoint>[],
  );
});

/// Gapping insights (§9.10.3).
final gappingInsightsProvider =
    FutureProvider.family<List<Insight>, String>((ref, userId) async {
  final results = await ref.watch(clubDistanceAnalyticsProvider(userId).future);
  return generateGappingInsights(results);
});

/// Wedge insights (§9.10.3).
final wedgeInsightsProvider =
    FutureProvider.family<List<Insight>, String>((ref, userId) async {
  final results =
      await ref.watch(wedgeCoverageAnalyticsProvider(userId).future);
  return generateWedgeInsights(results);
});

/// Chipping insights (§9.10.3).
final chippingInsightsProvider =
    FutureProvider.family<List<Insight>, String>((ref, userId) async {
  final results =
      await ref.watch(chippingAccuracyAnalyticsProvider(userId).future);
  return generateChippingInsights(results);
});
