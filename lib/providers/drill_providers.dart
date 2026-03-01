// Phase 3 — Drill domain Riverpod providers.
// TD-03 §3.1 — Reactive providers for drill browsing and Practice Pool.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';

import 'repository_providers.dart';

/// System drills (28 seeded drills, no userId filter needed).
final systemDrillsProvider = StreamProvider<List<Drill>>((ref) {
  return ref.watch(drillRepositoryProvider).watchSystemDrills();
});

/// Adopted system drills for a user.
final adoptedDrillsProvider =
    StreamProvider.family<List<DrillWithAdoption>, String>((ref, userId) {
  return ref.watch(drillRepositoryProvider).watchAdoptedDrills(userId);
});

/// Practice Pool: adopted system drills + active custom drills.
final practicePoolProvider =
    StreamProvider.family<List<DrillWithAdoption>, String>((ref, userId) {
  return ref.watch(drillRepositoryProvider).watchPracticePool(userId);
});
