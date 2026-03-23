// Unified execution screen — input delegate interface.
// Each InputMode provides a delegate that renders the center input area
// and communicates instance data back to the host ExecutionScreen.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

/// Data passed from the host ExecutionScreen to delegates on every build.
class ExecutionContext {
  final bool isLocked;
  final bool isEnding;
  /// Selected club ID (UUID). Null for technique blocks.
  final String? selectedClub;
  final String? currentSetId;
  /// Player-declared shot shape intent (Fade/Draw/Straight). Nullable.
  final String? shotShape;
  /// Player-declared effort percentage (100/90/75). Nullable.
  final int? shotEffort;
  /// Resolved target values for storage on Instance.
  final double? resolvedTargetDistance;
  final double? resolvedTargetWidth;
  final double? resolvedTargetDepth;

  const ExecutionContext({
    required this.isLocked,
    required this.isEnding,
    required this.selectedClub,
    required this.currentSetId,
    this.shotShape,
    this.shotEffort,
    this.resolvedTargetDistance,
    this.resolvedTargetWidth,
    this.resolvedTargetDepth,
  });
}

/// Callback to log a single instance. Host handles haptics, club rotation,
/// timer reset, setState, and set auto-advance.
typedef LogInstanceCallback = Future<InstanceResult> Function(
    InstancesCompanion data);

/// Abstract interface for input-mode-specific widgets.
abstract class ExecutionInputDelegate {
  /// Build the center input area.
  Widget buildInputArea({
    required BuildContext context,
    required ExecutionContext executionContext,
    required LogInstanceCallback onLogInstance,
    required VoidCallback requestRebuild,
  });

  /// Called after the host logs an instance. Update local display state.
  void onInstanceLogged(InstanceResult result, InstancesCompanion data) {}

  /// Called after the host undoes an instance. Update local counters.
  void onInstanceUndone(Instance? deleted) {}

  /// Override to supply a per-instance target distance for display in the
  /// distance box. Return null to use the default distance logic.
  double? get currentTargetDistance => null;

  /// Optional status line shown between the shot log and input area.
  /// Return null to hide. Used by scoring game for hole/category/par info.
  String? get statusLine => null;

  /// Optional trailing widget for the status line row (e.g. score chip).
  Widget? get statusTrailing => null;

  /// Cleanup (e.g. dispose TextEditingControllers).
  void dispose() {}
}
