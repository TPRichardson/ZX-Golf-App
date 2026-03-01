import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zx_golf_app/core/error_types.dart';

// TD-03 §5 — Thin wrapper around Supabase Auth.
// No abstract interface per CLAUDE.md "No invented architecture" rule.

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Current authenticated user ID, or null if not signed in.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// TD-03 §5 — Sign in with Google OAuth.
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.zxgolfapp://login-callback/',
      );
    } on AuthException catch (e) {
      throw AuthenticationException(
        code: AuthenticationException.refreshFailed,
        message: 'Google sign-in failed: ${e.message}',
        context: {'statusCode': e.statusCode},
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthenticationException(
        code: AuthenticationException.sessionRevoked,
        message: 'Sign-out failed: ${e.message}',
      );
    }
  }

  /// TD-07 §9 — Stream of auth state changes.
  Stream<AuthState> watchAuthState() {
    return _client.auth.onAuthStateChange;
  }
}
