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

/// Result from the club picker — club UUID + optional shot intent.
class ClubPickerResult {
  final String clubId;
  final String? shotShape;
  final int? shotEffort;

  const ClubPickerResult({
    required this.clubId,
    this.shotShape,
    this.shotEffort,
  });
}

/// Shows a reactive club picker dialog. Returns club UUID + shot intent.
Future<ClubPickerResult?> showClubGridPicker(
  BuildContext context, {
  required List<String> clubs,
  required String selectedClub,
  SkillArea? skillArea,
  String? userId,
  bool showShotIntent = false,
  String? initialShape,
  int? initialEffort,
  ValueChanged<bool>? onToggleShotIntent,
}) {
  return showDialog<ClubPickerResult>(
    context: context,
    builder: (ctx) => _ReactiveClubPicker(
      selectedClub: selectedClub,
      skillArea: skillArea,
      userId: userId,
      showShotIntent: showShotIntent,
      initialShape: initialShape,
      initialEffort: initialEffort,
      onToggleShotIntent: onToggleShotIntent,
    ),
  );
}

/// Reactive club picker that watches skill area clubs and rebuilds
/// when mappings change (e.g. after "Edit Clubs").
class _ReactiveClubPicker extends ConsumerStatefulWidget {
  final String selectedClub;
  final SkillArea? skillArea;
  final String? userId;
  final bool showShotIntent;
  final String? initialShape;
  final int? initialEffort;
  final ValueChanged<bool>? onToggleShotIntent;

  const _ReactiveClubPicker({
    required this.selectedClub,
    required this.skillArea,
    required this.userId,
    this.showShotIntent = false,
    this.initialShape,
    this.initialEffort,
    this.onToggleShotIntent,
  });

  @override
  ConsumerState<_ReactiveClubPicker> createState() =>
      _ReactiveClubPickerState();
}

class _ReactiveClubPickerState extends ConsumerState<_ReactiveClubPicker> {
  late bool _showIntent;
  String? _shape;
  int? _effort;

  @override
  void initState() {
    super.initState();
    _showIntent = widget.showShotIntent;
    _shape = widget.initialShape;
    _effort = widget.initialEffort;
  }

  void _selectClub(String clubId) {
    Navigator.pop(context, ClubPickerResult(
      clubId: clubId,
      shotShape: _showIntent ? _shape : null,
      shotEffort: _showIntent ? _effort : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Reactively watch clubs for this skill area.
    final clubsAsync = (widget.skillArea != null && widget.userId != null)
        ? ref.watch(clubsForSkillAreaProvider((widget.userId!, widget.skillArea!)))
        : null;

    final clubs = clubsAsync?.valueOrNull ?? [];
    final sorted = List.of(clubs)
      ..sort((a, b) => a.clubType.index.compareTo(b.clubType.index));
    final clubNames = sorted.map((c) => c.clubType.dbValue).toList();
    // Map name → ID for returning the UUID on selection.
    final nameToId = {for (final c in sorted) c.clubType.dbValue: c.clubId};

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
            if (widget.skillArea != null && widget.userId != null)
              ZxPillButton(
                label: 'Edit Clubs',
                variant: ZxPillVariant.secondary,
                onTap: () => _showSkillAreaClubMapper(
                    context, skillArea: widget.skillArea!, userId: widget.userId!),
              ),
          ],
        ),
        contentPadding: const EdgeInsets.all(SpacingTokens.md),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ClubGrid(
                clubs: clubNames,
                selectedClub: widget.selectedClub,
                onSelect: (club) => _selectClub(nameToId[club]!),
              ),
              _buildShotIntentSection(),
            ],
          ),
        ),
      );
    }

    // Tabbed picker.
    final initialTab = specialist.contains(widget.selectedClub) ? 1 : 0;

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
                if (widget.skillArea != null && widget.userId != null)
                  ZxPillButton(
                    label: 'Edit Clubs',
                    variant: ZxPillVariant.secondary,
                    onTap: () => _showSkillAreaClubMapper(
                        context, skillArea: widget.skillArea!, userId: widget.userId!),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    _ClubGrid(
                      clubs: common,
                      selectedClub: widget.selectedClub,
                      onSelect: (club) => _selectClub(nameToId[club]!),
                    ),
                    _ClubGrid(
                      clubs: specialist,
                      selectedClub: widget.selectedClub,
                      onSelect: (club) => _selectClub(nameToId[club]!),
                    ),
                  ],
                ),
              ),
              _buildShotIntentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShotIntentSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: SpacingTokens.md),
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
                  widget.onToggleShotIntent?.call(v);
                },
              ),
            ),
          ],
        ),
        if (_showIntent) ...[
          const SizedBox(height: SpacingTokens.sm),
          _intentLabel('Shape'),
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
          _intentLabel('Effort'),
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
    ),
    );
  }

  static Widget _intentLabel(String text) {
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
