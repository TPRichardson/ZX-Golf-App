import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/core/widgets/detail_row.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/practice_router.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// Phase 3 — Drill detail screen. View drill properties and anchors (read-only).
// Anchors are system-defined and not user-editable.

class DrillDetailScreen extends ConsumerStatefulWidget {
  final String drillId;
  final bool isCustom;

  const DrillDetailScreen({
    super.key,
    required this.drillId,
    required this.isCustom,
  });

  @override
  ConsumerState<DrillDetailScreen> createState() => _DrillDetailScreenState();
}

class _DrillDetailScreenState extends ConsumerState<DrillDetailScreen> {
  Drill? _drill;
  bool _isLoading = true;
  bool _isAdopted = false;
  Map<String, ({double min, double scratch, double pro})> _anchors = {};

  @override
  void initState() {
    super.initState();
    _loadDrill();
  }

  Future<void> _loadDrill() async {
    final drillRepo = ref.read(drillRepositoryProvider);
    final drill = await drillRepo.getById(widget.drillId);
    if (mounted) {
      setState(() {
        _drill = drill;
        _isLoading = false;
        if (drill != null) {
          _anchors = _parseAnchors(drill.anchors);
        }
      });
      // Check adoption status and clear unseen update badge.
      if (drill != null && drill.origin == DrillOrigin.standard) {
        final userId = ref.read(currentUserIdProvider);
        final adoption =
            await drillRepo.getAdoption(userId, widget.drillId);
        if (mounted) {
          setState(() => _isAdopted = adoption != null);
        }
        try {
          await drillRepo.markUpdateSeen(userId, widget.drillId);
        } catch (_) {
          // Non-critical — badge will clear on next open.
        }
      }
    }
  }

