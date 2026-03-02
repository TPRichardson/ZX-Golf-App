// Phase 4 — Club Selector widget.
// S04 §4.7 — Club selection per ClubSelectionMode.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

/// S04 §4.7 — Selects a club for the current instance.
/// Mode: UserLed = dropdown, Guided = suggested with override, Random = auto.
class ClubSelector extends StatelessWidget {
  final ClubSelectionMode mode;
  final List<String> availableClubs;
  final String selectedClub;
  final ValueChanged<String> onClubSelected;

  const ClubSelector({
    super.key,
    required this.mode,
    required this.availableClubs,
    required this.selectedClub,
    required this.onClubSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      child: Row(
        children: [
          Text(
            'Club:',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: _buildSelector(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector(BuildContext context) {
    // S04 §4.7 — Random mode: display assigned club, no user interaction.
    if (mode == ClubSelectionMode.random) {
      return Text(
        selectedClub,
        style: TextStyle(
          fontSize: TypographyTokens.bodyLgSize,
          fontWeight: FontWeight.w500,
          color: ColorTokens.textPrimary,
        ),
      );
    }

    // UserLed + Guided: dropdown.
    return DropdownButton<String>(
      value: selectedClub,
      isExpanded: true,
      dropdownColor: ColorTokens.surfaceModal,
      style: TextStyle(
        fontSize: TypographyTokens.bodyLgSize,
        color: ColorTokens.textPrimary,
      ),
      underline: Container(
        height: 1,
        color: ColorTokens.surfaceBorder,
      ),
      items: availableClubs
          .map((club) => DropdownMenuItem(
                value: club,
                child: Text(club),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onClubSelected(value);
      },
    );
  }
}
