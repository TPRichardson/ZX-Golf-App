// Unified Matrix setup screen for all matrix types.
// Matrix §3.1–3.3 — Configure and start a new matrix run.
// Replaces GappingSetupScreen, WedgeSetupScreen, ChippingSetupScreen
// with a single host + type-specific form content.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/screens/matrix_execution_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// Unified setup screen for all matrix types (Gapping, Wedge, Chipping).
class MatrixSetupScreen extends ConsumerStatefulWidget {
  final String userId;
  final MatrixType matrixType;

  const MatrixSetupScreen({
    super.key,
    required this.userId,
    required this.matrixType,
  });

  @override
  ConsumerState<MatrixSetupScreen> createState() => _MatrixSetupScreenState();
}

class _MatrixSetupScreenState extends ConsumerState<MatrixSetupScreen> {
  final _shotTargetController = TextEditingController(text: '5');
  final Set<String> _selectedClubIds = {};
  bool _creating = false;

  // Shared environment/surface state (all matrix types).
  EnvironmentSurfaceResult? _envSurface;

  // Wedge-specific state.
  final List<String> _effortLevels = ['Full', '3/4', '1/2'];
  final _effortController = TextEditingController();

  // Chipping-specific state.
  final List<String> _carryDistances = ['10', '20', '30'];
  final List<String> _flightTypes = ['Low', 'Mid', 'High'];
  final _distanceController = TextEditingController();
  final _flightController = TextEditingController();
  final _greenSpeedController = TextEditingController();
  GreenFirmness? _greenFirmness;

  @override
  void dispose() {
    _shotTargetController.dispose();
    _effortController.dispose();
    _distanceController.dispose();
    _flightController.dispose();
    _greenSpeedController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.matrixType) {
        MatrixType.gappingChart => 'New Gapping Chart',
        MatrixType.wedgeMatrix => 'New Wedge Matrix',
        MatrixType.chippingMatrix => 'New Chipping Matrix',
      };

  String get _shotTargetLabel => switch (widget.matrixType) {
        MatrixType.gappingChart => 'Shots Per Club',
        _ => 'Shots Per Cell',
      };

  String get _buttonLabel {
    final clubCount = _selectedClubIds.length;
    return switch (widget.matrixType) {
      MatrixType.gappingChart => 'Start Gapping ($clubCount clubs)',
      MatrixType.wedgeMatrix =>
        'Start Matrix ($clubCount × ${_effortLevels.length} = ${clubCount * _effortLevels.length} cells)',
      MatrixType.chippingMatrix =>
        'Start Chipping Matrix (${clubCount * _carryDistances.length * _flightTypes.length} cells)',
    };
  }

