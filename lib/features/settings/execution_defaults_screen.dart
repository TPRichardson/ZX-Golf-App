import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';

// S10 §10.7 — Per-SkillArea default ClubSelectionMode settings.

class ExecutionDefaultsScreen extends ConsumerWidget {
  const ExecutionDefaultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      appBar: AppBar(
        title: const Text('Club Selection Defaults'),
        backgroundColor: ColorTokens.surfacePrimary,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Text(
              'Set the default club selection mode for each skill area.',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
          ),
          for (final area in SkillArea.values)
            _SkillAreaModeTile(
              area: area,
              mode: prefs.defaultClubSelectionModes[area] ??
                  ClubSelectionMode.random,
              onChanged: (mode) {
                final updated =
                    Map<SkillArea, ClubSelectionMode>.from(
                        prefs.defaultClubSelectionModes);
                updated[area] = mode;
                updatePreferences(
                  ref,
                  prefs.copyWith(defaultClubSelectionModes: updated),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SkillAreaModeTile extends StatelessWidget {
  final SkillArea area;
  final ClubSelectionMode mode;
  final ValueChanged<ClubSelectionMode> onChanged;

  const _SkillAreaModeTile({
    required this.area,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        area.dbValue,
        style: const TextStyle(color: ColorTokens.textPrimary),
      ),
      trailing: DropdownButton<ClubSelectionMode>(
        value: mode,
        dropdownColor: ColorTokens.surfaceModal,
        style: const TextStyle(color: ColorTokens.textSecondary),
        underline: const SizedBox.shrink(),
        items: ClubSelectionMode.values
            .map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(m.dbValue),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