  static Map<String, ({double min, double scratch, double pro})> _parseAnchors(
      String anchorsJson) {
    if (anchorsJson == '{}' || anchorsJson.isEmpty) return {};
    final map = jsonDecode(anchorsJson) as Map<String, dynamic>;
    final result = <String, ({double min, double scratch, double pro})>{};
    for (final entry in map.entries) {
      final a = entry.value as Map<String, dynamic>;
      result[entry.key] = (
        min: (a['Min'] as num).toDouble(),
        scratch: (a['Scratch'] as num).toDouble(),
        pro: (a['Pro'] as num).toDouble(),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const ZxAppBar(title: 'Drill'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_drill == null) {
      return Scaffold(
        appBar: const ZxAppBar(title: 'Drill'),
        body: const Center(child: Text('Drill not found')),
      );
    }

    final drill = _drill!;
    final isStandard = drill.origin == DrillOrigin.standard;
    final isScored = drill.drillType != DrillType.techniqueBlock;

    return Scaffold(
      appBar: ZxAppBar(
        title: drill.name,
        actions: [
          if (widget.isCustom)
            PopupMenuButton<String>(
              onSelected: _handleAction,
              itemBuilder: (_) => [
                if (drill.status == DrillStatus.active)
                  const PopupMenuItem(
                    value: 'retire',
                    child: Text('Retire Drill'),
                  ),
                if (drill.status == DrillStatus.retired)
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reactivate Drill'),
                  ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Text('Duplicate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          // Status badge.
          DetailRow(label: 'Status', value: drill.status.dbValue),
          DetailRow(label: 'Skill Area', value: drill.skillArea.dbValue),
          DetailRow(label: 'Drill Type', value: _drillTypeLabel(drill.drillType)),
          DetailRow(label: 'Input Mode', value: drill.inputMode.dbValue),
          DetailRow(label: 'Origin', value: drill.origin.dbValue),
          if (drill.requiredAttemptsPerSet != null)
            DetailRow(
              label: 'Attempts/Set',
              value: '${drill.requiredAttemptsPerSet}',
            ),
          DetailRow(
            label: 'Set Count',
            value: '${drill.requiredSetCount}',
          ),
          if (drill.clubSelectionMode != null)
            DetailRow(
              label: 'Club Selection',
              value: drill.clubSelectionMode!.dbValue,
            ),
          if (drill.description != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: ColorTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                border: Border.all(color: ColorTokens.surfaceBorder),
              ),
              child: Text(
                drill.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorTokens.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
          ],
          if (drill.targetDistanceMode != null)
            DetailRow(
              label: 'Target Distance',
              value: _formatTargetValue(
                  drill.targetDistanceValue, drill.targetDistanceUnit),
            ),
          if (drill.targetSizeWidth != null)
            DetailRow(
              label: 'Target Width',
              value: _formatTargetValue(
                  drill.targetSizeWidth, drill.targetSizeUnit),
            ),

          // Recommended equipment section — informational only.
          if (_recommendedEquipment(drill).isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.sm),
            DetailRow(
              label: 'Recommended',
              value: _recommendedEquipment(drill),
            ),
          ],

          // Anchors section — system drills, read-only display.
          if (isStandard && isScored) ...[
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'Scoring Anchors',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ColorTokens.textPrimary,
                  ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            for (final entry in _anchors.entries) ...[
              _AnchorDisplay(
                label: _formatSubskillId(entry.key),
                min: entry.value.min,
                scratch: entry.value.scratch,
                pro: entry.value.pro,
                unit: _anchorUnit(drill),
              ),
              const SizedBox(height: SpacingTokens.sm),
            ],
          ],
          // Target section — custom drills only.
          if (!isStandard && isScored) ...[
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'Target',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ColorTokens.textPrimary,
                  ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            if (drill.target != null)
              DetailRow(
                label: 'Personal Target',
                value: drill.target!.toStringAsFixed(1),
              )
            else
              Text(
                'No target set',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorTokens.textTertiary,
                    ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.md,
            SpacingTokens.sm,
            SpacingTokens.md,
            SpacingTokens.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ZxPillButton(
                label: 'Start This Drill',
                icon: Icons.play_arrow,
                variant: ZxPillVariant.progress,
                expanded: true,
                centered: true,
                onTap: () => _startPractice(drill),
              ),
              if (_isAdopted && isStandard) ...[
                const SizedBox(height: SpacingTokens.sm),
                ZxPillButton(
                  label: 'Remove from Active Drills',
                  variant: ZxPillVariant.destructive,
                  expanded: true,
                  centered: true,
                  onTap: () => _removeFromActive(drill),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startPractice(Drill drill) async {
    final userId = ref.read(currentUserIdProvider);
    // Auto-adopt standard drills if not already adopted.
    if (drill.origin == DrillOrigin.standard) {
      try {
        await ref.read(drillRepositoryProvider).adoptStandardDrill(userId, drill);
      } catch (_) {
        // Already adopted or validation error — proceed anyway.
      }
    }

    if (!mounted) return;
    final envSurface = await showEnvironmentSurfacePicker(context);
    if (envSurface == null || !mounted) return;

    // Check if drill requires clubs the user doesn't have.
    if (drill.clubSelectionMode != null) {
      final clubs = await ref
          .read(clubsForSkillAreaProvider((userId, drill.skillArea)).future);
      if (clubs.isEmpty && mounted) {
        final proceed = await _showNoClubsWarning(drill.skillArea);
        if (proceed != true || !mounted) return;
      }
    }

    final actions = ref.read(practiceActionsProvider);
    final repo = ref.read(practiceRepositoryProvider);

    // If there's already an active practice block, end it first.
    final existingBlock = await repo.getActivePracticeBlock(userId).first;
    if (existingBlock != null) {
      await actions.endPracticeBlock(existingBlock.practiceBlockId, userId);
    }

    if (!mounted) return;

    final pb = await actions.startPracticeBlock(
      userId,
      initialDrillIds: [drill.drillId],
      surfaceType: envSurface.surface,
    );

    if (!mounted) return;

    // Get the practice entry that was just created for this drill.
    final entries = await repo.getPracticeEntriesByBlock(pb.practiceBlockId);
    if (entries.isEmpty || !mounted) return;
    final entry = entries.first;

    // S04 §4.3 — Prompt for intention declaration on Binary Hit/Miss drills.
    String? userDeclaration;
    if (drill.inputMode == InputMode.binaryHitMiss) {
      userDeclaration = await _promptForDeclaration();
      if (userDeclaration != null && userDeclaration.trim().isEmpty) {
        userDeclaration = null;
      }
      if (!mounted) return;
    }

    final session = await actions.startSession(
      entry.practiceEntryId,
      userId,
      userDeclaration: userDeclaration,
    );

    if (!mounted) return;

    // Go directly to execution screen, skipping the queue.
    final screen = PracticeRouter.routeToExecutionScreen(
      drill: drill,
      session: session,
      userId: userId,
    );

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => screen),
    );

    // After execution returns, auto-discard session if empty.
    if (!mounted) return;
    await _discardSessionIfEmpty(entry.practiceEntryId, session.sessionId);
  }

  /// Discard a session if it has zero instances recorded.
  Future<void> _discardSessionIfEmpty(String entryId, String sessionId) async {
    final repo = ref.read(practiceRepositoryProvider);
    final entry = await repo.getPracticeEntryById(entryId);
    if (entry == null || entry.entryType != PracticeEntryType.activeSession) {
      return;
    }
    final currentSet = await repo.getCurrentSet(sessionId);
    if (currentSet == null) return;
    final instanceCount = await repo.getInstanceCount(currentSet.setId);
    final setCount = await repo.getSetCount(sessionId);
    if (instanceCount == 0 && setCount <= 1) {
      await ref
          .read(practiceActionsProvider)
          .discardSession(entryId, sessionId);
    }
  }

  /// S04 §4.3 — Prompt for intention declaration on Binary Hit/Miss drills.
  Future<String?> _promptForDeclaration() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Session Declaration',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: ColorTokens.textPrimary),
          decoration: InputDecoration(
            hintText: 'What are you aiming for? (e.g. "Hit fairway")',
            hintStyle: TextStyle(color: ColorTokens.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryDefault,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  /// Warning when no clubs are configured for the drill's skill area.
  Future<bool?> _showNoClubsWarning(SkillArea skillArea) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('No Clubs Configured',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: Text(
          'This drill requires clubs for ${skillArea.dbValue}, '
          'but you have none in your bag. '
          'Add clubs in your Equipment bag before starting this drill.',
          style: const TextStyle(color: ColorTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.warningIntegrity,
            ),
            child: const Text('Start Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromActive(Drill drill) async {
    final userId = ref.read(currentUserIdProvider);
    final drillRepo = ref.read(drillRepositoryProvider);
    await drillRepo.retireAdoption(userId, drill.drillId);
    if (mounted) {
      setState(() => _isAdopted = false);
    }
  }

  Future<void> _handleAction(String action) async {
    final userId = ref.read(currentUserIdProvider);
    final drillRepo = ref.read(drillRepositoryProvider);
    final drill = _drill!;

    switch (action) {
      case 'retire':
        await drillRepo.retireDrill(userId, drill.drillId);
        await _loadDrill();
      case 'reactivate':
        await drillRepo.reactivateDrill(userId, drill.drillId);
        await _loadDrill();
      case 'duplicate':
        await drillRepo.duplicateDrill(userId, drill.drillId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drill duplicated')),
          );
        }
      case 'delete':
        final confirmed = await showSoftConfirmation(
          context,
          title: 'Delete Drill',
          message: 'This will permanently delete this drill and all associated data. This action cannot be undone.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (confirmed) {
          await drillRepo.deleteDrill(userId, drill.drillId);
          if (mounted) Navigator.pop(context);
        }
    }
  }

  String _drillTypeLabel(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Technique Block',
      DrillType.transition => 'Transition',
      DrillType.pressure => 'Pressure',
      DrillType.benchmark => 'Benchmark',
    };
  }

  String _formatTargetValue(double? value, DrillLengthUnit? unit) {
    if (value == null) return 'N/A';
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return unit != null ? '$formatted ${unit.dbValue}' : formatted;
  }

  String _recommendedEquipment(Drill drill) {
    final json = drill.recommendedEquipment;
    if (json.isEmpty || json == '[]') return '';
    try {
      final list = jsonDecode(json) as List<dynamic>;
      if (list.isEmpty) return '';
      return list.map((e) => _formatEquipmentName(e as String)).join(', ');
    } on Exception {
      return '';
    }
  }

  String _formatEquipmentName(String value) {
    // Convert PascalCase to spaced words.
    return value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
  }

  String _anchorUnit(Drill drill) {
    return switch (drill.metricSchemaId) {
      'driver_club_speed' || 'driver_ball_speed' ||
      'raw_club_head_speed' || 'raw_ball_speed' => 'mph',
      'driver_total_distance' || 'raw_total_distance' ||
      'raw_carry_distance' => 'yds',
      _ => '%',
    };
  }

  String _formatSubskillId(String id) {
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Read-only anchor display — shows Min / Scratch / Pro values.
class _AnchorDisplay extends StatelessWidget {
  final String label;
  final double min;
  final double scratch;
  final double pro;
  final String unit;

  const _AnchorDisplay({
    required this.label,
    required this.min,
    required this.scratch,
    required this.pro,
    this.unit = '%',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Row(
            children: [
              _AnchorValue(label: 'Min', value: min, unit: unit),
              const SizedBox(width: SpacingTokens.lg),
              _AnchorValue(label: 'Scratch', value: scratch, unit: unit),
              const SizedBox(width: SpacingTokens.lg),
              _AnchorValue(label: 'Pro', value: pro, unit: unit),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnchorValue extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const _AnchorValue({required this.label, required this.value, this.unit = '%'});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ColorTokens.textTertiary,
              ),
        ),
        Text(
          '${value.toStringAsFixed(0)}$unit',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColorTokens.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}