  List<AxisConfig> get _axes => switch (widget.matrixType) {
        MatrixType.gappingChart => [
            AxisConfig(
              axisType: AxisType.club,
              axisName: 'Club',
              labels: _orderedClubLabels,
            ),
          ],
        MatrixType.wedgeMatrix => [
            AxisConfig(
              axisType: AxisType.club,
              axisName: 'Club',
              labels: _orderedClubLabels,
            ),
            AxisConfig(
              axisType: AxisType.effort,
              axisName: 'Effort',
              labels: List.from(_effortLevels),
            ),
          ],
        MatrixType.chippingMatrix => [
            AxisConfig(
              axisType: AxisType.club,
              axisName: 'Club',
              labels: _orderedClubLabels,
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
      };

  List<String> get _orderedClubLabels {
    final bagAsync = ref.read(userBagProvider(widget.userId));
    final bagClubs = bagAsync.valueOrNull ?? [];
    return bagClubs
        .where((c) => _selectedClubIds.contains(c.clubId))
        .map((c) => c.clubType.dbValue)
        .toList();
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
      final greenSpeed = widget.matrixType == MatrixType.chippingMatrix &&
              _greenSpeedController.text.trim().isNotEmpty
          ? double.tryParse(_greenSpeedController.text.trim())
          : null;

      final config = MatrixRunConfig(
        matrixType: widget.matrixType,
        sessionShotTarget: shotTarget,
        environmentType: _envSurface?.environment,
        surfaceType: _envSurface?.surface,
        greenSpeed: greenSpeed,
        greenFirmness:
            widget.matrixType == MatrixType.chippingMatrix ? _greenFirmness : null,
        axes: _axes,
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
        title: Text(_title),
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
                // Club selection (shared by all types).
                _buildClubSelection(clubs),

                // Type-specific form fields.
                ...switch (widget.matrixType) {
                  MatrixType.gappingChart => const <Widget>[],
                  MatrixType.wedgeMatrix => _buildWedgeFields(),
                  MatrixType.chippingMatrix => _buildChippingFields(),
                },

                // Shot target (shared by all types).
                const SizedBox(height: SpacingTokens.lg),
                _buildShotTarget(),

                // Environment/surface picker (shared by all types).
                const SizedBox(height: SpacingTokens.lg),
                _buildEnvironmentSurface(),
              ],
            ),
          ),
        ),
        // Start button footer (shared by all types).
        _buildFooter(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared form sections
  // ---------------------------------------------------------------------------

  Widget _buildClubSelection(List<UserClub> clubs) {
    final label = widget.matrixType == MatrixType.wedgeMatrix
        ? 'Select Wedge Clubs'
        : 'Select Clubs';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: TypographyTokens.headerSize,
            fontWeight: TypographyTokens.headerWeight,
            color: ColorTokens.textPrimary,
          ),
        ),
        if (widget.matrixType == MatrixType.gappingChart) ...[
          const SizedBox(height: SpacingTokens.xs),
          const Text(
            'Choose which clubs to include in this gapping chart.',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: SpacingTokens.sm),
        if (clubs.isEmpty)
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: ColorTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            ),
            child: const Text(
              'No clubs in bag. Add clubs in Settings first.',
              style: TextStyle(color: ColorTokens.textSecondary),
            ),
          )
        else ...[
          if (widget.matrixType == MatrixType.gappingChart)
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _selectedClubIds.addAll(clubs.map((c) => c.clubId));
                  }),
                  child: const Text('Select All'),
                ),
                const SizedBox(width: SpacingTokens.sm),
                TextButton(
                  onPressed: () => setState(() => _selectedClubIds.clear()),
                  child: const Text('Deselect All'),
                ),
              ],
            ),
          ...clubs.map((club) => _buildClubTile(club)),
        ],
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

  Widget _buildShotTarget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _shotTargetLabel,
          style: const TextStyle(
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
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
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
                  _buttonLabel,
                  style: const TextStyle(
                    fontSize: TypographyTokens.bodyLgSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Environment / Surface picker (shared)
  // ---------------------------------------------------------------------------

  Widget _buildEnvironmentSurface() {
    final label = _envSurface != null
        ? '${_envSurface!.environment.dbValue} — ${_envSurface!.surface.dbValue}'
        : 'Not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Environment',
          style: TextStyle(
            fontSize: TypographyTokens.headerSize,
            fontWeight: TypographyTokens.headerWeight,
            color: ColorTokens.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await showEnvironmentSurfacePicker(context);
            if (result != null) {
              setState(() => _envSurface = result);
            }
          },
          icon: Icon(
            _envSurface?.environment == EnvironmentType.indoor
                ? Icons.home
                : _envSurface?.environment == EnvironmentType.outdoor
                    ? Icons.wb_sunny
                    : Icons.place,
            size: 18,
          ),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorTokens.textPrimary,
            side: const BorderSide(color: ColorTokens.surfaceBorder),
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Wedge-specific fields
  // ---------------------------------------------------------------------------

  List<Widget> _buildWedgeFields() {
    return [
      const SizedBox(height: SpacingTokens.lg),
      _buildTagSection(
        title: 'Effort Levels',
        tags: _effortLevels,
        controller: _effortController,
        hintText: 'Add effort level',
        onAdd: () {
          final text = _effortController.text.trim();
          if (text.isEmpty || _effortLevels.contains(text)) return;
          setState(() {
            _effortLevels.add(text);
            _effortController.clear();
          });
        },
        onRemove: (i) {
          if (_effortLevels.length <= 1) return;
          setState(() => _effortLevels.removeAt(i));
        },
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Chipping-specific fields
  // ---------------------------------------------------------------------------

  List<Widget> _buildChippingFields() {
    return [
      const SizedBox(height: SpacingTokens.lg),
      _buildTagSection(
        title: 'Carry Distances (yards)',
        tags: _carryDistances,
        controller: _distanceController,
        hintText: 'Add value',
        onAdd: () {
          final text = _distanceController.text.trim();
          if (text.isEmpty || _carryDistances.contains(text)) return;
          setState(() {
            _carryDistances.add(text);
            _distanceController.clear();
          });
        },
        onRemove: (i) {
          if (_carryDistances.length > 1) {
            setState(() => _carryDistances.removeAt(i));
          }
        },
      ),
      const SizedBox(height: SpacingTokens.lg),
      _buildTagSection(
        title: 'Flight Types',
        tags: _flightTypes,
        controller: _flightController,
        hintText: 'Add value',
        onAdd: () {
          final text = _flightController.text.trim();
          if (text.isEmpty || _flightTypes.contains(text)) return;
          setState(() {
            _flightTypes.add(text);
            _flightController.clear();
          });
        },
        onRemove: (i) {
          if (_flightTypes.length > 1) {
            setState(() => _flightTypes.removeAt(i));
          }
        },
      ),
      const SizedBox(height: SpacingTokens.lg),
      const Text(
        'Green Conditions',
        style: TextStyle(
          fontSize: TypographyTokens.headerSize,
          fontWeight: TypographyTokens.headerWeight,
          color: ColorTokens.textPrimary,
        ),
      ),
      const SizedBox(height: SpacingTokens.sm),
      TextField(
        controller: _greenSpeedController,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: ColorTokens.textPrimary),
        decoration: InputDecoration(
          labelText: 'Green Speed (stimpmeter)',
          labelStyle:
              const TextStyle(color: ColorTokens.textSecondary),
          filled: true,
          fillColor: ColorTokens.surfacePrimary,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(ShapeTokens.radiusInput),
          ),
        ),
      ),
      const SizedBox(height: SpacingTokens.sm),
      DropdownButtonFormField<GreenFirmness>(
        initialValue: _greenFirmness,
        decoration: InputDecoration(
          labelText: 'Green Firmness',
          labelStyle:
              const TextStyle(color: ColorTokens.textSecondary),
          filled: true,
          fillColor: ColorTokens.surfacePrimary,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(ShapeTokens.radiusInput),
          ),
        ),
        dropdownColor: ColorTokens.surfaceModal,
        style: const TextStyle(color: ColorTokens.textPrimary),
        items: [
          const DropdownMenuItem<GreenFirmness>(
              value: null, child: Text('Not set')),
          ...GreenFirmness.values.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f.dbValue),
              )),
        ],
        onChanged: (v) => setState(() => _greenFirmness = v),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Shared tag section (used by wedge + chipping)
  // ---------------------------------------------------------------------------

  Widget _buildTagSection({
    required String title,
    required List<String> tags,
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: TypographyTokens.headerSize,
            fontWeight: TypographyTokens.headerWeight,
            color: ColorTokens.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Wrap(
          spacing: SpacingTokens.sm,
          children: tags.asMap().entries.map((entry) {
            return Chip(
              label: Text(entry.value),
              onDeleted:
                  tags.length > 1 ? () => onRemove(entry.key) : null,
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
                  hintText: hintText,
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
