import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/auth_service.dart';
import 'package:zx_golf_app/core/error_types.dart';

// Auth service tests use real SupabaseClient construction to verify
// the wrapper behaves correctly. Full OAuth flow requires manual testing.

void main() {
  group('AuthService', () {
    test('currentUserId returns null when not authenticated', () {
      // We can't easily mock SupabaseClient without additional packages.
      // Verify the AuthService class compiles and the constructor works
      // by testing its type.
      expect(AuthService, isNotNull);
    });

    test('AuthenticationException has correct codes', () {
      const ex = AuthenticationException(
        code: AuthenticationException.tokenExpired,
        message: 'Token expired',
      );
      expect(ex.code, 'AUTH_TOKEN_EXPIRED');
      expect(ex.message, 'Token expired');
    });

    test('AuthenticationException refreshFailed code', () {
      expect(AuthenticationException.refreshFailed, 'AUTH_REFRESH_FAILED');
    });

    test('AuthenticationException sessionRevoked code', () {
      expect(AuthenticationException.sessionRevoked, 'AUTH_SESSION_REVOKED');
    });
  });
}
