import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

/// Inter-shot dialog for variable target drills.
/// Shows next target, club selector, shape and effort pickers.
/// For chipping games, shows flight (1/2/3) instead of shape/effort.
class NextTargetDialog extends StatefulWidget {
  final int targetDistance;
  final String? initialShape;
  final int? initialEffort;
  final int? initialFlight;
  final String initialClubLabel;
  final List<UserClub> availableClubs;
  final Map<String, String> clubIdToLabel;
  final SkillArea skillArea;
  final String userId;
  final bool showShotIntent;
  /// When true, show flight (1/2/3) instead of shape/effort.
  final bool showFlightMode;
  /// Structured last-hole summary for chipping game (3-box display).
  final ({int hole, String par, String score, Color scoreColor})? lastHoleSummary;
  /// Current hole par (for chipping game display).
  final String? holePar;
  final void Function(String? clubId, String? shape, int? effort, {int? flight}) onConfirm;
  final ValueChanged<bool> onToggleShotIntent;

  const NextTargetDialog({
    super.key,
    required this.targetDistance,
    required this.initialShape,
    required this.initialEffort,
    this.initialFlight,
    required this.initialClubLabel,
    required this.availableClubs,
    required this.clubIdToLabel,
    required this.skillArea,
    required this.userId,
    required this.showShotIntent,
    this.showFlightMode = false,
    this.lastHoleSummary,
    this.holePar,
    required this.onConfirm,
    required this.onToggleShotIntent,
  });

  @override
  State<NextTargetDialog> createState() => _NextTargetDialogState();
}

class _NextTargetDialogState extends State<NextTargetDialog> {
  String? _selectedClubId;
  String? _shape;
  int? _effort;
  int? _flight;
  late bool _showIntent;

