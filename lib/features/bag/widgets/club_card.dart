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
    final makeModel = [club.make, club.model]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return ZxCard(
      onTap: onTap,
      child: Row(
        children: [
          // Left column: color square + make/model.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _categoryColor(club.clubType).withAlpha(30),
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusCard),
                ),
                alignment: Alignment.center,
                child: Text(
                  _clubTypeShort(club.clubType),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _categoryColor(club.clubType),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showMakeModelDialog(context, ref),
                child: Text(
                  makeModel.isEmpty ? 'Make / Model' : makeModel,
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: makeModel.isEmpty
                        ? ColorTokens.textTertiary
                        : ColorTokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Loft field.
          _DataField(
            label: 'Loft',
            value: club.loft != null
                ? '${club.loft!.toStringAsFixed(0)}°'
                : null,
            onTap: () => _showLoftDialog(context, ref),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Carry field.
          _DataField(
            label: 'Carry',
            value: carry != null ? '${carry.toStringAsFixed(0)}y' : null,
            onTap: () => _showCarryDialog(context, ref),
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
          Icon(
            Icons.chevron_right,
            color: ColorTokens.textTertiary,
          ),
        ],
      ),
    );
  }

  Future<void> _showMakeModelDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String make, String model})>(
      context: context,
      builder: (ctx) => _MakeModelDialog(
        initialMake: club.make ?? '',
        initialModel: club.model ?? '',
      ),
    );

    if (result != null) {
      await ref.read(clubRepositoryProvider).updateClub(
            club.clubId,
            UserClubsCompanion(
              make: drift.Value(
                  result.make.isEmpty ? null : result.make),
              model: drift.Value(
                  result.model.isEmpty ? null : result.model),
            ),
          );
    }
  }

  Future<void> _showLoftDialog(BuildContext context, WidgetRef ref) async {
    final range = _loftRange(club.clubType);
    final currentLoft = club.loft?.round() ?? range.middle;

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => _LoftPickerDialog(
        min: range.min,
        max: range.max,
        initial: currentLoft.clamp(range.min, range.max),
      ),
    );

    if (selected != null) {
      await ref.read(clubRepositoryProvider).updateClub(
            club.clubId,
            UserClubsCompanion(
              loft: drift.Value(selected.toDouble()),
            ),
          );
    }
  }

  /// Returns carry range per club category, or null for putter.
  static ({int min, int max, int middle})? _carryRange(ClubType type) {
    if (type == ClubType.putter) return null;
    if (type == ClubType.driver) return (min: 150, max: 400, middle: 250);
    if (type.dbValue.startsWith('W')) return (min: 130, max: 350, middle: 220);
    if (type.dbValue.startsWith('H')) return (min: 80, max: 300, middle: 180);
    if (type.dbValue.startsWith('i')) return (min: 50, max: 280, middle: 150);
    // Wedges: PW, AW, GW, SW, UW, LW, chipper.
    return (min: 40, max: 160, middle: 100);
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

    final result = await showDialog<({int carry, double? total})>(
      context: context,
      builder: (ctx) => _CarryPickerDialog(
        min: range.min,
        max: range.max,
        initial: currentCarry.clamp(range.min, range.max),
        initialTotal: profile?.totalDistance,
      ),
    );

    if (result != null) {
      await ref.read(clubRepositoryProvider).addPerformanceProfile(
            club.clubId,
            ClubPerformanceProfilesCompanion(
              effectiveFromDate: drift.Value(DateTime.now()),
              carryDistance: drift.Value(result.carry.toDouble()),
              totalDistance: drift.Value(result.total),
              dispersionLeft: drift.Value(profile?.dispersionLeft),
              dispersionRight: drift.Value(profile?.dispersionRight),
              dispersionShort: drift.Value(profile?.dispersionShort),
              dispersionLong: drift.Value(profile?.dispersionLong),
            ),
          );
      ref.invalidate(activeProfileProvider(club.clubId));
    }
  }

  static String _clubTypeShort(ClubType type) {
    return switch (type) {
      ClubType.driver => 'D',
      ClubType.putter => 'P',
      ClubType.chipper => 'Ch',
      _ => type.dbValue,
    };
  }

  static Color _categoryColor(ClubType type) {
    return ColorTokens.clubCategory(type);
  }
}

