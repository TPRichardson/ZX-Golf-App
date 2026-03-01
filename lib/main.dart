import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/zx_theme.dart';
import 'features/shell/shell_screen.dart';

// TD-07 §3.3 — Top-level error handlers.
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // TD-03 §5 — Supabase initialisation using compile-time env vars.
      await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL'),
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
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
      home: const ShellScreen(),
    );
  }
}
