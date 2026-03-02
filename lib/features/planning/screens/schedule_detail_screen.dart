import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// S08 §8.12.3 — Schedule detail screen: view info + lifecycle actions.

class ScheduleDetailScreen extends ConsumerStatefulWidget {
  final String scheduleId;

  const ScheduleDetailScreen({super.key, required this.scheduleId});

  @override
  ConsumerState<ScheduleDetailScreen> createState() =>
      _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState
    extends ConsumerState<ScheduleDetailScreen> {
  Schedule? _schedule;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final repo = ref.read(planningRepositoryProvider);
    final schedule = await repo.getScheduleById(widget.scheduleId);
    if (schedule != null && mounted) {
      setState(() => _schedule = schedule);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_schedule == null) {
      return Scaffold(
        appBar: const ZxAppBar(title: 'Schedule'),
        body: const Center(
          child:
              CircularProgressIndicator(color: ColorTokens.primaryDefault),
        ),
      );
    }

    final isActive = _schedule!.status == ScheduleStatus.active;

    return Scaffold(
      appBar: ZxAppBar(
        title: _schedule!.name,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: ColorTokens.surfaceModal,
            onSelected: _onMenuAction,
            itemBuilder: (context) => [
              if (isActive)
                const PopupMenuItem(
                  value: 'retire',
                  child: Text('Retire'),
                ),
              if (_schedule!.status == ScheduleStatus.retired)
                const PopupMenuItem(
                  value: 'reactivate',
                  child: Text('Reactivate'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                    style:
                        TextStyle(color: ColorTokens.errorDestructive)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          // Status + mode row.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? ColorTokens.successDefault
                          .withValues(alpha: 0.15)
                      : ColorTokens.textTertiary
                          .withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusCard),
                ),
                child: Text(
                  _schedule!.status.dbValue,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: isActive
                        ? ColorTokens.successDefault
                        : ColorTokens.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: ColorTokens.primaryDefault
                      .withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusCard),
                ),
                child: Text(
                  _schedule!.applicationMode.dbValue,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.primaryDefault,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),

          // Info card.
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: ColorTokens.surfaceRaised,
              borderRadius:
                  BorderRadius.circular(ShapeTokens.radiusCard),
              border: Border.all(color: ColorTokens.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule Configuration',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Mode: ${_schedule!.applicationMode.dbValue}',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenuAction(String action) async {
    final actions = ref.read(planningActionsProvider);
    try {
      switch (action) {
        case 'retire':
          await actions.retireSchedule(_schedule!.scheduleId);
          await _loadSchedule();
        case 'reactivate':
          await actions.reactivateSchedule(_schedule!.scheduleId);
          await _loadSchedule();
        case 'delete':
          await actions.deleteSchedule(_schedule!.scheduleId);
          if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
