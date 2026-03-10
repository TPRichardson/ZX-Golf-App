// Club grid picker — tabbed modal for one-tap club selection.
// Common tab shows 16 most-used clubs; Specialist tab shows the rest.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// The 16 most common club names (by dbValue).
const _commonClubs = {
  'Driver',
  'W3',
  'W5',
  'H3',
  'H4',
  'i3',
  'i4',
  'i5',
  'i6',
  'i7',
  'i8',
  'i9',
  'PW',
  'GW',
  'SW',
  'LW',
  'Chipper',
  'Putter',
};

/// Shows a tabbed dialog with clubs in a grid layout.
/// Common tab (default) shows the 16 most-used clubs; Specialist tab shows
/// everything else. Returns the selected club name.
Future<String?> showClubGridPicker(
  BuildContext context, {
  required List<String> clubs,
  required String selectedClub,
}) {
  final common = clubs.where((c) => _commonClubs.contains(c)).toList();
  final specialist = clubs.where((c) => !_commonClubs.contains(c)).toList();

  // If all clubs fit in one tab, skip tabs entirely.
  if (specialist.isEmpty) {
    return _showSingleGrid(context, clubs: clubs, selectedClub: selectedClub);
  }

  // Default tab: whichever contains the currently selected club.
  final initialTab = specialist.contains(selectedClub) ? 1 : 0;

  return showDialog<String>(
    context: context,
    builder: (ctx) => _TabbedClubPicker(
      common: common,
      specialist: specialist,
      selectedClub: selectedClub,
      initialTab: initialTab,
    ),
  );
}

/// Fallback: single grid with no tabs (when all clubs are common).
Future<String?> _showSingleGrid(
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
        child: _ClubGrid(
          clubs: clubs,
          selectedClub: selectedClub,
          onSelect: (club) => Navigator.pop(ctx, club),
        ),
      ),
    ),
  );
}

class _TabbedClubPicker extends StatelessWidget {
  final List<String> common;
  final List<String> specialist;
  final String selectedClub;
  final int initialTab;

  const _TabbedClubPicker({
    required this.common,
    required this.specialist,
    required this.selectedClub,
    required this.initialTab,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Club',
              style: TextStyle(color: ColorTokens.textPrimary),
            ),
            const SizedBox(height: SpacingTokens.sm),
            TabBar(
              labelColor: ColorTokens.primaryDefault,
              unselectedLabelColor: ColorTokens.textTertiary,
              indicatorColor: ColorTokens.primaryDefault,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: ColorTokens.surfaceBorder,
              labelStyle: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Common'),
                Tab(text: 'Specialist'),
              ],
            ),
          ],
        ),
        contentPadding: const EdgeInsets.all(SpacingTokens.md),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: TabBarView(
            children: [
              _ClubGrid(
                clubs: common,
                selectedClub: selectedClub,
                onSelect: (club) => Navigator.pop(context, club),
              ),
              _ClubGrid(
                clubs: specialist,
                selectedClub: selectedClub,
                onSelect: (club) => Navigator.pop(context, club),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubGrid extends StatelessWidget {
  final List<String> clubs;
  final String selectedClub;
  final ValueChanged<String> onSelect;

  const _ClubGrid({
    required this.clubs,
    required this.selectedClub,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (clubs.isEmpty) {
      return Center(
        child: Text(
          'No clubs in this category',
          style: TextStyle(
            color: ColorTokens.textTertiary,
            fontSize: TypographyTokens.bodySize,
          ),
        ),
      );
    }

    return GridView.builder(
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
          onTap: () => onSelect(club),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          child: Container(
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
                club,
                style: TextStyle(
                  fontSize: TypographyTokens.microSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
    );
  }
}
