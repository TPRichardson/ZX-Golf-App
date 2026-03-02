// Phase 4 — Practice Router.
// S14 §14.3 — Routes InputMode → execution screen.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

import 'screens/binary_hit_miss_screen.dart';
import 'screens/continuous_measurement_screen.dart';
import 'screens/grid_cell_screen.dart';
import 'screens/raw_data_entry_screen.dart';
import 'screens/technique_block_screen.dart';

/// S14 §14.3 — Map InputMode + DrillType to the correct execution screen.
class PracticeRouter {
  /// Returns the appropriate execution screen widget for a drill.
  static Widget routeToExecutionScreen({
    required Drill drill,
    required Session session,
    required String userId,
  }) {
    // Technique blocks always route to technique screen.
    if (drill.drillType == DrillType.techniqueBlock) {
      return TechniqueBlockScreen(drill: drill, session: session, userId: userId);
    }

    // Route by InputMode.
    switch (drill.inputMode) {
      case InputMode.gridCell:
        return GridCellScreen(drill: drill, session: session, userId: userId);
      case InputMode.continuousMeasurement:
        return ContinuousMeasurementScreen(
            drill: drill, session: session, userId: userId);
      case InputMode.rawDataEntry:
        return RawDataEntryScreen(
            drill: drill, session: session, userId: userId);
      case InputMode.binaryHitMiss:
        return BinaryHitMissScreen(
            drill: drill, session: session, userId: userId);
    }
  }
}
