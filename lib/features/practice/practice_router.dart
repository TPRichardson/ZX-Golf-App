// Phase 4 — Practice Router.
// S14 §14.3 — Routes InputMode → execution screen.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

import 'screens/execution_screen.dart';
import 'screens/technique_block_screen.dart';

/// S14 §14.3 — Map InputMode + DrillType to the correct execution screen.
class PracticeRouter {
  /// Returns the appropriate execution screen widget for a drill.
  static Widget routeToExecutionScreen({
    required Drill drill,
    required Session session,
    required String userId,
  }) {
    // Technique blocks always route to technique screen (timer-based).
    if (drill.drillType == DrillType.techniqueBlock) {
      return TechniqueBlockScreen(drill: drill, session: session, userId: userId);
    }

    // All instance-recording modes use the unified execution screen.
    return ExecutionScreen(drill: drill, session: session, userId: userId);
  }
}
