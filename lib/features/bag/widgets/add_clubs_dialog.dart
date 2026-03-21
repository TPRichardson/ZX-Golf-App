import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

/// Multi-select dialog with Common / Full tabs.
class AddClubsDialog extends StatefulWidget {
  final List<ClubType> commonClubs;
  final Map<String, List<ClubType>> fullClubGroups;
  final Set<ClubType> existingTypes;
  final ValueChanged<Set<ClubType>> onAdd;

  const AddClubsDialog({
    super.key,
    required this.commonClubs,
    required this.fullClubGroups,
    required this.existingTypes,
    required this.onAdd,
  });

  @override
  State<AddClubsDialog> createState() => _AddClubsDialogState();
}

class _AddClubsDialogState extends State<AddClubsDialog> {
  final _selected = <ClubType>{};
  final _expanded = <String>{};

  void _toggle(ClubType type) {
    setState(() {
      if (_selected.contains(type)) {
        _selected.remove(type);
      } else {
        _selected.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Clubs',
                style: TextStyle(color: ColorTokens.textPrimary)),
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
                Tab(text: 'Full'),
              ],
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: TabBarView(
            children: [
              ClubGrid(
                clubs: widget.commonClubs,
                selected: _selected,
                existingTypes: widget.existingTypes,
                onToggle: _toggle,
              ),
              FullClubList(
                groups: widget.fullClubGroups,
                selected: _selected,
                existingTypes: widget.existingTypes,
                expanded: _expanded,
                onToggle: _toggle,
                onToggleGroup: (group) => setState(() {
                  if (_expanded.contains(group)) {
                    _expanded.remove(group);
                  } else {
                    _expanded.add(group);
                  }
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed:
                _selected.isEmpty ? null : () => widget.onAdd(_selected),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryDefault,
            ),
            child: Text(
                'Add${_selected.isEmpty ? '' : ' (${_selected.length})'}'),
          ),
        ],
      ),
    );
  }
}

/// 3-column grid of tappable club cells with selection state.
class ClubGrid extends StatelessWidget {
  final List<ClubType> clubs;
  final Set<ClubType> selected;
  final Set<ClubType> existingTypes;
  final ValueChanged<ClubType> onToggle;

  const ClubGrid({
    super.key,
    required this.clubs,
    required this.selected,
    required this.existingTypes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: SpacingTokens.sm,
        crossAxisSpacing: SpacingTokens.sm,
        childAspectRatio: 2.0,
      ),
      itemCount: clubs.length,
      itemBuilder: (context, index) {
        final club = clubs[index];
        final isOwned = existingTypes.contains(club);
        final isSelected = selected.contains(club);
        return InkWell(
          onTap: isOwned ? null : () => onToggle(club),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          child: Opacity(
            opacity: isOwned ? 0.35 : 1.0,
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
                  club.dbValue,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? ColorTokens.primaryDefault
                        : ColorTokens.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Expandable category list showing all clubs.
class FullClubList extends StatelessWidget {
  final Map<String, List<ClubType>> groups;
  final Set<ClubType> selected;
  final Set<ClubType> existingTypes;
  final Set<String> expanded;
  final ValueChanged<ClubType> onToggle;
  final ValueChanged<String> onToggleGroup;

  const FullClubList({
    super.key,
    required this.groups,
    required this.selected,
    required this.existingTypes,
    required this.expanded,
    required this.onToggle,
    required this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final entry in groups.entries)
          _buildGroup(entry.key, entry.value),
      ],
    );
  }

  Widget _buildGroup(String category, List<ClubType> clubs) {
    if (clubs.length == 1) {
      final club = clubs.first;
      final isOwned = existingTypes.contains(club);
      final isSelected = selected.contains(club);
      return Padding(
        padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
        child: Opacity(
          opacity: isOwned ? 0.35 : 1.0,
          child: InkWell(
          onTap: isOwned ? null : () => onToggle(club),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm + 2,
            ),
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
            child: Text(
              category,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? ColorTokens.primaryDefault
                    : ColorTokens.textPrimary,
              ),
            ),
          ),
        ),
        ),
      );
    }

    final isExpanded = expanded.contains(category);
    final selectedInGroup = clubs.where((c) => selected.contains(c)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => onToggleGroup(category),
            borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm + 2,
              ),
              decoration: BoxDecoration(
                color: ColorTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
                border: Border.all(color: ColorTokens.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                  if (selectedInGroup > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.xs + 2, vertical: 2),
                      margin:
                          const EdgeInsets.only(right: SpacingTokens.xs),
                      decoration: BoxDecoration(
                        color: ColorTokens.primaryDefault
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                            ShapeTokens.radiusSegmented),
                      ),
                      child: Text('$selectedInGroup',
                          style: const TextStyle(
                            fontSize: TypographyTokens.bodySmSize,
                            color: ColorTokens.primaryDefault,
                          )),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: ColorTokens.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: SpacingTokens.sm),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: SpacingTokens.sm,
                crossAxisSpacing: SpacingTokens.sm,
                childAspectRatio: 2.0,
                children: clubs.map((club) {
                  final isOwned = existingTypes.contains(club);
                  final isSelected = selected.contains(club);
                  return Opacity(
                    opacity: isOwned ? 0.35 : 1.0,
                    child: InkWell(
                    onTap: isOwned ? null : () => onToggle(club),
                    borderRadius:
                        BorderRadius.circular(ShapeTokens.radiusGrid),
                    child: Container(
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
                          club.dbValue,
                          style: TextStyle(
                            fontSize: TypographyTokens.bodySize,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? ColorTokens.primaryDefault
                                : ColorTokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
