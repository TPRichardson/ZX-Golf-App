import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';

/// Dialog to edit a shot's zone (hit/miss) and/or club.
class EditShotDialog extends StatefulWidget {
  final String currentLabel;
  final String? currentClubId;
  final List<({String label, bool isHit})>? zoneOptions;
  final List<UserClub> availableClubs;
  final Map<String, String> clubIdToLabel;
  final void Function(String? label, bool? isHit, String? clubId) onConfirm;

  const EditShotDialog({
    super.key,
    required this.currentLabel,
    required this.currentClubId,
    required this.zoneOptions,
    required this.availableClubs,
    required this.clubIdToLabel,
    required this.onConfirm,
  });

  @override
  State<EditShotDialog> createState() => _EditShotDialogState();
}

class _EditShotDialogState extends State<EditShotDialog> {
  late String _selectedLabel;
  late bool _selectedIsHit;
  String? _selectedClubId;

  @override
  void initState() {
    super.initState();
    _selectedLabel = widget.currentLabel;
    _selectedIsHit = widget.zoneOptions
            ?.where((z) => z.label == widget.currentLabel)
            .firstOrNull
            ?.isHit ??
        false;
    _selectedClubId = widget.currentClubId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Edit Shot',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      contentPadding: const EdgeInsets.all(SpacingTokens.md),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone selector (grid drills only).
            if (widget.zoneOptions != null) ...[
              const Text(
                'Result',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySmSize,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.textTertiary,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Wrap(
                spacing: SpacingTokens.xs,
                runSpacing: SpacingTokens.xs,
                children: widget.zoneOptions!.map((zone) {
                  final isSelected = zone.label == _selectedLabel;
                  final color = zone.isHit
                      ? ColorTokens.successDefault
                      : ColorTokens.missDefault;
                  return ChoiceChip(
                    label: Text(zone.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _selectedLabel = zone.label;
                      _selectedIsHit = zone.isHit;
                    }),
                    selectedColor: color.withValues(alpha: 0.3),
                    backgroundColor: ColorTokens.surfaceRaised,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: isSelected ? color : ColorTokens.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected ? color : ColorTokens.surfaceBorder,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: SpacingTokens.md),
            ],
            // Club selector.
            if (widget.availableClubs.isNotEmpty) ...[
              const Text(
                'Club',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySmSize,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.textTertiary,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Wrap(
                spacing: SpacingTokens.sm,
                runSpacing: SpacingTokens.sm,
                children: widget.availableClubs.map((club) {
                  final isSelected = club.clubId == _selectedClubId;
                  return InkWell(
                    onTap: () =>
                        setState(() => _selectedClubId = club.clubId),
                    borderRadius:
                        BorderRadius.circular(ShapeTokens.radiusGrid),
                    child: Container(
                      width: 72,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorTokens.primaryDefault
                                .withValues(alpha: 0.2)
                            : ColorTokens.surfaceRaised,
                        borderRadius:
                            BorderRadius.circular(ShapeTokens.radiusGrid),
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
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
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
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: ColorTokens.textSecondary)),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(_selectedLabel, _selectedIsHit, _selectedClubId);
            Navigator.pop(context, true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: ColorTokens.primaryDefault,
            foregroundColor: ColorTokens.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
