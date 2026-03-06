// Phase M7 — Chipping Matrix setup screen.
// Matrix §3.3 — Configure and start a new Chipping Matrix run.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/screens/matrix_execution_screen.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// Matrix §3.3 — Setup screen for creating a new Chipping Matrix run.
/// Selects clubs, carry distances, flight types, green conditions.
class ChippingSetupScreen extends ConsumerStatefulWidget {
  final String userId;

  const ChippingSetupScreen({super.key, required this.userId});

  @override
  ConsumerState<ChippingSetupScreen> createState() =>
      _ChippingSetupScreenState();
}

class _ChippingSetupScreenState extends ConsumerState<ChippingSetupScreen> {
  final _shotTargetController = TextEditingController(text: '5');
  final _greenSpeedController = TextEditingController();
  final Set<String> _selectedClubIds = {};
  final List<String> _carryDistances = ['10', '20', '30'];
  final List<String> _flightTypes = ['Low', 'Mid', 'High'];
  final _distanceController = TextEditingController();
  final _flightController = TextEditingController();
  bool _creating = false;
  GreenFirmness? _greenFirmness;
  SurfaceType? _surfaceType;

  @override
  void dispose() {
    _shotTargetController.dispose();
    _greenSpeedController.dispose();
    _distanceController.dispose();
    _flightController.dispose();
    super.dispose();
  }

  void _addDistance() {
    final text = _distanceController.text.trim();
    if (text.isEmpty || _carryDistances.contains(text)) return;
    setState(() {
      _carryDistances.add(text);
      _distanceController.clear();
    });
  }

  void _addFlight() {
    final text = _flightController.text.trim();
    if (text.isEmpty || _flightTypes.contains(text)) return;
    setState(() {
      _flightTypes.add(text);
      _flightController.clear();
    });
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
      final bagAsync = ref.read(userBagProvider(widget.userId));
      final bagClubs = bagAsync.valueOrNull ?? [];
      final orderedLabels = <String>[];
      for (final club in bagClubs) {
        if (_selectedClubIds.contains(club.clubId)) {
          orderedLabels.add(club.clubType.dbValue);
        }
      }

      final greenSpeed = _greenSpeedController.text.trim().isNotEmpty
          ? double.tryParse(_greenSpeedController.text.trim())
          : null;

      final config = MatrixRunConfig(
        matrixType: MatrixType.chippingMatrix,
        sessionShotTarget: shotTarget,
        surfaceType: _surfaceType,
        greenSpeed: greenSpeed,
        greenFirmness: _greenFirmness,
        axes: [
          AxisConfig(
            axisType: AxisType.club,
            axisName: 'Club',
            labels: orderedLabels,
          ),
          AxisConfig(
            axisType: AxisType.carryDistance,
            axisName: 'Carry Distance',
            labels: List.from(_carryDistances),
          ),
          AxisConfig(
            axisType: AxisType.flight,
            axisName: 'Flight',
            labels: List.from(_flightTypes),
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
            builder: (_) => MatrixExecutionScreen(
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
        title: const Text('New Chipping Matrix'),
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
    final totalCells =
        _selectedClubIds.length * _carryDistances.length * _flightTypes.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Club selection.
                const Text('Select Clubs',
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: TypographyTokens.headerWeight,
                      color: ColorTokens.textPrimary,
                    )),
                const SizedBox(height: SpacingTokens.sm),
                ...clubs.map((club) {
                  final selected =
                      _selectedClubIds.contains(club.clubId);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedClubIds.add(club.clubId);
                      } else {
                        _selectedClubIds.remove(club.clubId);
                      }
                    }),
                    title: Text(club.clubType.dbValue,
                        style: const TextStyle(
                            color: ColorTokens.textPrimary)),
                    activeColor: ColorTokens.primaryDefault,
                    tileColor: ColorTokens.surfacePrimary,
                    dense: true,
                  );
                }),

                const SizedBox(height: SpacingTokens.lg),

