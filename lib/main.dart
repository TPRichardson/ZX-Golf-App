import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/zx_theme.dart';
import 'features/shell/shell_screen.dart';

// TD-07 §3.3 — Top-level error handlers.
void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

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
