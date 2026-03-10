import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/startup_checks.dart';
import 'core/theme/zx_theme.dart';
import 'features/auth/auth_gate.dart';
import 'providers/database_providers.dart';
import 'providers/repository_providers.dart';
import 'providers/scoring_providers.dart';
import 'providers/sync_providers.dart';

// TD-07 §3.3 — Top-level error handlers.
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // S12 §12.1 — Portrait-only orientation.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Load environment credentials from .env (gitignored).
      await dotenv.load();

      // TD-03 §5 — Supabase initialisation from .env credentials.
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      // TD-07 §3.3 — Flutter framework error handler.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('[ZxGolfApp] FlutterError: ${details.exception}');
      };

      runApp(
        const ProviderScope(
          child: ZxGolfApp(),
        ),
      );
    },
    // TD-07 §3.3 — Dart Zone error handler. Graceful degradation.
    (error, stack) {
      debugPrint('[ZxGolfApp] Unhandled error: $error');
      debugPrint('[ZxGolfApp] Stack: $stack');
    },
  );
}

class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class ZxGolfApp extends ConsumerStatefulWidget {
  const ZxGolfApp({super.key});

  @override
  ConsumerState<ZxGolfApp> createState() => _ZxGolfAppState();
}

class _ZxGolfAppState extends ConsumerState<ZxGolfApp> {
  @override
  void initState() {
    super.initState();
    // TD-07 §13.6 — Run startup integrity checks after database initializes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupChecks();
    });
  }

  Future<void> _runStartupChecks() async {
    try {
      final checks = StartupChecks(
        ref.read(databaseProvider),
        ref.read(scoringRepositoryProvider),
        ref.read(reflowEngineProvider),
      );
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUserId;
      if (userId != null) {
        await checks.runAll(userId);
      }
    } catch (e) {
      debugPrint('[ZxGolfApp] Startup checks failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZX Golf',
      debugShowCheckedModeBanner: false,
      theme: ZxTheme.dark(),
      scrollBehavior: const _NoOverscrollBehavior(),
      home: const AuthGate(),
    );
  }
}
