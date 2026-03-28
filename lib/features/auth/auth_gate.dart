import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/auth/post_login_sync_screen.dart';
import 'package:zx_golf_app/features/auth/sign_in_screen.dart';
import 'package:zx_golf_app/features/shell/shell_screen.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';

// TD-07 §9 — Auth gate: routes to SignInScreen or ShellScreen based on auth state.

/// Tracks whether the current session came from a fresh login (vs app reopen).
/// Set true on signedIn event, cleared after the sync screen completes.
final _freshLoginProvider = StateProvider<bool>((ref) => false);

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  Widget build(BuildContext context) {
    // Dev-only: bypass auth on desktop when DEV_BYPASS_AUTH=true in .env.
    if (kDebugMode && dotenv.env['DEV_BYPASS_AUTH'] == 'true') {
      final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS;
      if (isDesktop) {
        return const ShellScreen();
      }
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const SignInScreen();
        }

        // Detect fresh sign-in (not app reopen with existing session).
        if (state.event == AuthChangeEvent.signedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(_freshLoginProvider.notifier).state = true;
            }
          });
        }

        final isFreshLogin = ref.watch(_freshLoginProvider);
        if (isFreshLogin) {
          return PostLoginSyncScreen(
            onComplete: () {
              ref.read(_freshLoginProvider.notifier).state = false;
            },
          );
        }

        return const ShellScreen();
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
