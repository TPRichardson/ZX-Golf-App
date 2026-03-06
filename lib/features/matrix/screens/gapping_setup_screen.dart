// Phase M5 — Gapping Chart setup screen.
// Matrix §3.1 — Configure and start a new Gapping Chart run.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/screens/gapping_execution_screen.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// Matrix §3.1 — Setup screen for creating a new Gapping Chart run.
/// User selects clubs from their bag, sets shot target, and optional settings.
class GappingSetupScreen extends ConsumerStatefulWidget {
  final String userId;

  const GappingSetupScreen({super.key, required this.userId});

  @override
  ConsumerState<GappingSetupScreen> createState() =>
      _GappingSetupScreenState();
}

class _GappingSetupScreenState extends ConsumerState<GappingSetupScreen> {
  final _shotTargetController = TextEditingController(text: '5');
  final Set<String> _selectedClubIds = {};
  bool _creating = false;
  String? _measurementDevice;
  EnvironmentType? _environmentType;
  SurfaceType? _surfaceType;

  @override
  void dispose() {
    _shotTargetController.dispose();
    super.dispose();
  }

  Future<void> _createRun() async {
    if (_selectedClubIds.isEmpty || _creating) return;

    final shotTarget = int.tryParse(_shotTargetController.text.trim());
    if (shotTarget == null || shotTarget < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shot target must be at least 3')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      // Sort clubs by the order they appear in the bag.
      final bagAsync = ref.read(userBagProvider(widget.userId));
      final bagClubs = bagAsync.valueOrNull ?? [];
      final orderedLabels = <String>[];
      for (final club in bagClubs) {
        if (_selectedClubIds.contains(club.clubId)) {
          orderedLabels.add(club.clubType.dbValue);
        }
      }

      final config = MatrixRunConfig(
        matrixType: MatrixType.gappingChart,
        sessionShotTarget: shotTarget,
        measurementDevice: _measurementDevice,
        environmentType: _environmentType,
        surfaceType: _surfaceType,
        axes: [
          AxisConfig(
            axisType: AxisType.club,
            axisName: 'Club',
            labels: orderedLabels,
          ),
        ],
      );

      final run = await ref
          .read(matrixActionsProvider)
          .createMatrixRun(widget.userId, config);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GappingExecutionScreen(
              matrixRunId: run.matrixRunId,
              userId: widget.userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bagAsync = ref.watch(userBagProvider(widget.userId));

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      appBar: AppBar(
        title: const Text('New Gapping Chart'),
        backgroundColor: ColorTokens.surfacePrimary,
      ),
      body: bagAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (clubs) => _buildForm(clubs),
      ),
    );
  }

  Widget _buildForm(List<UserClub> clubs) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Club selection.
                const Text(
                  'Select Clubs',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                const Text(
                  'Choose which clubs to include in this gapping chart.',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                if (clubs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: ColorTokens.surfacePrimary,
                      borderRadius:
                          BorderRadius.circular(ShapeTokens.radiusCard),
                    ),
                    child: const Text(
                      'No clubs in bag. Add clubs in Settings first.',
                      style: TextStyle(color: ColorTokens.textSecondary),
                    ),
                  )
                else ...[
                  // Select all / Deselect all.
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedClubIds
                              .addAll(clubs.map((c) => c.clubId));
                        }),
                        child: const Text('Select All'),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedClubIds.clear()),
                        child: const Text('Deselect All'),
                      ),
                    ],
                  ),
                  ...clubs.map((club) => _buildClubTile(club)),
                ],

                const SizedBox(height: SpacingTokens.lg),

                // Shot target.
                const Text(
                  'Shots Per Club',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _shotTargetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: ColorTokens.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ColorTokens.surfacePrimary,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(ShapeTokens.radiusInput),
                        borderSide:
                            const BorderSide(color: ColorTokens.surfaceBorder),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: SpacingTokens.lg),

                // Environment settings.
                const Text(
                  'Environment (Optional)',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                _buildDropdown<EnvironmentType>(
                  label: 'Environment',
                  value: _environmentType,
                  items: EnvironmentType.values,
                  itemLabel: (e) => e.dbValue,
                  onChanged: (v) =>
                      setState(() => _environmentType = v),
                ),
                const SizedBox(height: SpacingTokens.sm),
                _buildDropdown<SurfaceType>(
                  label: 'Surface',
                  value: _surfaceType,
                  items: SurfaceType.values,
                  itemLabel: (e) => e.dbValue,
                  onChanged: (v) => setState(() => _surfaceType = v),
                ),
              ],
            ),
          ),
        ),

        // Start button.
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: const BoxDecoration(
            color: ColorTokens.surfacePrimary,
            border: Border(
              top: BorderSide(color: ColorTokens.surfaceBorder),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _selectedClubIds.isEmpty || _creating ? null : _createRun,
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primaryDefault,
                padding:
                    const EdgeInsets.symmetric(vertical: SpacingTokens.md),
              ),
              child: _creating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Start Gapping (${_selectedClubIds.length} clubs)',
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodyLgSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubTile(UserClub club) {
    final selected = _selectedClubIds.contains(club.clubId);
    return CheckboxListTile(
      value: selected,
      onChanged: (v) {
        setState(() {
          if (v == true) {
            _selectedClubIds.add(club.clubId);
          } else {
            _selectedClubIds.remove(club.clubId);
          }
        });
      },
      title: Text(
        club.clubType.dbValue,
        style: const TextStyle(color: ColorTokens.textPrimary),
      ),
      subtitle: club.make != null || club.model != null
          ? Text(
              [club.make, club.model].whereType<String>().join(' '),
              style: const TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textSecondary,
              ),
            )
          : null,
      activeColor: ColorTokens.primaryDefault,
      tileColor: ColorTokens.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      ),
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ColorTokens.textSecondary),
        filled: true,
        fillColor: ColorTokens.surfacePrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusInput),
          borderSide: const BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      dropdownColor: ColorTokens.surfaceModal,
      style: const TextStyle(color: ColorTokens.textPrimary),
      items: [
        DropdownMenuItem<T>(value: null, child: const Text('Not set')),
        ...items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
