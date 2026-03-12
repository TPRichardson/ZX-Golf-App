import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// S08 §8.2.1 — Routine apply screen: preview resolved drills → confirm/reroll.

class RoutineApplyScreen extends ConsumerStatefulWidget {
  final String routineId;
  final DateTime? targetDate;

  const RoutineApplyScreen({
    super.key,
    required this.routineId,
    this.targetDate,
  });

  @override
  ConsumerState<RoutineApplyScreen> createState() =>
      _RoutineApplyScreenState();
}

class _RoutineApplyScreenState extends ConsumerState<RoutineApplyScreen> {
  static const _userId = kDevUserId;

  Routine? _routine;
  List<RoutineEntry> _entries = [];
  CalendarDay? _targetDay;
  List<String> _resolvedDrillIds = [];
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(planningRepositoryProvider);
    final routine = await repo.getRoutineById(widget.routineId);
    if (routine == null || !mounted) return;

    final target = widget.targetDate ?? DateTime.now();
    final targetDate = DateTime(target.year, target.month, target.day);
    final day = await repo.getOrCreateCalendarDay(_userId, targetDate);

    final entries = _parseEntries(routine.entries);

    // S08 §8.2.1 — Preview: resolve entries to drill IDs.
    // For fixed entries, use the drillId directly.
    // For criterion entries, use placeholder (weakness engine integration).
    final resolved = <String>[];
    for (final entry in entries) {
      if (entry.type == RoutineEntryType.fixed && entry.drillId != null) {
        resolved.add(entry.drillId!);
      } else {
        // Phase 5 stub: criterion entries get a placeholder.
        // Full integration uses WeaknessDetectionEngine.
        resolved.add('generated-${resolved.length}');
      }
    }

    setState(() {
      _routine = routine;
      _entries = entries;
      _targetDay = day;
      _resolvedDrillIds = resolved;
    });
  }

  List<RoutineEntry> _parseEntries(String json) {
    try {
      return (jsonDecode(json) as List<dynamic>)
          .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_routine == null || _targetDay == null) {
      return Scaffold(
        appBar: const ZxAppBar(title: 'Apply Routine'),
        body: const Center(
          child:
              CircularProgressIndicator(color: ColorTokens.primaryDefault),
        ),
      );
    }

    return Scaffold(
      appBar: ZxAppBar(
        title: 'Apply: ${_routine!.name}',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(SpacingTokens.md),
              children: [
                // Target day info.
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: ColorTokens.surfaceRaised,
                    borderRadius:
                        BorderRadius.circular(ShapeTokens.radiusCard),
                    border:
                        Border.all(color: ColorTokens.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: ColorTokens.primaryDefault, size: 20),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        '${_formatDate(_targetDay!.date)} — ${_targetDay!.slotCapacity} slots',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SpacingTokens.lg),

                // Preview heading.
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),

                // Resolved drill list.
                for (var i = 0; i < _resolvedDrillIds.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.sm),
                    decoration: BoxDecoration(
                      color: ColorTokens.surfaceRaised,
                      borderRadius:
                          BorderRadius.circular(ShapeTokens.radiusCard),
                      border:
                          Border.all(color: ColorTokens.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ColorTokens.primaryDefault
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: TypographyTokens.bodySmSize,
                              color: ColorTokens.primaryDefault,
                            ),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: Text(
                            _resolvedDrillIds[i],
                            style: TextStyle(
                              fontSize: TypographyTokens.bodySize,
                              color: ColorTokens.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          _entries[i].type == RoutineEntryType.fixed
                              ? Icons.sports_golf
                              : Icons.auto_awesome,
                          size: 16,
                          color: ColorTokens.textTertiary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                ],
              ],
            ),
          ),

          // Bottom action bar.
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: ColorTokens.surfacePrimary,
              border: const Border(
                top: BorderSide(color: ColorTokens.surfaceBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _applying ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.textSecondary,
                      side: const BorderSide(
                          color: ColorTokens.surfaceBorder),
                    ),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _applying ? null : _reroll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.primaryDefault,
                      side: const BorderSide(
                          color: ColorTokens.primaryDefault),
                    ),
                    child: const Text('Reroll'),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _applying ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorTokens.primaryDefault,
                    ),
                    child: _applying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorTokens.textPrimary,
                            ),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      formatDate(date, includeWeekday: true);

  void _reroll() {
    // S08 §8.2.1 — Re-resolve criterion entries.
    _load();
  }

  Future<void> _confirm() async {
    setState(() => _applying = true);
    try {
      final actions = ref.read(planningActionsProvider);
      await actions.applyRoutine(
        _userId,
        widget.routineId,
        _targetDay!.date,
        _resolvedDrillIds,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _applying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
