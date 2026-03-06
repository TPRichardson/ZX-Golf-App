// Phase M6 — Wedge Matrix setup screen.
// Matrix §3.2 — Configure and start a new Wedge Matrix run.

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

/// Matrix §3.2 — Setup screen for creating a new Wedge Matrix run.
/// User selects wedge clubs, effort levels, and shot target.
class WedgeSetupScreen extends ConsumerStatefulWidget {
  final String userId;

  const WedgeSetupScreen({super.key, required this.userId});

  @override
  ConsumerState<WedgeSetupScreen> createState() => _WedgeSetupScreenState();
}

class _WedgeSetupScreenState extends ConsumerState<WedgeSetupScreen> {
  final _shotTargetController = TextEditingController(text: '5');
  final Set<String> _selectedClubIds = {};
  final List<String> _effortLevels = ['Full', '3/4', '1/2'];
  final _effortController = TextEditingController();
  bool _creating = false;
  EnvironmentType? _environmentType;
  SurfaceType? _surfaceType;

  @override
  void dispose() {
    _shotTargetController.dispose();
    _effortController.dispose();
    super.dispose();
  }

  void _addEffortLevel() {
    final text = _effortController.text.trim();
    if (text.isEmpty || _effortLevels.contains(text)) return;
    setState(() {
      _effortLevels.add(text);
      _effortController.clear();
    });
  }

  void _removeEffortLevel(int index) {
    if (_effortLevels.length <= 1) return;
    setState(() => _effortLevels.removeAt(index));
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

      final config = MatrixRunConfig(
        matrixType: MatrixType.wedgeMatrix,
        sessionShotTarget: shotTarget,
        environmentType: _environmentType,
        surfaceType: _surfaceType,
        axes: [
          AxisConfig(
            axisType: AxisType.club,
            axisName: 'Club',
            labels: orderedLabels,
          ),
          AxisConfig(
            axisType: AxisType.effort,
            axisName: 'Effort',
            labels: List.from(_effortLevels),
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
        title: const Text('New Wedge Matrix'),
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
                  'Select Wedge Clubs',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                ...clubs.map((club) {
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
                    activeColor: ColorTokens.primaryDefault,
                    tileColor: ColorTokens.surfacePrimary,
                    dense: true,
                  );
                }),

                const SizedBox(height: SpacingTokens.lg),

                // Effort levels.
                const Text(
                  'Effort Levels',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Wrap(
                  spacing: SpacingTokens.sm,
                  children: _effortLevels.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      onDeleted: _effortLevels.length > 1
                          ? () => _removeEffortLevel(entry.key)
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
                        controller: _effortController,
                        style:
                            const TextStyle(color: ColorTokens.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Add effort level',
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
                        onSubmitted: (_) => _addEffortLevel(),
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    IconButton(
                      onPressed: _addEffortLevel,
                      icon: const Icon(Icons.add,
                          color: ColorTokens.primaryDefault),
                    ),
                  ],
                ),

                const SizedBox(height: SpacingTokens.lg),

                // Shot target.
                const Text(
                  'Shots Per Cell',
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style:
                        const TextStyle(color: ColorTokens.textPrimary),
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
              ],
            ),
          ),
        ),
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Start Matrix (${_selectedClubIds.length} × ${_effortLevels.length} = ${_selectedClubIds.length * _effortLevels.length} cells)',
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
