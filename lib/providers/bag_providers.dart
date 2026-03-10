// Phase 3 — Bag domain Riverpod providers.
// TD-03 §3.1 — Reactive providers for golf bag and skill area mappings.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

import 'repository_providers.dart';

/// Active clubs in user's bag.
final userBagProvider =
    StreamProvider.family<List<UserClub>, String>((ref, userId) {
  return ref.watch(clubRepositoryProvider).watchUserBag(
        userId,
        status: UserClubStatus.active,
      );
});

/// Clubs mapped to a specific skill area for a user.
final clubsForSkillAreaProvider =
    StreamProvider.family<List<UserClub>, (String, SkillArea)>((ref, params) {
  final (userId, skillArea) = params;
  return ref.watch(clubRepositoryProvider).watchClubsForSkillArea(
        userId,
        skillArea,
      );
});

/// Active performance profile for a club (latest by effective date).
final activeProfileProvider =
    FutureProvider.family<ClubPerformanceProfile?, String>((ref, clubId) {
  return ref.watch(clubRepositoryProvider).getActiveProfile(clubId);
});

/// All skill area mappings for a user.
final skillAreaMappingsProvider =
    StreamProvider.family<List<UserSkillAreaClubMapping>, String>(
        (ref, userId) {
  return ref.watch(clubRepositoryProvider).watchMappingsByUser(userId);
});

/// Skill areas mapped to a specific club type for a user.
final skillAreasForClubProvider = Provider.family<List<SkillArea>,
    (String userId, ClubType clubType)>((ref, params) {
  final (userId, clubType) = params;
  final mappings = ref.watch(skillAreaMappingsProvider(userId)).valueOrNull ?? [];
  return mappings
      .where((m) => m.clubType == clubType)
      .map((m) => m.skillArea)
      .toList();
});
