import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/planning/screens/routine_apply_screen.dart';
import 'package:zx_golf_app/features/planning/screens/schedule_apply_screen.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';

// Shared routine/schedule picker sheets used by CalendarScreen
// and CalendarDayDetailScreen (S08 §8.12.1, §8.12.2).

/// Show a bottom sheet listing active routines. On selection, navigates to
/// RoutineApplyScreen. [onApplied] is called when the apply screen pops.
void showRoutinePickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required DateTime date,
  VoidCallback? onApplied,
}) {
  final routinesAsync = ref.read(routinesProvider(userId));
  final routines = routinesAsync.valueOrNull ?? [];

  if (routines.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No active routines')),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: ColorTokens.surfaceModal,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
          top: Radius.circular(ShapeTokens.radiusModal)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                SpacingTokens.md, SpacingTokens.md, SpacingTokens.md, SpacingTokens.sm),
            child: Text(
              'Apply routine',
              style: TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
          ),
          for (final routine in routines)
            ListTile(
              leading: const Icon(Icons.playlist_play,
                  color: ColorTokens.primaryDefault),
              title: Text(routine.name),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RoutineApplyScreen(
                    routineId: routine.routineId,
                    targetDate: date,
                  ),
                )).then((_) => onApplied?.call());
              },
            ),
        ],
      ),
    ),
  );
}

/// Show a bottom sheet listing active schedules. On selection, navigates to
/// ScheduleApplyScreen. [onApplied] is called when the apply screen pops.
void showSchedulePickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required DateTime date,
  VoidCallback? onApplied,
}) {
  final schedulesAsync = ref.read(schedulesProvider(userId));
  final schedules = schedulesAsync.valueOrNull ?? [];

  if (schedules.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No active schedules')),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: ColorTokens.surfaceModal,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
          top: Radius.circular(ShapeTokens.radiusModal)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                SpacingTokens.md, SpacingTokens.md, SpacingTokens.md, SpacingTokens.sm),
            child: Text(
              'Apply schedule',
              style: TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
          ),
          for (final schedule in schedules)
            ListTile(
              leading: const Icon(Icons.date_range,
                  color: ColorTokens.primaryDefault),
              title: Text(schedule.name),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ScheduleApplyScreen(
                    scheduleId: schedule.scheduleId,
                    startDate: date,
                  ),
                )).then((_) => onApplied?.call());
              },
            ),
        ],
      ),
    ),
  );
}