  @override
  void initState() {
    super.initState();
    _showIntent = widget.showShotIntent;
    _shape = widget.initialShape;
    _effort = widget.initialEffort;
    _flight = widget.initialFlight;
    // Find club ID matching the initial label.
    _selectedClubId = widget.availableClubs
        .where((c) => c.clubType.dbValue == widget.initialClubLabel)
        .map((c) => c.clubId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.lastHoleSummary != null) ...[
            const Text(
              'Last Hole',
              style: TextStyle(color: ColorTokens.textPrimary),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Row(
              children: [
                _summaryBox('Hole', '${widget.lastHoleSummary!.hole}'),
                const SizedBox(width: SpacingTokens.sm),
                _summaryBox('Par', widget.lastHoleSummary!.par),
                const SizedBox(width: SpacingTokens.sm),
                _summaryBox('Score', widget.lastHoleSummary!.score,
                    valueColor: widget.lastHoleSummary!.scoreColor),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
          ],
          const Text(
            'Next Shot',
            style: TextStyle(color: ColorTokens.textPrimary),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.all(SpacingTokens.md),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Target distance + par row.
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.md,
                  ),
                  decoration: BoxDecoration(
                    color: ColorTokens.primaryDefault.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                      Text(
                        '${widget.targetDistance}y',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.primaryDefault,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.holePar != null) ...[
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: SpacingTokens.md,
                    ),
                    decoration: BoxDecoration(
                      color: ColorTokens.surfaceRaised,
                      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                      border: Border.all(color: ColorTokens.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Beat',
                          style: TextStyle(
                            fontSize: TypographyTokens.bodySmSize,
                            color: ColorTokens.textTertiary,
                          ),
                        ),
                        Text(
                          widget.holePar!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: ColorTokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: SpacingTokens.md),

          // Club selector — grid matching club picker style.
          _sectionLabel('Club'),
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: widget.availableClubs.map((club) {
              final isSelected = club.clubId == _selectedClubId;
              return InkWell(
                onTap: () => setState(() => _selectedClubId = club.clubId),
                borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
                child: Container(
                  width: 72,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorTokens.primaryDefault.withValues(alpha: 0.2)
                        : ColorTokens.surfaceRaised,
                    borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
                    border: Border.all(
                      color: isSelected
                          ? ColorTokens.primaryDefault
                          : ColorTokens.surfaceBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      club.clubType.dbValue,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? ColorTokens.primaryDefault
                            : ColorTokens.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: SpacingTokens.md),

          // Flight mode (chipping) or shot intent toggle (standard).
          if (widget.showFlightMode) ...[
            _sectionLabel('Flight'),
            Row(
              children: [
                for (final f in [
                  (value: 1, label: 'Low'),
                  (value: 2, label: 'Mid'),
                  (value: 3, label: 'High'),
                ])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: f.value != 3 ? SpacingTokens.xs : 0,
                      ),
                      child: ChoiceChip(
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(f.label, textAlign: TextAlign.center),
                        ),
                        selected: _flight == f.value,
                        onSelected: (_) => setState(() =>
                            _flight = _flight == f.value ? null : f.value),
                        selectedColor: ColorTokens.primaryDefault,
                        backgroundColor: ColorTokens.surfaceRaised,
                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: _flight == f.value
                              ? ColorTokens.textPrimary
                              : ColorTokens.textSecondary,
                        ),
                        side: BorderSide(
                          color: _flight == f.value
                              ? ColorTokens.primaryDefault
                              : ColorTokens.surfaceBorder,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Shot intent toggle.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shot Intent',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySmSize,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.textTertiary,
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: Switch(
                    value: _showIntent,
                    activeColor: ColorTokens.primaryDefault,
                    onChanged: (v) {
                      setState(() => _showIntent = v);
                      widget.onToggleShotIntent(v);
                    },
                  ),
                ),
              ],
            ),

            if (_showIntent) ...[
              const SizedBox(height: SpacingTokens.sm),

              // Shape selector.
              _sectionLabel('Shape'),
              Row(
                children: [
                  for (final s in ShotShape.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: s != ShotShape.values.last
                              ? SpacingTokens.xs
                              : 0,
                        ),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(s.dbValue, textAlign: TextAlign.center),
                          ),
                          selected: _shape == s.dbValue,
                          onSelected: (_) => setState(() =>
                              _shape = _shape == s.dbValue ? null : s.dbValue),
                          selectedColor: ColorTokens.primaryDefault,
                          backgroundColor: ColorTokens.surfaceRaised,
                          labelStyle: TextStyle(
                            fontSize: 16,
                            color: _shape == s.dbValue
                                ? ColorTokens.textPrimary
                                : ColorTokens.textSecondary,
                          ),
                          side: BorderSide(
                            color: _shape == s.dbValue
                                ? ColorTokens.primaryDefault
                                : ColorTokens.surfaceBorder,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: SpacingTokens.md),

              // Effort selector.
              _sectionLabel('Effort'),
              Row(
                children: [
                  for (final e in [75, 90, 100])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: e != 100 ? SpacingTokens.xs : 0,
                        ),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text('$e%', textAlign: TextAlign.center),
                          ),
                          selected: _effort == e,
                          onSelected: (_) => setState(() =>
                              _effort = _effort == e ? null : e),
                          selectedColor: ColorTokens.primaryDefault,
                          backgroundColor: ColorTokens.surfaceRaised,
                          labelStyle: TextStyle(
                            fontSize: 16,
                            color: _effort == e
                                ? ColorTokens.textPrimary
                                : ColorTokens.textSecondary,
                          ),
                          side: BorderSide(
                            color: _effort == e
                                ? ColorTokens.primaryDefault
                                : ColorTokens.surfaceBorder,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              widget.onConfirm(_selectedClubId, _shape, _effort, flight: _flight);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryDefault,
              foregroundColor: ColorTokens.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
              ),
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
              textStyle: const TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Ready'),
          ),
        ),
      ],
    );
  }

  static Widget _summaryBox(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: SpacingTokens.sm,
          horizontal: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: TypographyTokens.bodySmSize,
                color: ColorTokens.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                fontWeight: FontWeight.w700,
                color: valueColor ?? ColorTokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: TypographyTokens.bodySmSize,
            fontWeight: FontWeight.w600,
            color: ColorTokens.textTertiary,
          ),
        ),
      ),
    );
  }
}
