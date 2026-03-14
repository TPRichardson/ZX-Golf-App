import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/core/widgets/zx_input_field.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/database_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// Phase 3 — Club detail screen. Edit make, model, loft.
// S09 §9.1 — Club configuration.

class ClubDetailScreen extends ConsumerStatefulWidget {
  final String clubId;

  const ClubDetailScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen> {
  UserClub? _club;
  bool _isLoading = true;

  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _loftController = TextEditingController();

  // Performance profile fields.
  final _carryController = TextEditingController();
  final _totalController = TextEditingController();
  final _dispLeftController = TextEditingController();
  final _dispRightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClub();
  }

  Future<void> _loadClub() async {
    final db = ref.read(databaseProvider);
    final clubRepo = ref.read(clubRepositoryProvider);

    final club = await (db.select(db.userClubs)
          ..where((t) => t.clubId.equals(widget.clubId)))
        .getSingleOrNull();
    final profile = await clubRepo.getActiveProfile(widget.clubId);

    if (mounted) {
      setState(() {
        _club = club;
        _isLoading = false;

        if (club != null) {
          _makeController.text = club.make ?? '';
          _modelController.text = club.model ?? '';
          _loftController.text = club.loft?.toStringAsFixed(1) ?? '';
        }
        if (profile != null) {
          _carryController.text =
              profile.carryDistance?.toStringAsFixed(0) ?? '';
          _totalController.text =
              profile.totalDistance?.toStringAsFixed(0) ?? '';
          _dispLeftController.text =
              profile.dispersionLeft?.toStringAsFixed(0) ?? '';
          _dispRightController.text =
              profile.dispersionRight?.toStringAsFixed(0) ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _loftController.dispose();
    _carryController.dispose();
    _totalController.dispose();
    _dispLeftController.dispose();
    _dispRightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const ZxAppBar(title: 'Club'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_club == null) {
      return Scaffold(
        appBar: const ZxAppBar(title: 'Club'),
        body: const Center(child: Text('Club not found')),
      );
    }

    final club = _club!;

    return Scaffold(
      appBar: ZxAppBar(
        title: club.clubType.dbValue,
        actions: [
          if (club.status == UserClubStatus.active)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Retire Club',
              onPressed: _retireClub,
            ),
          if (club.status == UserClubStatus.retired)
            IconButton(
              icon: const Icon(Icons.unarchive_outlined),
              tooltip: 'Reactivate Club',
              onPressed: _reactivateClub,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          // Status.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.sm,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: club.status == UserClubStatus.active
                  ? ColorTokens.successDefault.withAlpha(30)
                  : ColorTokens.textTertiary.withAlpha(30),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusBadge),
            ),
            child: Text(
              club.status.dbValue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: club.status == UserClubStatus.active
                        ? ColorTokens.successDefault
                        : ColorTokens.textTertiary,
                  ),
            ),
          ),

          const SizedBox(height: SpacingTokens.lg),

          // Club details.
          Text(
            'Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ColorTokens.textPrimary,
                ),
          ),
          const SizedBox(height: SpacingTokens.md),
          ZxInputField(
            label: 'Make',
            controller: _makeController,
            hintText: 'e.g., TaylorMade',
          ),
          const SizedBox(height: SpacingTokens.md),
          ZxInputField(
            label: 'Model',
            controller: _modelController,
            hintText: 'e.g., P770',
          ),
          const SizedBox(height: SpacingTokens.md),
          ZxInputField(
            label: 'Loft',
            controller: _loftController,
            keyboardType: TextInputType.number,
            hintText: 'Degrees',
          ),
          const SizedBox(height: SpacingTokens.md),
          ZxPillButton(
            label: 'Save Details',
            variant: ZxPillVariant.primary,
            expanded: true,
            centered: true,
            onTap: _saveDetails,
          ),

          const SizedBox(height: SpacingTokens.xl),

          // Performance profile.
          Text(
            'Performance Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ColorTokens.textPrimary,
                ),
          ),
          const SizedBox(height: SpacingTokens.md),
          ZxInputField(
            label: 'Carry Distance (yards)',
            controller: _carryController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: SpacingTokens.md),
          ZxInputField(
            label: 'Total Distance (yards)',
            controller: _totalController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: SpacingTokens.md),
          Row(
            children: [
              Expanded(
                child: ZxInputField(
                  label: 'Disp. Left',
                  controller: _dispLeftController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: ZxInputField(
                  label: 'Disp. Right',
                  controller: _dispRightController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          ZxPillButton(
            label: 'Update Profile',
            variant: ZxPillVariant.secondary,
            expanded: true,
            centered: true,
            onTap: _updateProfile,
          ),
        ],
      ),
    );
  }

  Future<void> _saveDetails() async {
    try {
      await ref.read(clubRepositoryProvider).updateClub(
            widget.clubId,
            UserClubsCompanion(
              make: drift.Value(_makeController.text.isEmpty
                  ? null
                  : _makeController.text),
              model: drift.Value(_modelController.text.isEmpty
                  ? null
                  : _modelController.text),
              loft: drift.Value(double.tryParse(_loftController.text)),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club details saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      await ref.read(clubRepositoryProvider).addPerformanceProfile(
            widget.clubId,
            ClubPerformanceProfilesCompanion(
              effectiveFromDate: drift.Value(DateTime.now()),
              carryDistance:
                  drift.Value(double.tryParse(_carryController.text)),
              totalDistance:
                  drift.Value(double.tryParse(_totalController.text)),
              dispersionLeft:
                  drift.Value(double.tryParse(_dispLeftController.text)),
              dispersionRight:
                  drift.Value(double.tryParse(_dispRightController.text)),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _retireClub() async {
    final userId = ref.read(currentUserIdProvider);
    await ref.read(clubRepositoryProvider).retireClub(userId, widget.clubId);
    await _loadClub();
  }

  Future<void> _reactivateClub() async {
    final userId = ref.read(currentUserIdProvider);
    await ref
        .read(clubRepositoryProvider)
        .reactivateClub(userId, widget.clubId);
    await _loadClub();
  }
}
