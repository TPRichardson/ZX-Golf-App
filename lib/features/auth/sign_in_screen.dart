import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/features/auth/auth_gate.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';

// TD-07 §9 — Sign-in screen shown when user is not authenticated.

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _loading = false;
  String? _error;

  void _bypassLogin() {
    ref.read(guestModeProvider.notifier).state = true;
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ZX Golf',
                style: TextStyle(
                  color: ColorTokens.textPrimary,
                  fontSize: TypographyTokens.displayXlSize,
                  fontWeight: TypographyTokens.displayXlWeight,
                  height: TypographyTokens.displayXlHeight,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Practice performance tracking',
                style: TextStyle(
                  color: ColorTokens.textSecondary,
                  fontSize: TypographyTokens.bodyLgSize,
                  fontWeight: TypographyTokens.bodyWeight,
                  height: TypographyTokens.bodyLgHeight,
                ),
              ),
              const SizedBox(height: SpacingTokens.xxl),
              ZxPillButton(
                label: _loading ? 'Signing in...' : 'Sign in with Google',
                icon: Icons.login,
                variant: ZxPillVariant.primary,
                expanded: true,
                centered: true,
                isLoading: _loading,
                onTap: _loading ? null : _signInWithGoogle,
              ),
              const SizedBox(height: SpacingTokens.md),
              ZxPillButton(
                label: 'Continue without account',
                icon: Icons.person_outline,
                variant: ZxPillVariant.secondary,
                expanded: true,
                centered: true,
                onTap: _loading ? null : _bypassLogin,
              ),
              if (_error != null) ...[
                const SizedBox(height: SpacingTokens.md),
                Text(
                  _error!,
                  style: TextStyle(
                    color: ColorTokens.errorDestructive,
                    fontSize: TypographyTokens.bodySize,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
