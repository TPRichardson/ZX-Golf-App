import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';

// S08 §8.2.3 — Schedule apply screen: date range → preview → confirm.

class ScheduleApplyScreen extends ConsumerStatefulWidget {
  final String scheduleId;
  final DateTime? startDate;

  const ScheduleApplyScreen({
    super.key,
    required this.scheduleId,
    this.startDate,
  });

  @override
  ConsumerState<ScheduleApplyScreen> createState() =>
      _ScheduleApplyScreenState();
}

class _ScheduleApplyScreenState
    extends ConsumerState<ScheduleApplyScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    if (widget.startDate != null) {
      _startDate = widget.startDate;
      _endDate = widget.startDate!.add(const Duration(days: 6));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ZxAppBar(title: 'Apply Schedule'),
      body: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select date range',
              style: TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.md),

            // Start date picker.
            _DatePickerTile(
              label: 'Start date',
              date: _startDate,
              onPick: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: SpacingTokens.sm),

            // End date picker.
            _DatePickerTile(
              label: 'End date',
              date: _endDate,
              onPick: () => _pickDate(isStart: false),
            ),
            const Spacer(),

            // Confirm button.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    (_startDate != null && _endDate != null && !_applying)
                        ? _apply
                        : null,
                style: FilledButton.styleFrom(
                  backgroundColor: ColorTokens.primaryDefault,
                  padding: const EdgeInsets.symmetric(
                      vertical: SpacingTokens.md),
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
                    : const Text('Apply Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Auto-set end date to start + 6 days if not set.
          _endDate ??= picked.add(const Duration(days: 6));
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      // Phase 5 stub: simplified application without full preview.
      // Full integration would use ScheduleApplicator.previewListMode/previewDayPlanningMode.
      final actions = ref.read(planningActionsProvider);
      await actions.applySchedule(
        kDevUserId,
        widget.scheduleId,
        _startDate!,
        _endDate!,
        {}, // Empty resolved map — stub for Phase 5 UI.
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

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            Text(
              date != null
                  ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
                  : 'Select',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: date != null
                    ? ColorTokens.textPrimary
                    : ColorTokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