                // Carry distances.
                _buildTagSection(
                  title: 'Carry Distances (yards)',
                  tags: _carryDistances,
                  controller: _distanceController,
                  onAdd: _addDistance,
                  onRemove: (i) => setState(() {
                    if (_carryDistances.length > 1) {
                      _carryDistances.removeAt(i);
                    }
                  }),
                ),

                const SizedBox(height: SpacingTokens.lg),

                // Flight types.
                _buildTagSection(
                  title: 'Flight Types',
                  tags: _flightTypes,
                  controller: _flightController,
                  onAdd: _addFlight,
                  onRemove: (i) => setState(() {
                    if (_flightTypes.length > 1) {
                      _flightTypes.removeAt(i);
                    }
                  }),
                ),

                const SizedBox(height: SpacingTokens.lg),

                // Shot target.
                const Text('Shots Per Cell',
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: TypographyTokens.headerWeight,
                      color: ColorTokens.textPrimary,
                    )),
                const SizedBox(height: SpacingTokens.sm),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _shotTargetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    style: const TextStyle(
                        color: ColorTokens.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ColorTokens.surfacePrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            ShapeTokens.radiusInput),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: SpacingTokens.lg),

                // Green conditions.
                const Text('Green Conditions',
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: TypographyTokens.headerWeight,
                      color: ColorTokens.textPrimary,
                    )),
                const SizedBox(height: SpacingTokens.sm),
                TextField(
                  controller: _greenSpeedController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: const TextStyle(
                      color: ColorTokens.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Green Speed (stimpmeter)',
                    labelStyle: const TextStyle(
                        color: ColorTokens.textSecondary),
                    filled: true,
                    fillColor: ColorTokens.surfacePrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          ShapeTokens.radiusInput),
                    ),
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                DropdownButtonFormField<GreenFirmness>(
                  initialValue: _greenFirmness,
                  decoration: InputDecoration(
                    labelText: 'Green Firmness',
                    labelStyle: const TextStyle(
                        color: ColorTokens.textSecondary),
                    filled: true,
                    fillColor: ColorTokens.surfacePrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          ShapeTokens.radiusInput),
                    ),
                  ),
                  dropdownColor: ColorTokens.surfaceModal,
                  style: const TextStyle(
                      color: ColorTokens.textPrimary),
                  items: [
                    const DropdownMenuItem<GreenFirmness>(
                        value: null, child: Text('Not set')),
                    ...GreenFirmness.values.map((f) =>
                        DropdownMenuItem(
                          value: f,
                          child: Text(f.dbValue),
                        )),
                  ],
                  onChanged: (v) =>
                      setState(() => _greenFirmness = v),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: const BoxDecoration(
            color: ColorTokens.surfacePrimary,
            border: Border(
                top: BorderSide(color: ColorTokens.surfaceBorder)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedClubIds.isEmpty || _creating
                  ? null
                  : _createRun,
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primaryDefault,
                padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.md),
              ),
              child: _creating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Start Chipping Matrix ($totalCells cells)'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection({
    required String title,
    required List<String> tags,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: TypographyTokens.headerSize,
              fontWeight: TypographyTokens.headerWeight,
              color: ColorTokens.textPrimary,
            )),
        const SizedBox(height: SpacingTokens.sm),
        Wrap(
          spacing: SpacingTokens.sm,
          children: tags.asMap().entries.map((entry) {
            return Chip(
              label: Text(entry.value),
              onDeleted: tags.length > 1
                  ? () => onRemove(entry.key)
                  : null,
              backgroundColor: ColorTokens.surfaceRaised,
              labelStyle:
                  const TextStyle(color: ColorTokens.textPrimary),
            );
          }).toList(),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style:
                    const TextStyle(color: ColorTokens.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add value',
                  hintStyle: const TextStyle(
                      color: ColorTokens.textTertiary),
                  filled: true,
                  fillColor: ColorTokens.surfacePrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        ShapeTokens.radiusInput),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add,
                  color: ColorTokens.primaryDefault),
            ),
          ],
        ),
      ],
    );
  }
}
