// Club grid picker — full-screen grid modal for one-tap club selection.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Shows a dialog with clubs in a grid layout. Returns the selected club name.
Future<String?> showClubGridPicker(
  BuildContext context, {
  required List<String> clubs,
  required String selectedClub,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Select Club',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      contentPadding: const EdgeInsets.all(SpacingTokens.md),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: SpacingTokens.sm,
            crossAxisSpacing: SpacingTokens.sm,
            childAspectRatio: 2.0,
          ),
          itemCount: clubs.length,
          itemBuilder: (context, index) {
            final club = clubs[index];
            final isSelected = club == selectedClub;
            return InkWell(
              onTap: () => Navigator.pop(ctx, club),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorTokens.primaryDefault.withValues(alpha: 0.2)
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
                    club,
                    style: TextStyle(
                      fontSize: TypographyTokens.microSize,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? ColorTokens.primaryDefault
                          : ColorTokens.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
