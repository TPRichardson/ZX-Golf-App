import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/screens/post_session_summary_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// Shared helpers for execution screens.

/// End the current session: close via PracticeActions, fetch updated session,
/// navigate to PostSessionSummaryScreen.
Future<void> endSessionAndNavigate(
  BuildContext context,
  WidgetRef ref, {
  required Session session,
  required Drill drill,
  required String userId,
  String? practiceBlockId,
}) async {
  final actions = ref.read(practiceActionsProvider);
  final result = await actions.endSession(session.sessionId, userId);

  if (!context.mounted) return;

  final closedSession =
      await ref.read(practiceRepositoryProvider).getSessionById(session.sessionId);

  if (!context.mounted) return;

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => PostSessionSummaryScreen(
        drill: drill,
        session: closedSession ?? session,
        sessionScore: result.sessionScore,
        integrityBreach: result.integrityBreach,
        practiceBlockId: practiceBlockId,
        userId: userId,
      ),
    ),
  );
}

/// Show environment/surface picker and update the session surface.
/// Returns the new surface type, or null if cancelled.
Future<SurfaceType?> changeSurface(
  BuildContext context,
  WidgetRef ref, {
  required String sessionId,
}) async {
  final result = await showEnvironmentSurfacePicker(context);
  if (result != null && context.mounted) {
    await ref
        .read(practiceRepositoryProvider)
        .updateSessionSurface(sessionId, result.surface);
  }
  return result?.surface;
}
