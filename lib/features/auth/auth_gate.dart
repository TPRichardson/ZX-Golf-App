import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/auth/sign_in_screen.dart';
import 'package:zx_golf_app/features/shell/shell_screen.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';

// TD-07 §9 — Auth gate: routes to SignInScreen or ShellScreen based on auth state.

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const ShellScreen();
        }
        return const SignInScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: ColorTokens.surfaceBase,
        body: Center(
          child: CircularProgressIndicator(
            color: ColorTokens.primaryDefault,
          ),
        ),
      ),
      error: (_, _) => const SignInScreen(),
    );
  }
}
