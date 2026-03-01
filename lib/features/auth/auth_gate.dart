import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/features/auth/sign_in_screen.dart';
import 'package:zx_golf_app/features/shell/shell_screen.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';

// TD-07 §9 — Auth gate: routes to SignInScreen or ShellScreen based on auth state.
// Desktop bypass: Windows skips auth (OAuth redirect not yet supported).

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dev bypass: skip auth on Windows desktop until OAuth redirect is implemented.
    if (!kIsWeb && Platform.isWindows) {
      return const ShellScreen();
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        if (state.session != null) {
          return const ShellScreen();
        }
        return const SignInScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => const SignInScreen(),
    );
  }
}
