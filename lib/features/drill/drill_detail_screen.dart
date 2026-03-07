import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
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
  static const _userId = kDevUserId;
  Drill? _drill;
  bool _isLoading = true;
  Map<String, ({double min, double scratch, double pro})> _anchors = {};

  @override
  void initState() {
    super.initState();
    _loadDrill();
  }

  Future<void> _loadDrill() async {
    final drill =
        await ref.read(drillRepositoryProvider).getById(widget.drillId);
    if (mounted) {
      setState(() {
        _drill = drill;
        _isLoading = false;
        if (drill != null) {
          _anchors = _parseAnchors(drill.anchors);
        }
      });
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
    final isSystem = drill.origin == DrillOrigin.system;
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
          _DetailRow(label: 'Status', value: drill.status.dbValue),
          _DetailRow(label: 'Skill Area', value: drill.skillArea.dbValue),
          _DetailRow(label: 'Drill Type', value: _drillTypeLabel(drill.drillType)),
          _DetailRow(label: 'Input Mode', value: drill.inputMode.dbValue),
          _DetailRow(label: 'Origin', value: drill.origin.dbValue),
          if (drill.requiredAttemptsPerSet != null)
            _DetailRow(
              label: 'Attempts/Set',
              value: '${drill.requiredAttemptsPerSet}',
            ),
          _DetailRow(
            label: 'Set Count',
            value: '${drill.requiredSetCount}',
          ),
          if (drill.clubSelectionMode != null)
            _DetailRow(
              label: 'Club Selection',
              value: drill.clubSelectionMode!.dbValue,
            ),
          if (drill.targetDistanceMode != null)
            _DetailRow(
              label: 'Target Distance',
              value: drill.targetDistanceMode!.dbValue,
            ),

          // Anchors section — system drills, read-only display.
          if (isSystem && isScored) ...[
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
              ),
              const SizedBox(height: SpacingTokens.sm),
            ],
          ],
          // Target section — custom drills only.
          if (!isSystem && isScored) ...[
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'Target',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ColorTokens.textPrimary,
                  ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            if (drill.target != null)
              _DetailRow(
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
    );
  }

  Future<void> _handleAction(String action) async {
    final drillRepo = ref.read(drillRepositoryProvider);
    final drill = _drill!;

    switch (action) {
      case 'retire':
        await drillRepo.retireDrill(_userId, drill.drillId);
        await _loadDrill();
      case 'reactivate':
        await drillRepo.reactivateDrill(_userId, drill.drillId);
        await _loadDrill();
      case 'duplicate':
        await drillRepo.duplicateDrill(_userId, drill.drillId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drill duplicated')),
          );
        }
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Drill'),
            content: const Text(
              'This will permanently delete this drill and all associated data. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: ColorTokens.errorDestructive),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await drillRepo.deleteDrill(_userId, drill.drillId);
          if (mounted) Navigator.pop(context);
        }
    }
  }

  String _drillTypeLabel(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Technique Block',
      DrillType.transition => 'Transition',
      DrillType.pressure => 'Pressure',
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only anchor display — shows Min / Scratch / Pro values with % suffix.
class _AnchorDisplay extends StatelessWidget {
  final String label;
  final double min;
  final double scratch;
  final double pro;

  const _AnchorDisplay({
    required this.label,
    required this.min,
    required this.scratch,
    required this.pro,
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
              _AnchorValue(label: 'Min', value: min),
              const SizedBox(width: SpacingTokens.lg),
              _AnchorValue(label: 'Scratch', value: scratch),
              const SizedBox(width: SpacingTokens.lg),
              _AnchorValue(label: 'Pro', value: pro),
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

  const _AnchorValue({required this.label, required this.value});

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
          '${value.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColorTokens.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}