/// Make/model picker with popular brand picklist + custom free text.
class _MakeModelDialog extends StatefulWidget {
  final String initialMake;
  final String initialModel;

  const _MakeModelDialog({
    required this.initialMake,
    required this.initialModel,
  });

  @override
  State<_MakeModelDialog> createState() => _MakeModelDialogState();
}

class _MakeModelDialogState extends State<_MakeModelDialog> {
  static const _brands = [
    'Callaway',
    'TaylorMade',
    'Titleist',
    'Ping',
    'Cobra',
    'Mizuno',
    'Srixon',
    'Cleveland',
    'Wilson Staff',
    'PXG',
    'Bridgestone',
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Make & Model',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      content: SizedBox(
        width: 300,
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
            GridView.count(
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
                    onTap: () {
                      setState(() {
                        _selectedBrand = brand;
                        _isCustom = false;
                      });
                    },
                  ),
                ZxPillButton(
                  label: 'Custom',
                  size: ZxPillSize.sm,
                  expanded: true,
                  centered: true,
                  variant: _isCustom
                      ? ZxPillVariant.primary
                      : ZxPillVariant.tertiary,
                  onTap: () {
                    setState(() {
                      _isCustom = true;
                      _selectedBrand = '';
                    });
                  },
                ),
              ],
            ),
            if (_isCustom) ...[
              const SizedBox(height: SpacingTokens.sm),
              TextField(
                controller: _customCtrl,
                autofocus: true,
                style: const TextStyle(color: ColorTokens.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Brand name',
                  hintText: 'e.g. PXG',
                  labelStyle: TextStyle(color: ColorTokens.textTertiary),
                  hintStyle: TextStyle(color: ColorTokens.textTertiary),
                ),
              ),
            ],
            if (_selectedBrand.isNotEmpty || _isCustom) ...[
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
            ],
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
          label: 'Save',
          variant: ZxPillVariant.primary,
          onTap: () => Navigator.pop(
            context,
            (make: _make, model: _modelCtrl.text.trim()),
          ),
        ),
      ],
    );
  }
}

/// Scroll-wheel loft picker dialog with category-constrained range.
class _LoftPickerDialog extends StatefulWidget {
  final int min;
  final int max;
  final int initial;

  const _LoftPickerDialog({
    required this.min,
    required this.max,
    required this.initial,
  });

  @override
  State<_LoftPickerDialog> createState() => _LoftPickerDialogState();
}

