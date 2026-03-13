// Phase 3 — Drill domain Riverpod providers.
// TD-03 §3.1 — Reactive providers for drill browsing and Active Drills.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';

import 'repository_providers.dart';

/// Standard drills (28 seeded drills, no userId filter needed).
final standardDrillsProvider = StreamProvider<List<Drill>>((ref) {
  return ref.watch(drillRepositoryProvider).watchStandardDrills();
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
