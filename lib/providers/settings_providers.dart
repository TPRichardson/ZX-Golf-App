import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/models/user_preferences.dart';
import 'repository_providers.dart';
import 'sync_providers.dart';

// S10 — Settings providers for user preferences.

/// S10 §10.1 — Current authenticated user record.
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUserId;
  if (userId == null) return null;
  return ref.watch(userRepositoryProvider).getById(userId);
});

/// S10 §10.6 — Parsed user preferences from Users.unitPreferences JSON.
final userPreferencesProvider = Provider<UserPreferences>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return const UserPreferences();
      return UserPreferences.fromJson(user.unitPreferences);
    },
    loading: () => const UserPreferences(),
    error: (_, _) => const UserPreferences(),
  );
});

/// S10 §10.2 — Save updated preferences to the user record.
Future<void> updatePreferences(
  WidgetRef ref,
  UserPreferences prefs,
) async {
  final authService = ref.read(authServiceProvider);
  final userId = authService.currentUserId;
  if (userId == null) return;
  await ref.read(userRepositoryProvider).update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );
  ref.invalidate(currentUserProvider);
}