class _LoftPickerDialogState extends State<_LoftPickerDialog> {
  late final FixedExtentScrollController _scrollCtrl;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _scrollCtrl = FixedExtentScrollController(
      initialItem: widget.initial - widget.min,
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Loft',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      content: SizedBox(
        height: 180,
        child: Row(
          children: [
            // Type value button on the left.
            ZxPillButton(
              label: 'Enter\nvalue',
              variant: ZxPillVariant.secondary,
  
              onTap: () async {
                final ctrl = TextEditingController();
                final value = await showDialog<int>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: ColorTokens.surfaceModal,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ShapeTokens.radiusModal),
                    ),
                    title: const Text(
                      'Enter Loft',
                      style: TextStyle(color: ColorTokens.textPrimary),
                    ),
                    content: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                          color: ColorTokens.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Degrees',
                        hintText: 'e.g. 46',
                        labelStyle:
                            TextStyle(color: ColorTokens.textTertiary),
                        hintStyle:
                            TextStyle(color: ColorTokens.textTertiary),
                      ),
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
            
                        onTap: () {
                          final v = int.tryParse(ctrl.text);
                          if (v != null) Navigator.pop(ctx, v);
                        },
                      ),
                    ],
                  ),
                );
                if (value != null && context.mounted) {
                  Navigator.pop(context, value);
                }
              },
            ),
            const SizedBox(width: SpacingTokens.md),
            // Scroll wheel on the right.
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _scrollCtrl,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.5,
                onSelectedItemChanged: (index) {
                  setState(() => _selected = widget.min + index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.max - widget.min + 1,
                  builder: (context, index) {
                    final value = widget.min + index;
                    final isSelected = value == _selected;
                    return Center(
                      child: Text(
                        '$value°',
                        style: TextStyle(
                          fontSize: isSelected
                              ? TypographyTokens.displayLgSize
                              : TypographyTokens.bodyLgSize,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? ColorTokens.primaryDefault
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
      actions: [
        ZxPillButton(
          label: 'Cancel',
          variant: ZxPillVariant.tertiary,

          onTap: () => Navigator.pop(context),
        ),
        ZxPillButton(
          label: 'Save',
          variant: ZxPillVariant.primary,

          onTap: () => Navigator.pop(context, _selected),
        ),
      ],
    );
  }
}

/// Scroll-wheel carry picker + optional total distance field.
class _CarryPickerDialog extends StatefulWidget {
  final int min;
  final int max;
  final int initial;
  final double? initialTotal;

  const _CarryPickerDialog({
    required this.min,
    required this.max,
    required this.initial,
    this.initialTotal,
  });

  @override
  State<_CarryPickerDialog> createState() => _CarryPickerDialogState();
}

class _CarryPickerDialogState extends State<_CarryPickerDialog> {
  late final FixedExtentScrollController _scrollCtrl;
  late int _selected;
  late final TextEditingController _totalCtrl;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _scrollCtrl = FixedExtentScrollController(
      initialItem: widget.initial - widget.min,
    );
    _totalCtrl = TextEditingController(
      text: widget.initialTotal?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Distance',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      content: SizedBox(
        height: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carry',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            SizedBox(
              height: 140,
              child: Row(
                children: [
                  ZxPillButton(
                    label: 'Enter\nvalue',
                    variant: ZxPillVariant.secondary,
                    onTap: () async {
                      final ctrl = TextEditingController();
                      final value = await showDialog<int>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: ColorTokens.surfaceModal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ShapeTokens.radiusModal),
                          ),
                          title: const Text(
                            'Enter Carry',
                            style:
                                TextStyle(color: ColorTokens.textPrimary),
                          ),
                          content: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            style: const TextStyle(
                                color: ColorTokens.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Yards',
                              hintText: 'e.g. 150',
                              labelStyle: TextStyle(
                                  color: ColorTokens.textTertiary),
                              hintStyle: TextStyle(
                                  color: ColorTokens.textTertiary),
                            ),
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
                              onTap: () {
                                final v = int.tryParse(ctrl.text);
                                if (v != null) Navigator.pop(ctx, v);
                              },
                            ),
                          ],
                        ),
                      );
                      if (value != null && context.mounted) {
                        Navigator.pop(
                          context,
                          (
                            carry: value,
                            total: double.tryParse(_totalCtrl.text),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _scrollCtrl,
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      diameterRatio: 1.5,
                      onSelectedItemChanged: (index) {
                        setState(() => _selected = widget.min + index);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: widget.max - widget.min + 1,
                        builder: (context, index) {
                          final value = widget.min + index;
                          final isSelected = value == _selected;
                          return Center(
                            child: Text(
                              '${value}y',
                              style: TextStyle(
                                fontSize: isSelected
                                    ? TypographyTokens.displayLgSize
                                    : TypographyTokens.bodyLgSize,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? ColorTokens.primaryDefault
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
            const SizedBox(height: SpacingTokens.sm),
            TextField(
              controller: _totalCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: ColorTokens.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Total (yards)',
                hintText: '(Optional)',
                labelStyle: TextStyle(color: ColorTokens.textTertiary),
                hintStyle: TextStyle(color: ColorTokens.textTertiary),
              ),
            ),
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
          label: 'Save',
          variant: ZxPillVariant.primary,
          onTap: () => Navigator.pop(
            context,
            (
              carry: _selected,
              total: double.tryParse(_totalCtrl.text),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tappable data field cell showing label + value.
class _DataField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DataField({
    required this.label,
    required this.value,
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
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value ?? '--',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: FontWeight.w500,
                color: value != null
                    ? ColorTokens.textSecondary
                    : ColorTokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
