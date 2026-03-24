import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/drill/widgets/drill_card.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// S08 §8.12.3 — Routine entry card: displays a fixed or criterion entry.

class RoutineEntryCard extends ConsumerWidget {
  final RoutineEntry entry;
  final int index;
  final VoidCallback? onRemove;

  const RoutineEntryCard({
    super.key,
    required this.entry,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFixed = entry.type == RoutineEntryType.fixed;

    if (isFixed && entry.drillId != null) {
      return FutureBuilder(
        future: ref.read(drillRepositoryProvider).getById(entry.drillId!),
        builder: (context, snapshot) {
          final drill = snapshot.data;
          if (drill != null) {
            return DrillCard(
              drill: drill,
              trailing: onRemove != null
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: ColorTokens.textTertiary),
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
            );
          }
          // Loading or not found — show placeholder.
          return _PlaceholderCard(
            icon: Icons.sports_golf,
            label: 'Loading drill...',
            index: index,
            onRemove: onRemove,
          );
        },
      );
    }

    // Generated criterion entry.
    return _PlaceholderCard(
      icon: Icons.auto_awesome,
      iconColor: ColorTokens.warningIntegrity,
      label: entry.criterion != null
          ? _criterionSummary(entry.criterion!)
          : 'Generated',
      index: index,
      onRemove: onRemove,
    );
  }

  String _criterionSummary(GenerationCriterion c) {
    final parts = <String>[];
    if (c.skillArea != null) parts.add(c.skillArea!.dbValue);
    if (c.drillTypes.isNotEmpty) {
      parts.add(c.drillTypes.map((d) => d.dbValue).join(', '));
    }
    parts.add(c.mode.dbValue);
    return parts.join(' · ');
  }
}

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final int index;
  final VoidCallback? onRemove;

  const _PlaceholderCard({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? ColorTokens.primaryDefault;
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close,
                  size: 18, color: ColorTokens.textTertiary),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
