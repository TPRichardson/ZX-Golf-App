import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/models/user_preferences.dart';
import 'repository_providers.dart';
import 'sync_providers.dart';

// S10 — Settings providers for user preferences.

/// Current user ID — auth user ID when authenticated, dev fallback otherwise.
final currentUserIdProvider = Provider<String>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserId ?? kDevUserId;
});

/// S10 §10.1 — Current authenticated user record.
/// Creates a dev user row if none exists (dev bypass mode).
final currentUserProvider = FutureProvider<User?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.watch(userRepositoryProvider);
  final existing = await repo.getById(userId);
  if (existing != null) return existing;
  // Dev bypass: create a local-only user row so preferences can be saved.
  if (userId == kDevUserId) {
    return repo.create(UsersCompanion.insert(
      userId: kDevUserId,
      email: 'a@b.com',
      displayName: const Value('Testing'),
      timezone: const Value('UTC'),
    ));
  }
  return null;
});

/// Auth profile from Supabase — display name, email, avatar from Google OAuth.
final authProfileProvider = Provider<({String? displayName, String? email, String? avatarUrl})>((ref) {
  ref.watch(authStateProvider); // Re-evaluate on auth changes.
  final user = sb.Supabase.instance.client.auth.currentUser;
  final meta = user?.userMetadata ?? {};
  // Google OAuth may use 'full_name', 'name', or identity-level data.
  final name = (meta['full_name'] ?? meta['name']) as String?;
  final avatar = (meta['avatar_url'] ?? meta['picture']) as String?;
  return (
    displayName: name,
    email: user?.email,
    avatarUrl: avatar,
  );
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
/// Writes to local DB immediately (offline-first). Sync uploads later.
Future<void> updatePreferences(
  WidgetRef ref,
  UserPreferences prefs,
) async {
  // Ensure user record exists (auto-creates if needed).
  await ref.read(currentUserProvider.future);
  final userId = ref.read(currentUserIdProvider);
  await ref.read(userRepositoryProvider).update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );
  ref.invalidate(currentUserProvider);
}
