// Phase 3 — Drill domain Riverpod providers.
// TD-03 §3.1 — Reactive providers for drill browsing and Active Drills.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/dto/drill_dto.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';

import 'database_providers.dart';
import 'repository_providers.dart';

/// Local standard drills (for contexts needing offline-available adopted copies).
final standardDrillsProvider = StreamProvider<List<Drill>>((ref) {
  return ref.watch(drillRepositoryProvider).watchStandardDrills();
});

/// Server-authoritative standard drill catalogue (live Supabase query).
/// Returns empty list on network error (offline empty state).
final standardDrillCatalogueProvider = FutureProvider<List<Drill>>((ref) async {
  try {
    final supabase = ref.watch(supabaseClientProvider);
    final rows = await supabase
        .from('Drill')
        .select()
        .eq('Origin', 'System')
        .eq('IsDeleted', false);
    return (rows as List)
        .map((row) {
          final json = Map<String, dynamic>.from(row as Map);
          final companion = drillFromSyncDto(json);
          // Convert DrillsCompanion to Drill data object.
          return Drill(
            drillId: companion.drillId.value,
            userId: companion.userId.value,
            name: companion.name.value,
            skillArea: companion.skillArea.value,
            drillType: companion.drillType.value,
            scoringMode: companion.scoringMode.value,
            inputMode: companion.inputMode.value,
            metricSchemaId: companion.metricSchemaId.value,
            gridType: companion.gridType.value,
            subskillMapping: companion.subskillMapping.value,
            clubSelectionMode: companion.clubSelectionMode.value,
            targetDistanceMode: companion.targetDistanceMode.value,
            targetDistanceValue: companion.targetDistanceValue.value,
            targetSizeMode: companion.targetSizeMode.value,
            targetSizeWidth: companion.targetSizeWidth.value,
            targetSizeDepth: companion.targetSizeDepth.value,
            requiredSetCount: companion.requiredSetCount.value,
            requiredAttemptsPerSet: companion.requiredAttemptsPerSet.value,
            anchors: companion.anchors.value,
            target: companion.target.value,
            description: companion.description.value,
            targetDistanceUnit: companion.targetDistanceUnit.value,
            targetSizeUnit: companion.targetSizeUnit.value,
            requiredEquipment: companion.requiredEquipment.value,
            recommendedEquipment: companion.recommendedEquipment.value,
            origin: companion.origin.value,
            status: companion.status.value,
            windowCap: companion.windowCap.value,
            isDeleted: companion.isDeleted.value,
            createdAt: companion.createdAt.value,
            updatedAt: companion.updatedAt.value,
          );
        })
        .toList();
  } catch (e, st) {
    // Offline or network error — return empty catalogue.
    // ignore: avoid_print
    print('[StandardDrillCatalogue] Error fetching drills: $e\n$st');
    return <Drill>[];
  }
});

/// Adopted standard drills for a user.
final adoptedDrillsProvider =
    StreamProvider.family<List<DrillWithAdoption>, String>((ref, userId) {
  return ref.watch(drillRepositoryProvider).watchAdoptedDrills(userId);
});

/// Active Drills: adopted standard drills + active custom drills.
final activeDrillsProvider =
    StreamProvider.family<List<DrillWithAdoption>, String>((ref, userId) {
  return ref.watch(drillRepositoryProvider).watchActiveDrills(userId);
});
