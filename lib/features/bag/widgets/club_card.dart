import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// S15 §15.8 — Club card for bag list display.
// Shows club type square, make/model, loft, carry, and status.

class ClubCard extends ConsumerWidget {
  final UserClub club;
  final VoidCallback? onTap;

  const ClubCard({
    super.key,
    required this.club,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider(club.clubId));
    final carry = profileAsync.whenOrNull(data: (p) => p?.carryDistance);
    final skillAreas =
        ref.watch(skillAreasForClubProvider((club.userId, club.clubType)));

    return ZxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          const SizedBox(width: SpacingTokens.md),
          // Left column: club name square + model.
          SizedBox(
            width: 56,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorTokens.surfaceRaised,
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusCard),
                ),
                alignment: Alignment.center,
                child: Text(
                  clubTypeShort(club.clubType),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showMakeModelDialog(context, ref),
                child: Text(
                  _makeModelLabel(club.make, club.model),
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySmSize,
                    color: _hasMakeOrModel(club.make, club.model)
                        ? ColorTokens.textSecondary
                        : ColorTokens.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Flexible(
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showSkillAreaMappingDialog(context, ref),
              child: skillAreas.isEmpty
                  ? ZxPillButton(
                      label: 'Map',
                      size: ZxPillSize.sm,
                      variant: ZxPillVariant.tertiary,
                      onTap: () => _showSkillAreaMappingDialog(context, ref),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 87, // 2 × 42px pills + 3px gap
                          child: Wrap(
                            spacing: 3,
                            runSpacing: 3,
                            children: [
                              for (final area in skillAreas.take(4))
                                SizedBox(
                                  width: 42,
                                  child: ZxPillButton(
                                    label: _skillAreaShort(area),
                                    size: ZxPillSize.sm,
                                    expanded: true,
                                    centered: true,
                                    color: ColorTokens.skillArea(area),
                                    onTap: () =>
                                        _showSkillAreaMappingDialog(context, ref),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (skillAreas.length > 4)
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              '+${skillAreas.length - 4}',
                              style: TextStyle(
                                fontSize: TypographyTokens.bodySmSize,
                                color: ColorTokens.textTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Loft field.
          _DataField(
            value: club.loft != null
                ? '${_formatLoft(club.loft!)}°'
                : null,
            placeholder: 'Loft',
            onTap: () => _showLoftDialog(context, ref),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Carry field — render invisible placeholder when club has no carry range
          // (e.g. putter) so all rows stay aligned.
          Visibility(
            visible: _carryRange(club.clubType) != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: _DataField(
              value: carry != null ? '${carry.toStringAsFixed(0)}y' : null,
              placeholder: 'Carry',
              onTap: () {
                if (_carryRange(club.clubType) != null) {
                  _showCarryDialog(context, ref);
                }
              },
            ),
          ),
          if (club.status == UserClubStatus.retired) ...[
            const SizedBox(width: SpacingTokens.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: ColorTokens.textTertiary.withAlpha(30),
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusBadge),
              ),
              child: Text(
                'Retired',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColorTokens.textTertiary,
                    ),
              ),
            ),
          ],
          const SizedBox(width: SpacingTokens.xs),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Icon(
              Icons.chevron_right,
              color: ColorTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMakeModelDialog(
      BuildContext context, WidgetRef ref) async {
    // Collect brand+model combos from the user's bag, ranked by frequency.
    final bag = ref.read(userBagProvider(club.userId)).valueOrNull ?? [];
    final counts = <({String make, String model}), int>{};
    for (final c in bag) {
      if (c.make != null && c.make!.isNotEmpty) {
        final key = (make: c.make!, model: c.model ?? '');
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCombos = sorted.map((e) => e.key).toList();

    final result = await showDialog<({String make, String model, List<String>? applyToClubIds})>(
      context: context,
      builder: (ctx) => _MakeModelDialog(
        clubLabel: _clubFullName(club.clubType),
        initialMake: club.make ?? '',
        initialModel: club.model ?? '',
        existingCombos: topCombos,
        bagClubs: bag,
      ),
    );

    if (result != null) {
      final companion = UserClubsCompanion(
        make: drift.Value(result.make.isEmpty ? null : result.make),
        model: drift.Value(result.model.isEmpty ? null : result.model),
      );
      final repo = ref.read(clubRepositoryProvider);
      if (result.applyToClubIds != null && result.applyToClubIds!.isNotEmpty) {
        for (final id in result.applyToClubIds!) {
          await repo.updateClub(id, companion);
        }
      } else {
        await repo.updateClub(club.clubId, companion);
      }
    }
  }

  Future<void> _showLoftDialog(BuildContext context, WidgetRef ref) async {
    final range = _loftRange(club.clubType);
    final currentLoft = club.loft?.round() ?? range.middle;

    final selected = await showDialog<double>(
      context: context,
      builder: (ctx) => _ScrollWheelPickerDialog(
        title: 'Loft',
        suffix: '°',
        min: range.min,
        max: range.max,
        initial: currentLoft.clamp(range.min, range.max),
        allowHalf: true,
      ),
    );

    if (selected != null) {
      await ref.read(clubRepositoryProvider).updateClub(
            club.clubId,
            UserClubsCompanion(
              loft: drift.Value(selected),
            ),
          );
    }
  }

  /// Returns carry range scaled by specific club number, or null for putter.
  static ({int min, int max, int middle})? _carryRange(ClubType type) {
    if (type == ClubType.putter || type == ClubType.chipper) return null;
    if (type == ClubType.driver) return (min: 180, max: 350, middle: 260);
    // Parse club number (1-9) from dbValue for per-club scaling.
    final db = type.dbValue;
    if (db.startsWith('W')) {
      final n = int.tryParse(db.substring(1)) ?? 5;
      // W1=170-350, W3=150-310, W5=140-280, W7=120-250, W9=110-230
      return (
        min: 180 - n * 10,
        max: 360 - n * 15,
        middle: (180 - n * 10 + 360 - n * 15) ~/ 2,
      );
    }
    if (db.startsWith('H')) {
      final n = int.tryParse(db.substring(1)) ?? 4;
      // H2=150-300, H4=120-260, H6=100-220, H9=70-175
      return (
        min: 160 - n * 10,
        max: 320 - n * 15,
        middle: (160 - n * 10 + 320 - n * 15) ~/ 2,
      );
    }
    if (db.startsWith('i')) {
      final n = int.tryParse(db.substring(1)) ?? 7;
      // i1=150-280, i3=130-250, i5=110-220, i7=90-190, i9=70-175
      final min = 160 - n * 10;
      final max = (295 - n * 13.3).round();
      return (min: min, max: max, middle: (min + max) ~/ 2);
    }
    // Wedges: PW highest, LW bottoms out at 40.
    return switch (type) {
      ClubType.pw => (min: 70, max: 170, middle: 120),
      ClubType.aw => (min: 60, max: 155, middle: 105),
      ClubType.gw => (min: 55, max: 145, middle: 100),
      ClubType.sw => (min: 50, max: 130, middle: 85),
      ClubType.uw => (min: 45, max: 120, middle: 75),
      ClubType.lw => (min: 40, max: 110, middle: 65),
      _ => (min: 40, max: 160, middle: 100),
    };
  }

  static ({int min, int max, int middle}) _loftRange(ClubType type) {
    if (type == ClubType.driver) return (min: 3, max: 20, middle: 10);
    if (type == ClubType.putter) return (min: 0, max: 10, middle: 4);
    if (type == ClubType.chipper) return (min: 25, max: 45, middle: 35);
    if (type.dbValue.startsWith('W')) return (min: 5, max: 30, middle: 15);
    if (type.dbValue.startsWith('H')) return (min: 10, max: 40, middle: 22);
    if (type.dbValue.startsWith('i')) return (min: 10, max: 50, middle: 30);
    // Wedges: PW, AW, GW, SW, UW, LW.
    return (min: 30, max: 80, middle: 50);
  }

  Future<void> _showCarryDialog(BuildContext context, WidgetRef ref) async {
    final range = _carryRange(club.clubType);
    if (range == null) return; // Putter — no carry.

    final profile = ref.read(activeProfileProvider(club.clubId)).valueOrNull;
    final currentCarry = profile?.carryDistance?.round() ?? range.middle;

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => _ScrollWheelPickerDialog(
        title: 'Carry',
        suffix: 'y',
        min: range.min,
        max: range.max,
        initial: currentCarry.clamp(range.min, range.max),
      ),
    );

    if (selected != null) {
      await ref.read(clubRepositoryProvider).addPerformanceProfile(
            club.clubId,
            ClubPerformanceProfilesCompanion(
              effectiveFromDate: drift.Value(DateTime.now()),
              carryDistance: drift.Value(selected.toDouble()),
              dispersionLeft: drift.Value(profile?.dispersionLeft),
              dispersionRight: drift.Value(profile?.dispersionRight),
              dispersionShort: drift.Value(profile?.dispersionShort),
              dispersionLong: drift.Value(profile?.dispersionLong),
            ),
          );
      ref.invalidate(activeProfileProvider(club.clubId));
    }
  }

  Future<void> _showSkillAreaMappingDialog(
      BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ClubSkillAreaDialog(
        clubType: club.clubType,
        userId: club.userId,
      ),
    );
  }

  static String clubTypeShort(ClubType type) {
    final db = type.dbValue;
    // Woods: "W3" → "3w", Hybrids: "H4" → "4h".
    if (db.startsWith('W') || db.startsWith('H')) {
      return '${db.substring(1)}${db[0].toLowerCase()}';
    }
    // Irons: "i4" → "4i".
    if (db.startsWith('i')) {
      return '${db.substring(1)}i';
    }
    return switch (type) {
      ClubType.driver => 'Dr',
      ClubType.putter => 'Pt',
      ClubType.chipper => 'Ch',
      ClubType.pw => 'Pw',
      ClubType.aw => 'Aw',
      ClubType.gw => 'Gw',
      ClubType.sw => 'Sw',
      ClubType.uw => 'Uw',
      ClubType.lw => 'Lw',
      _ => db,
    };
  }

  static bool _hasMakeOrModel(String? make, String? model) {
    return (make != null && make.isNotEmpty) ||
        (model != null && model.isNotEmpty);
  }

  static String _makeModelLabel(String? make, String? model) {
    final hasMake = make != null && make.isNotEmpty;
    final hasModel = model != null && model.isNotEmpty;
    if (!hasMake && !hasModel) return 'Model';
    final brandPrefix = hasMake
        ? make.substring(0, make.length >= 2 ? 2 : make.length)
        : '';
    if (hasMake && hasModel) return '$brandPrefix/$model';
    if (hasMake) return brandPrefix;
    return model!;
  }

  static String _clubFullName(ClubType type) {
    final db = type.dbValue;
    if (type == ClubType.driver) return 'Driver';
    if (type == ClubType.putter) return 'Putter';
    if (type == ClubType.chipper) return 'Chipper';
    if (db.startsWith('W')) return '${db.substring(1)} Wood';
    if (db.startsWith('H')) return '${db.substring(1)} Hybrid';
    if (db.startsWith('i')) return '${db.substring(1)} Iron';
    return switch (type) {
      ClubType.pw => 'Pitching Wedge',
      ClubType.aw => 'Approach Wedge',
      ClubType.gw => 'Gap Wedge',
      ClubType.sw => 'Sand Wedge',
      ClubType.uw => 'Utility Wedge',
      ClubType.lw => 'Lob Wedge',
      _ => db,
    };
  }

  static String _formatLoft(double v) {
    if (v % 1 == 0.5) return v.toStringAsFixed(1);
    return v.toStringAsFixed(0);
  }

  static String _skillAreaShort(SkillArea area) {
    return switch (area) {
      SkillArea.driving => 'Dr',
      SkillArea.woods => 'Wo',
      SkillArea.irons => 'Ir',
      SkillArea.pitching => 'Pi',
      SkillArea.chipping => 'Ch',
      SkillArea.bunkers => 'Bu',
      SkillArea.putting => 'Pu',
    };
  }
}

/// Make/model picker with popular brand picklist + custom free text.
class _MakeModelDialog extends StatefulWidget {
  final String clubLabel;
  final String initialMake;
  final String initialModel;
  final List<({String make, String model})> existingCombos;
  final List<UserClub> bagClubs;

  const _MakeModelDialog({
    required this.clubLabel,
    required this.initialMake,
    required this.initialModel,
    this.existingCombos = const [],
    this.bagClubs = const [],
  });

  @override
  State<_MakeModelDialog> createState() => _MakeModelDialogState();
}

class _MakeModelDialogState extends State<_MakeModelDialog> {
  static const _brands = [
    'Callaway',
    'Cobra',
    'Mizuno',
    'Ping',
    'PXG',
    'Srixon',
    'TaylorMade',
    'Titleist',
    'Wilson Staff',
  ];

  late String _selectedBrand;
  late bool _isCustom;
  late final TextEditingController _customCtrl;
  late final TextEditingController _modelCtrl;

  @override
  void initState() {
    super.initState();
    final match = _brands.indexWhere(
      (b) => b.toLowerCase() == widget.initialMake.toLowerCase(),
    );
    if (match >= 0) {
      _selectedBrand = _brands[match];
      _isCustom = false;
    } else {
      _selectedBrand = '';
      _isCustom = widget.initialMake.isNotEmpty;
    }
    _customCtrl = TextEditingController(
      text: _isCustom ? widget.initialMake : '',
    );
    _modelCtrl = TextEditingController(text: widget.initialModel);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  String get _make => _isCustom ? _customCtrl.text.trim() : _selectedBrand;

  Future<void> _showBrandPicker(BuildContext context) async {
    final result = await showDialog<({String brand, bool isCustom})>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
        ),
        title: const Text(
          'Select Brand',
          style: TextStyle(color: ColorTokens.textPrimary),
        ),
        content: SizedBox(
          width: 300,
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: SpacingTokens.xs,
            crossAxisSpacing: SpacingTokens.xs,
            childAspectRatio: 2.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final brand in _brands)
                ZxPillButton(
                  label: brand,
                  size: ZxPillSize.sm,
                  expanded: true,
                  centered: true,
                  variant: (!_isCustom && _selectedBrand == brand)
                      ? ZxPillVariant.primary
                      : ZxPillVariant.secondary,
                  onTap: () => Navigator.pop(
                    ctx,
                    (brand: brand, isCustom: false),
                  ),
                ),
              ZxPillButton(
                label: 'Custom',
                size: ZxPillSize.sm,
                expanded: true,
                centered: true,
                variant: _isCustom
                    ? ZxPillVariant.primary
                    : ZxPillVariant.tertiary,
                onTap: () => Navigator.pop(
                  ctx,
                  (brand: '', isCustom: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && context.mounted) {
      setState(() {
        if (result.isCustom) {
          _isCustom = true;
          _selectedBrand = '';
        } else {
          _isCustom = false;
          _selectedBrand = result.brand;
        }
      });
      // Show custom brand text entry if custom was selected.
      if (result.isCustom && context.mounted) {
        final customName = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final ctrl = TextEditingController(text: _customCtrl.text);
            return AlertDialog(
              backgroundColor: ColorTokens.surfaceModal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
              ),
              title: const Text(
                'Custom Brand',
                style: TextStyle(color: ColorTokens.textPrimary),
              ),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: ColorTokens.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Brand name',
                  labelStyle: TextStyle(color: ColorTokens.textTertiary),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              actions: [
                ZxPillButton(
                  label: 'Cancel',
                  variant: ZxPillVariant.tertiary,
                  onTap: () => Navigator.pop(ctx),
                ),
                ZxPillButton(
                  label: 'Save',
                  variant: ZxPillVariant.primary,
                  onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
                ),
              ],
            );
          },
        );
        if (customName != null && customName.isNotEmpty && context.mounted) {
          setState(() => _customCtrl.text = customName);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 24, 24, 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.clubLabel,
            style: const TextStyle(
              fontSize: TypographyTokens.displayLgSize,
              fontWeight: TypographyTokens.displayLgWeight,
              color: ColorTokens.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close,
              color: ColorTokens.textTertiary,
              size: 24,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            ZxPillButton(
              label: _isCustom
                  ? (_customCtrl.text.isNotEmpty ? _customCtrl.text : 'Custom')
                  : (_selectedBrand.isNotEmpty ? _selectedBrand : 'Select brand'),
              size: ZxPillSize.md,
              expanded: true,
              centered: true,
              variant: (_selectedBrand.isNotEmpty || _isCustom)
                  ? ZxPillVariant.primary
                  : ZxPillVariant.secondary,
              onTap: () => _showBrandPicker(context),
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'Model',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            TextField(
              controller: _modelCtrl,
              style: const TextStyle(color: ColorTokens.textPrimary),
              decoration: const InputDecoration(
                hintText: '(Optional)',
                hintStyle: TextStyle(color: ColorTokens.textTertiary),
              ),
            ),
            if (widget.existingCombos.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.md),
              Text(
                'From your bag',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textTertiary,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Wrap(
                spacing: SpacingTokens.sm,
                runSpacing: SpacingTokens.sm,
                children: [
                  for (final combo in widget.existingCombos.take(3))
                    ZxPillButton(
                      label: combo.model.isNotEmpty
                          ? '${combo.make} ${combo.model}'
                          : combo.make,
                      size: ZxPillSize.md,
                      variant: ZxPillVariant.secondary,
                      onTap: () {
                        final brandMatch = _brands.indexWhere(
                          (b) => b.toLowerCase() == combo.make.toLowerCase(),
                        );
                        setState(() {
                          if (brandMatch >= 0) {
                            _selectedBrand = _brands[brandMatch];
                            _isCustom = false;
                          } else {
                            _isCustom = true;
                            _selectedBrand = '';
                            _customCtrl.text = combo.make;
                          }
                          _modelCtrl.text = combo.model;
                        });
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        SpacingTokens.md, 0, SpacingTokens.md, SpacingTokens.md,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: ZxPillButton(
                label: 'Apply to many',
                variant: ZxPillVariant.secondary,
                expanded: true,
                centered: true,
                onTap: () => _showMultiClubPicker(context),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxPillButton(
                label: 'Save',
                variant: ZxPillVariant.primary,
                expanded: true,
                centered: true,
                onTap: () => Navigator.pop(
                  context,
                  (make: _make, model: _modelCtrl.text.trim(), applyToClubIds: null as List<String>?),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showMultiClubPicker(BuildContext context) async {
    final make = _make;
    final model = _modelCtrl.text.trim();
    if (make.isEmpty) return;

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _MultiClubPickerDialog(clubs: widget.bagClubs),
    );

    if (selected != null && selected.isNotEmpty && context.mounted) {
      Navigator.pop(
        context,
        (make: make, model: model, applyToClubIds: selected),
      );
    }
  }
}

/// Grid picker for selecting multiple clubs to apply make/model to.
class _MultiClubPickerDialog extends StatefulWidget {
  final List<UserClub> clubs;

  const _MultiClubPickerDialog({required this.clubs});

  @override
  State<_MultiClubPickerDialog> createState() => _MultiClubPickerDialogState();
}

class _MultiClubPickerDialogState extends State<_MultiClubPickerDialog> {
  final _selected = <String>{};

  late final List<UserClub> _sortedClubs;

  @override
  void initState() {
    super.initState();
    _sortedClubs = List.of(widget.clubs)
      ..sort((a, b) => ClubType.values.indexOf(a.clubType)
          .compareTo(ClubType.values.indexOf(b.clubType)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Clubs',
            style: TextStyle(color: ColorTokens.textPrimary),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close,
              color: ColorTokens.textTertiary,
              size: 24,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        height: 480,
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: SpacingTokens.sm,
          crossAxisSpacing: SpacingTokens.sm,
          children: [
            for (final club in _sortedClubs)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selected.contains(club.clubId)) {
                      _selected.remove(club.clubId);
                    } else {
                      _selected.add(club.clubId);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _selected.contains(club.clubId)
                        ? ColorTokens.primaryDefault
                        : ColorTokens.surfaceRaised,
                    borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                    border: Border.all(
                      color: _selected.contains(club.clubId)
                          ? ColorTokens.primaryDefault
                          : ColorTokens.surfaceBorder,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ClubCard.clubTypeShort(club.clubType),
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: FontWeight.w600,
                      color: _selected.contains(club.clubId)
                          ? ColorTokens.surfaceBase
                          : ColorTokens.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        ZxPillButton(
          label: 'Save',
          variant: ZxPillVariant.primary,
          onTap: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
        ),
      ],
    );
  }
}

/// Per-club skill area mapping dialog. Toggle which areas this club maps to.
class _ClubSkillAreaDialog extends ConsumerWidget {
  final ClubType clubType;
  final String userId;

  const _ClubSkillAreaDialog({
    required this.clubType,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMappings =
        ref.watch(skillAreaMappingsProvider(userId)).valueOrNull ?? [];
    final clubMappings =
        allMappings.where((m) => m.clubType == clubType).toList();
    final mappedAreas = clubMappings.map((m) => m.skillArea).toSet();

    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: Text(
        '${clubType.dbValue} available for drills in:',
        style: const TextStyle(color: ColorTokens.textPrimary),
      ),
      content: SizedBox(
        width: 300,
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: SpacingTokens.xs,
          crossAxisSpacing: SpacingTokens.xs,
          childAspectRatio: 2.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final area in const [
              SkillArea.driving,
              SkillArea.woods,
              SkillArea.irons,
              SkillArea.pitching,
              SkillArea.chipping,
              SkillArea.bunkers,
              SkillArea.putting,
            ])
              _buildAreaTile(context, ref, area, mappedAreas),
          ],
        ),
      ),
      actions: [
        ZxPillButton(
          label: 'Cancel',
          variant: ZxPillVariant.tertiary,
          onTap: () => Navigator.pop(context),
        ),
        ZxPillButton(
          label: 'Done',
          variant: ZxPillVariant.primary,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildAreaTile(
    BuildContext context,
    WidgetRef ref,
    SkillArea area,
    Set<SkillArea> mappedAreas,
  ) {
    final isMapped = mappedAreas.contains(area);
    final color = ColorTokens.skillArea(area);

    return ZxPillButton(
      label: area.dbValue,
      size: ZxPillSize.md,
      expanded: true,
      centered: true,
      color: isMapped ? color : null,
      variant: isMapped ? ZxPillVariant.primary : ZxPillVariant.tertiary,
      onTap: () async {
              try {
                await ref
                    .read(clubRepositoryProvider)
                    .updateSkillAreaMapping(
                      userId,
                      clubType,
                      area,
                      !isMapped,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
    );
  }
}

/// Scroll-wheel picker dialog for integer values with optional "Enter value" sub-dialog.
/// Used for both loft and carry pickers.
class _ScrollWheelPickerDialog extends StatefulWidget {
  final String title;
  final String suffix;
  final int min;
  final int max;
  final int initial;
  final bool allowHalf;

  const _ScrollWheelPickerDialog({
    required this.title,
    required this.suffix,
    required this.min,
    required this.max,
    required this.initial,
    this.allowHalf = false,
  });

  @override
  State<_ScrollWheelPickerDialog> createState() =>
      _ScrollWheelPickerDialogState();
}

class _ScrollWheelPickerDialogState extends State<_ScrollWheelPickerDialog> {
  late FixedExtentScrollController _scrollCtrl;
  late double _selected;
  bool _editing = false;
  bool _showHalves = false;
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toDouble();
    _scrollCtrl = FixedExtentScrollController(
      initialItem: widget.initial - widget.min,
    );
    _textCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  String _formatValue(double v) {
    if (v % 1 == 0.5) return '${v.toStringAsFixed(1)}${widget.suffix}';
    return '${v.toStringAsFixed(0)}${widget.suffix}';
  }

  int _valueToIndex(double v) {
    if (_showHalves) return ((v - widget.min) * 2).round();
    return (v - widget.min).round();
  }

  double _indexToValue(int index) {
    if (_showHalves) return widget.min + index * 0.5;
    return (widget.min + index).toDouble();
  }

  int get _itemCount {
    if (_showHalves) return (widget.max - widget.min) * 2 + 1;
    return widget.max - widget.min + 1;
  }

  void _toggleHalves() {
    final value = _selected;
    // Compute target index in the NEW mode before flipping.
    final newShowHalves = !_showHalves;
    final targetIndex = newShowHalves
        ? ((value - widget.min) * 2).round()
        : (value.round() - widget.min).clamp(0, widget.max - widget.min);
    final snappedValue = newShowHalves
        ? value
        : value.roundToDouble();
    final oldCtrl = _scrollCtrl;
    setState(() {
      _showHalves = newShowHalves;
      _selected = snappedValue;
      _scrollCtrl = FixedExtentScrollController(initialItem: targetIndex);
    });
    oldCtrl.dispose();
  }

  void _commitTextEntry() {
    final v = double.tryParse(_textCtrl.text);
    if (v == null || v < widget.min || v > widget.max) {
      setState(() => _editing = false);
      return;
    }
    // Snap to nearest .5 if allowHalf, otherwise nearest int.
    final snapped = widget.allowHalf
        ? (v * 2).roundToDouble() / 2
        : v.roundToDouble();
    final hasHalf = snapped % 1 == 0.5;
    setState(() {
      _selected = snapped;
      _editing = false;
      // Auto-enable half mode if user typed a .5 value.
      if (hasHalf && !_showHalves) {
        _showHalves = true;
        final oldCtrl = _scrollCtrl;
        _scrollCtrl = FixedExtentScrollController(
          initialItem: _valueToIndex(snapped),
        );
        oldCtrl.dispose();
        return;
      }
    });
    _scrollCtrl.animateToItem(
      _valueToIndex(snapped),
      duration: MotionTokens.slow,
      curve: MotionTokens.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Title (left) | 0.5° toggle (right).
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: TypographyTokens.displayLgSize,
                        fontWeight: TypographyTokens.displayLgWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: widget.allowHalf
                        ? ZxPillButton(
                            label: '0.5°',
                            icon: Icons.add,
                            size: ZxPillSize.md,
                            variant: _showHalves
                                ? ZxPillVariant.primary
                                : ZxPillVariant.secondary,
                            onTap: _toggleHalves,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            // Row 2: Display number (left) | Scroll wheel (right).
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Left: live display — tap to type.
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _editing = true;
                          _textCtrl.text = _selected % 1 == 0.5
                              ? _selected.toStringAsFixed(1)
                              : _selected.toStringAsFixed(0);
                          _textCtrl.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _textCtrl.text.length,
                          );
                        });
                      },
                      child: Center(
                        child: _editing
                            ? SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _textCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: TypographyTokens.displayXlSize,
                                    fontWeight: FontWeight.w600,
                                    color: ColorTokens.primaryDefault,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => _commitTextEntry(),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatValue(_selected),
                                    style: TextStyle(
                                      fontSize: TypographyTokens.displayXlSize,
                                      fontWeight: FontWeight.w600,
                                      color: ColorTokens.primaryDefault,
                                    ),
                                  ),
                                  const SizedBox(height: SpacingTokens.xs),
                                  Text(
                                    '(tap to edit)',
                                    style: TextStyle(
                                      fontSize: TypographyTokens.bodySmSize,
                                      color: ColorTokens.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  // Right: scroll wheel.
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      key: ValueKey(_showHalves),
                      controller: _scrollCtrl,
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      diameterRatio: 1.5,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selected = _indexToValue(index);
                          _editing = false;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _itemCount,
                        builder: (context, index) {
                          final value = _indexToValue(index);
                          final isSelected = value == _selected;
                          return Center(
                            child: Text(
                              _formatValue(value),
                              style: TextStyle(
                                fontSize: isSelected
                                    ? TypographyTokens.displayLgSize
                                    : TypographyTokens.bodyLgSize,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? ColorTokens.textPrimary
                                    : ColorTokens.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            // Row 3: Cancel (left) | Save (right).
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: ZxPillButton(
                      label: 'Cancel',
                      variant: ZxPillVariant.tertiary,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ZxPillButton(
                      label: 'Save',
                      variant: ZxPillVariant.primary,
                      onTap: () {
                        if (_editing) _commitTextEntry();
                        Navigator.pop(
                          context,
                          widget.allowHalf ? _selected : _selected.toInt(),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable data field cell showing label + value.
class _DataField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _DataField({
    required this.value,
    this.placeholder = '--',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.xs,
          vertical: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Center(
          child: Text(
            value ?? placeholder,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: value != null
                  ? ColorTokens.textPrimary
                  : ColorTokens.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
