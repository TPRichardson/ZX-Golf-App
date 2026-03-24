import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/core/widgets/empty_state.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/practice_router.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/features/bag/bag_screen.dart';
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
        body: const EmptyState(message: 'Drill not found'),
      );
    }

    final drill = _drill!;
    final isStandard = drill.origin == DrillOrigin.standard;
    final isScored = drill.drillType != DrillType.techniqueBlock;

    final skillColor = ColorTokens.skillArea(drill.skillArea);
    final subskills = _parseSubskills(drill.subskillMapping);

    return Scaffold(
      appBar: ZxAppBar(
        title: '',
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
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
        children: [
          // Hero header — drill name with skill area colour accent.
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: ColorTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
              border: Border(left: BorderSide(color: skillColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drill type label above the title.
                Text(
                  '${_drillTypeLabel(drill.drillType)} Drill',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySmSize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  drill.name,
                  style: TextStyle(
                    fontSize: TypographyTokens.displayMdSize,
                    fontWeight: TypographyTokens.displayLgWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                // Skill area badge + subskill chips.
                Wrap(
                  spacing: SpacingTokens.sm,
                  runSpacing: SpacingTokens.xs,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: skillColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(ShapeTokens.radiusMicro),
                      ),
                      child: Text(
                        drill.skillArea.dbValue,
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          fontWeight: FontWeight.w600,
                          color: skillColor,
                        ),
                      ),
                    ),
                    ...subskills.map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: skillColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(ShapeTokens.radiusMicro),
                        border: Border.all(
                            color: skillColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _formatSubskillId(s),
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          color: skillColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // Description.
          if (drill.description != null) ...[
            const SizedBox(height: SpacingTokens.md),
            Text(
              drill.description!,
              style: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          // Mode cards row — Target + Club.
          const SizedBox(height: SpacingTokens.md),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  icon: Icons.gps_fixed,
                  title: 'Target',
                  value: _targetLabel(drill),
                  color: _targetColor(drill),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: _ModeCard(
                  icon: Icons.sports_golf,
                  title: 'Club',
                  value: _clubLabel(drill),
                  color: _clubColor(drill),
                ),
              ),
            ],
          ),

          // Structure row — Sets + Attempts.
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  icon: Icons.layers,
                  title: 'Sets',
                  value: '${drill.requiredSetCount}',
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: _ModeCard(
                  icon: Icons.repeat,
                  title: 'Attempts/Set',
                  value: drill.requiredAttemptsPerSet != null
                      ? '${drill.requiredAttemptsPerSet}'
                      : 'Open',
                ),
              ),
            ],
          ),

          // Required equipment.
          if (_parseEquipmentList(drill.requiredEquipment).isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.sm),
            _ModeCard(
              icon: Icons.build_outlined,
              title: 'Equipment Needed',
              value: _parseEquipmentList(drill.requiredEquipment),
            ),
          ],

          // Recommended equipment.
          if (_recommendedEquipment(drill).isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.lg),
            const Text(
              'Recommended Equipment',
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                fontWeight: FontWeight.w600,
                color: ColorTokens.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              _recommendedEquipment(drill),
              style: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: SpacingTokens.xl),
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('No Clubs Configured',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: Text(
          'This drill requires clubs for ${skillArea.dbValue}. '
          'Add clubs to your bag before starting this drill.',
          style: const TextStyle(color: ColorTokens.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
            SpacingTokens.lg, 0, SpacingTokens.lg, SpacingTokens.lg),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ZxPillButton(
                label: 'Edit Bag',
                variant: ZxPillVariant.primary,
                expanded: true,
                centered: true,
                onTap: () {
                  Navigator.pop(dialogCtx, false);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BagScreen()),
                  );
                },
              ),
              const SizedBox(height: SpacingTokens.sm),
              ZxPillButton(
                label: 'Cancel',
                variant: ZxPillVariant.tertiary,
                expanded: true,
                centered: true,
                onTap: () => Navigator.pop(dialogCtx, false),
              ),
            ],
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

  static String _drillTypeLabel(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Technique',
      DrillType.transition => 'Transition',
      DrillType.pressure => 'Pressure',
      DrillType.benchmark => 'Benchmark',
    };
  }

  static String _targetLabel(Drill drill) {
    return switch (drill.targetDistanceMode) {
      TargetDistanceMode.randomRange => 'Random',
      TargetDistanceMode.randomDistancePerSet => 'Fixed',
      TargetDistanceMode.clubCarry => 'Club Carry',
      TargetDistanceMode.fixed => 'Fixed',
      TargetDistanceMode.percentageOfClubCarry => '% Carry',
      null => 'None',
    };
  }

  static Color _targetColor(Drill drill) {
    if (drill.targetDistanceMode == TargetDistanceMode.clubCarry) {
      return ColorTokens.primaryDefault;
    }
    if (drill.targetDistanceMode == TargetDistanceMode.randomRange ||
        drill.targetDistanceMode == TargetDistanceMode.randomDistancePerSet) {
      return ColorTokens.ragAmber;
    }
    return ColorTokens.textTertiary;
  }

  static String _clubLabel(Drill drill) {
    return switch (drill.clubSelectionMode) {
      ClubSelectionMode.userLed => 'User Led',
      ClubSelectionMode.random => 'Random',
      ClubSelectionMode.guided => 'Sequence',
      null => 'None',
    };
  }

  static Color _clubColor(Drill drill) {
    if (drill.clubSelectionMode == ClubSelectionMode.userLed) {
      return ColorTokens.primaryDefault;
    }
    if (drill.clubSelectionMode == ClubSelectionMode.random ||
        drill.clubSelectionMode == ClubSelectionMode.guided) {
      return ColorTokens.ragAmber;
    }
    return ColorTokens.textTertiary;
  }

  static String _gridLabel(Drill drill) {
    return switch (drill.gridType) {
      GridType.threeByThree => 'Full Grid (3x3)',
      GridType.oneByThree => 'Left/Right (1x3)',
      GridType.threeByOne => 'Long/Short (3x1)',
      null => '',
    };
  }

  static List<String> _parseSubskills(String json) {
    if (json.isEmpty || json == '[]') return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>();
    } on Exception {
      return [];
    }
  }

  static String _parseEquipmentList(String json) {
    if (json.isEmpty || json == '[]') return '';
    try {
      final list = jsonDecode(json) as List<dynamic>;
      if (list.isEmpty) return '';
      return list.map((e) => _formatEquipmentName(e as String)).join(', ');
    } on Exception {
      return '';
    }
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

  static String _formatEquipmentName(String value) {
    return value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
  }

  String _formatSubskillId(String id) {
    // Remove skill area prefix (e.g. "putting_" from "putting_distance_control").
    final parts = id.split('_');
    final meaningful = parts.length > 1 ? parts.sublist(1) : parts;
    return meaningful
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? color;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? ColorTokens.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md, vertical: 4),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                title,
                style: const TextStyle(
                  fontSize: TypographyTokens.bodySmSize,
                  color: ColorTokens.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
