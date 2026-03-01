import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/zx_theme.dart';
import 'features/auth/auth_gate.dart';

// TD-07 §3.3 — Top-level error handlers.
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment credentials from .env (gitignored).
      await dotenv.load();

      // TD-03 §5 — Supabase initialisation from .env credentials.
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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

class ZxGolfApp extends StatelessWidget {
  const ZxGolfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZX Golf',
      debugShowCheckedModeBanner: false,
      theme: ZxTheme.dark(),
      home: const AuthGate(),
    );
  }
}
