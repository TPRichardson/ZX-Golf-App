import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/features/shell/shell_screen.dart';

// TD-07 §9 — Auth gate: routes to SignInScreen or ShellScreen based on auth state.
// TEMPORARY: Auth bypass on all platforms until Google OAuth redirect is resolved.

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Temporary bypass: skip auth on all platforms.
    // TODO: restore auth gate when Google OAuth redirect_uri_mismatch is resolved.
    return const ShellScreen();
  }
}
