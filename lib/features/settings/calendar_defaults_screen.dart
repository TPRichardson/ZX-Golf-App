import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';

// S10 §10.8 — 7-day default slot capacity pattern editor.

class CalendarDefaultsScreen extends ConsumerWidget {
  const CalendarDefaultsScreen({super.key});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final pattern = prefs.defaultSlotCapacityPattern;

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      appBar: AppBar(
        title: const Text('Slot Capacity Pattern'),
        backgroundColor: ColorTokens.surfacePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          Text(
            'Set the default number of practice slots for each day of the week.',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          for (var i = 0; i < 7; i++)
            _DayCapacityRow(
              dayLabel: _dayLabels[i],
              value: pattern.length > i ? pattern[i] : 0,
              onChanged: (v) {
                final updated = List<int>.from(pattern);
                while (updated.length < 7) {
                  updated.add(0);
                }
                updated[i] = v;
                updatePreferences(
                  ref,
                  prefs.copyWith(defaultSlotCapacityPattern: updated),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DayCapacityRow extends StatelessWidget {
  final String dayLabel;
  final int value;
  final ValueChanged<int> onChanged;

  const _DayCapacityRow({
    required this.dayLabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              dayLabel,
              style: const TextStyle(
                color: ColorTokens.textPrimary,
                fontSize: TypographyTokens.bodyLgSize,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: ColorTokens.textSecondary),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorTokens.textPrimary,
                fontSize: TypographyTokens.bodyLgSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: ColorTokens.textSecondary),
            onPressed: value < 10 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
