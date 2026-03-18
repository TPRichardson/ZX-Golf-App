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

/// Shows a reactive club picker dialog. Watches clubsForSkillAreaProvider
/// so edits via "Edit Clubs" are reflected immediately.
Future<String?> showClubGridPicker(
  BuildContext context, {
  required List<String> clubs,
  required String selectedClub,
  SkillArea? skillArea,
  String? userId,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _ReactiveClubPicker(
      selectedClub: selectedClub,
      skillArea: skillArea,
      userId: userId,
    ),
  );
}

/// Reactive club picker that watches skill area clubs and rebuilds
/// when mappings change (e.g. after "Edit Clubs").
class _ReactiveClubPicker extends ConsumerWidget {
  final String selectedClub;
  final SkillArea? skillArea;
  final String? userId;

  const _ReactiveClubPicker({
    required this.selectedClub,
    this.skillArea,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reactively watch clubs for this skill area.
    final clubsAsync = (skillArea != null && userId != null)
        ? ref.watch(clubsForSkillAreaProvider((userId!, skillArea!)))
        : null;

    final clubs = clubsAsync?.valueOrNull ?? [];
    final sorted = List.of(clubs)
      ..sort((a, b) => a.clubType.index.compareTo(b.clubType.index));
    final clubNames = sorted.map((c) => c.clubType.dbValue).toList();

    final common = clubNames.where((c) => _commonClubs.contains(c)).toList();
    final specialist =
        clubNames.where((c) => !_commonClubs.contains(c)).toList();

    final hasSpecialist = specialist.isNotEmpty;

    if (!hasSpecialist) {
      // Single grid — no tabs needed.
      return AlertDialog(
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
              ZxPillButton(
                label: 'Edit Clubs',
                variant: ZxPillVariant.secondary,
                onTap: () => _showSkillAreaClubMapper(
                    context, skillArea: skillArea!, userId: userId!),
              ),
          ],
        ),
        contentPadding: const EdgeInsets.all(SpacingTokens.md),
        content: SizedBox(
          width: double.maxFinite,
          child: _ClubGrid(
            clubs: clubNames,
            selectedClub: selectedClub,
            onSelect: (club) => Navigator.pop(context, club),
          ),
        ),
      );
    }

    // Tabbed picker.
    final initialTab = specialist.contains(selectedClub) ? 1 : 0;

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
                  ZxPillButton(
                    label: 'Edit Clubs',
                    variant: ZxPillVariant.secondary,
                    onTap: () => _showSkillAreaClubMapper(
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
    final bagClubTypes = userBag.map((c) => c.clubType).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

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
