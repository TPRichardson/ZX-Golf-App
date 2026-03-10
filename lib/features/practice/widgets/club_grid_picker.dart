// Club grid picker — tabbed modal for one-tap club selection.
// Common tab shows 16 most-used clubs; Specialist tab shows the rest.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

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

String _clubLabel(ClubType type) {
  return switch (type) {
    ClubType.driver => 'Dr',
    ClubType.putter => 'Pt',
    ClubType.chipper => 'Ch',
    _ => type.dbValue,
  };
}

/// Shows a tabbed dialog with clubs in a grid layout.
/// Common tab (default) shows the 16 most-used clubs; Specialist tab shows
/// everything else. Returns the selected club name.
Future<String?> showClubGridPicker(
  BuildContext context, {
  required List<String> clubs,
  required String selectedClub,
  SkillArea? skillArea,
  String? userId,
}) {
  final common = clubs.where((c) => _commonClubs.contains(c)).toList();
  final specialist = clubs.where((c) => !_commonClubs.contains(c)).toList();

  // If all clubs fit in one tab, skip tabs entirely.
  if (specialist.isEmpty) {
    return _showSingleGrid(context,
        clubs: clubs,
        selectedClub: selectedClub,
        skillArea: skillArea,
        userId: userId);
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
      skillArea: skillArea,
      userId: userId,
    ),
  );
}

/// Fallback: single grid with no tabs (when all clubs are common).
Future<String?> _showSingleGrid(
  BuildContext context, {
  required List<String> clubs,
  required String selectedClub,
  SkillArea? skillArea,
  String? userId,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Select Club',
              style: TextStyle(color: ColorTokens.textPrimary),
            ),
          ),
          if (skillArea != null && userId != null)
            IconButton(
              icon: const Icon(Icons.tune, color: ColorTokens.textSecondary),
              tooltip: 'Map clubs to ${skillArea.dbValue}',
              onPressed: () => _showSkillAreaClubMapper(
                  ctx, skillArea: skillArea, userId: userId),
            ),
        ],
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
  final SkillArea? skillArea;
  final String? userId;

  const _TabbedClubPicker({
    required this.common,
    required this.specialist,
    required this.selectedClub,
    required this.initialTab,
    this.skillArea,
    this.userId,
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Club',
                    style: TextStyle(color: ColorTokens.textPrimary),
                  ),
                ),
                if (skillArea != null && userId != null)
                  IconButton(
                    icon: const Icon(Icons.tune,
                        color: ColorTokens.textSecondary),
                    tooltip: 'Map clubs to ${skillArea!.dbValue}',
                    onPressed: () => _showSkillAreaClubMapper(
                        context, skillArea: skillArea!, userId: userId!),
                  ),
              ],
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
          height: 400,
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
        childAspectRatio: 1.0,
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
                  fontSize: TypographyTokens.headerSize,
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

/// Opens a dialog to map/unmap clubs to a specific skill area.
void _showSkillAreaClubMapper(
  BuildContext context, {
  required SkillArea skillArea,
  required String userId,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _SkillAreaClubMapperDialog(
      skillArea: skillArea,
      userId: userId,
    ),
  );
}

/// Maps all club types to a single skill area (reverse of the bag screen dialog
/// which maps all skill areas to a single club).
class _SkillAreaClubMapperDialog extends ConsumerWidget {
  final SkillArea skillArea;
  final String userId;

  const _SkillAreaClubMapperDialog({
    required this.skillArea,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMappings =
        ref.watch(skillAreaMappingsProvider(userId)).valueOrNull ?? [];
    final mappedClubs = allMappings
        .where((m) => m.skillArea == skillArea)
        .map((m) => m.clubType)
        .toSet();

    // Only show club types the user has in their bag.
    final userBag = ref.watch(userBagProvider(userId)).valueOrNull ?? [];
    final bagClubTypes = userBag.map((c) => c.clubType).toList();

    final color = ColorTokens.skillArea(skillArea);

    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: Text(
        'Clubs for ${skillArea.dbValue}:',
        style: const TextStyle(color: ColorTokens.textPrimary),
      ),
      content: SizedBox(
        width: 300,
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: SpacingTokens.sm,
          crossAxisSpacing: SpacingTokens.sm,
          childAspectRatio: 1.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final clubType in bagClubTypes)
              ZxPillButton(
                label: _clubLabel(clubType),
                size: ZxPillSize.md,
                expanded: true,
                centered: true,
                color: mappedClubs.contains(clubType) ? color : null,
                variant: mappedClubs.contains(clubType)
                    ? ZxPillVariant.primary
                    : ZxPillVariant.tertiary,
                onTap: () async {
                  try {
                    await ref
                        .read(clubRepositoryProvider)
                        .updateSkillAreaMapping(
                          userId,
                          clubType,
                          skillArea,
                          !mappedClubs.contains(clubType),
                        );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
      actions: [
        ZxPillButton(
          label: 'Done',
          variant: ZxPillVariant.primary,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
