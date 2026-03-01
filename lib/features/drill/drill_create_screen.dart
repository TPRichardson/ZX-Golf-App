import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_button.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/core/widgets/zx_input_field.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// Phase 3 — Multi-step drill creation screen.
// S04 §4.2 — Validates all creation constraints before insert.

class DrillCreateScreen extends ConsumerStatefulWidget {
  const DrillCreateScreen({super.key});

  @override
  ConsumerState<DrillCreateScreen> createState() => _DrillCreateScreenState();
}

class _DrillCreateScreenState extends ConsumerState<DrillCreateScreen> {
  static const _userId = 'local-user';

  int _step = 0;
  final _nameController = TextEditingController();

  // Step 0: Skill Area.
  SkillArea? _skillArea;
  // Step 1: Subskill(s).
  final Set<String> _selectedSubskills = {};
  List<SubskillRef> _availableSubskills = [];
  // Step 2: Drill Type.
  DrillType? _drillType;
  // Step 3: Metric Schema.
  String? _metricSchemaId;
  List<MetricSchema> _schemas = [];
  // Step 4: Set structure.
  int _requiredSetCount = 1;
  int? _requiredAttemptsPerSet = 10;
  // Step 5: Anchors.
  final Map<String, ({double min, double scratch, double pro})> _anchors = {};

  String? _errorMessage;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadSchemas();
  }

  Future<void> _loadSchemas() async {
    final schemas =
        await ref.read(drillRepositoryProvider).watchAllMetricSchemas().first;
    setState(() => _schemas = schemas);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _totalSteps => _drillType == DrillType.techniqueBlock ? 4 : 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZxAppBar(
        title: 'Create Drill',
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _step--;
                  _errorMessage = null;
                }),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator.
            LinearProgressIndicator(
              value: (_step + 1) / _totalSteps,
              backgroundColor: ColorTokens.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation(ColorTokens.primaryDefault),
            ),
            const SizedBox(height: SpacingTokens.lg),

            // Step content.
            Expanded(child: _buildStep()),

            // Error message.
            if (_errorMessage != null) ...[
              const SizedBox(height: SpacingTokens.sm),
              Text(
                _errorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: ColorTokens.errorDestructive),
              ),
            ],

            // Navigation.
            const SizedBox(height: SpacingTokens.md),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildSkillAreaStep(),
      1 => _buildSubskillStep(),
      2 => _buildDrillTypeStep(),
      3 => _buildMetricSchemaStep(),
      4 => _drillType == DrillType.techniqueBlock
          ? _buildNameStep()
          : _buildSetStructureStep(),
      5 => _buildAnchorsStep(),
      6 => _buildNameStep(),
      _ => _buildNameStep(),
    };
  }

  Widget _buildSkillAreaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Skill Area',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ColorTokens.textPrimary,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Expanded(
          child: ListView(
            children: [
              for (final area in SkillArea.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: ZxCard(
                    onTap: () => setState(() => _skillArea = area),
                    showBorder: _skillArea == area,
                    child: Row(
                      children: [
                        Icon(
                          _skillArea == area
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _skillArea == area
                              ? ColorTokens.primaryDefault
                              : ColorTokens.textTertiary,
                        ),
                        const SizedBox(width: SpacingTokens.sm),
                        Text(
                          area.dbValue,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: ColorTokens.textPrimary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubskillStep() {
    return FutureBuilder<List<SubskillRef>>(
      future: _loadSubskillsForArea(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        _availableSubskills = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Subskill(s)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ColorTokens.textPrimary,
                  ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'Choose which subskills this drill targets',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.textSecondary,
                  ),
            ),
            const SizedBox(height: SpacingTokens.md),
            Expanded(
              child: ListView(
                children: [
                  for (final sub in _availableSubskills)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: SpacingTokens.sm),
                      child: ZxCard(
                        onTap: () {
                          setState(() {
                            if (_selectedSubskills
                                .contains(sub.subskillId)) {
                              _selectedSubskills.remove(sub.subskillId);
                            } else {
                              _selectedSubskills.add(sub.subskillId);
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _selectedSubskills.contains(sub.subskillId)
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: _selectedSubskills
                                      .contains(sub.subskillId)
                                  ? ColorTokens.primaryDefault
                                  : ColorTokens.textTertiary,
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Text(
                              sub.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: ColorTokens.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrillTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Drill Type',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ColorTokens.textPrimary,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),
        for (final type in DrillType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: ZxCard(
              onTap: () => setState(() => _drillType = type),
              child: Row(
                children: [
                  Icon(
                    _drillType == type
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _drillType == type
                        ? ColorTokens.primaryDefault
                        : ColorTokens.textTertiary,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _drillTypeLabel(type),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: ColorTokens.textPrimary,
                                  ),
                        ),
                        Text(
                          _drillTypeDescription(type),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: ColorTokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricSchemaStep() {
    final relevantSchemas = _drillType == DrillType.techniqueBlock
        ? _schemas.where((s) => s.scoringAdapterBinding == 'None').toList()
        : _schemas.where((s) => s.scoringAdapterBinding != 'None').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Metric Schema',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ColorTokens.textPrimary,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Expanded(
          child: ListView(
            children: [
              for (final schema in relevantSchemas)
                Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: ZxCard(
                    onTap: () =>
                        setState(() => _metricSchemaId = schema.metricSchemaId),
                    child: Row(
                      children: [
                        Icon(
                          _metricSchemaId == schema.metricSchemaId
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _metricSchemaId == schema.metricSchemaId
                              ? ColorTokens.primaryDefault
                              : ColorTokens.textTertiary,
                        ),
                        const SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schema.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: ColorTokens.textPrimary,
                                    ),
                              ),
                              Text(
                                '${schema.inputMode.dbValue} - ${schema.scoringAdapterBinding}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: ColorTokens.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetStructureStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Structure',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ColorTokens.textPrimary,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),
        ZxInputField(
          label: 'Required Set Count',
          controller:
              TextEditingController(text: _requiredSetCount.toString()),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null && parsed > 0) {
              _requiredSetCount = parsed;
            }
          },
        ),
        const SizedBox(height: SpacingTokens.md),
        ZxInputField(
          label: 'Attempts Per Set',
          controller: TextEditingController(
              text: _requiredAttemptsPerSet?.toString() ?? ''),
          keyboardType: TextInputType.number,
          hintText: 'Leave empty for unlimited',
          onChanged: (val) {
            _requiredAttemptsPerSet = int.tryParse(val);
          },
        ),
      ],
    );
  }

  Widget _buildAnchorsStep() {
    // Ensure all selected subskills have anchor entries.
    for (final subId in _selectedSubskills) {
      _anchors.putIfAbsent(subId, () => (min: 30, scratch: 70, pro: 90));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Anchors',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ColorTokens.textPrimary,
                ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Define Min, Scratch, and Pro benchmark values',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorTokens.textSecondary,
                ),
          ),
          const SizedBox(height: SpacingTokens.md),
          for (final subId in _selectedSubskills) ...[
            _AnchorFields(
              subskillId: subId,
              label: _formatSubskillId(subId),
              initial: _anchors[subId]!,
              onChanged: (values) {
                _anchors[subId] = values;
              },
            ),
            const SizedBox(height: SpacingTokens.lg),
          ],
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name Your Drill',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ColorTokens.textPrimary,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),
        ZxInputField(
          label: 'Drill Name',
          controller: _nameController,
          hintText: 'Enter a descriptive name',
        ),
        const SizedBox(height: SpacingTokens.lg),
        // Summary.
        Text(
          'Summary',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColorTokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        if (_skillArea != null)
          _SummaryRow(label: 'Skill Area', value: _skillArea!.dbValue),
        if (_drillType != null)
          _SummaryRow(
              label: 'Drill Type', value: _drillTypeLabel(_drillType!)),
        _SummaryRow(
          label: 'Subskills',
          value: _selectedSubskills.isEmpty
              ? 'None'
              : _selectedSubskills.map(_formatSubskillId).join(', '),
        ),
      ],
    );
  }

  Widget _buildNavigation() {
    final isLastStep =
        (_drillType == DrillType.techniqueBlock && _step == 4) ||
        (_drillType != DrillType.techniqueBlock && _step == 6) ||
        (_step == _totalSteps - 1);

    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: ZxButton(
              label: 'Back',
              variant: ZxButtonVariant.secondary,
              onPressed: () => setState(() {
                _step--;
                _errorMessage = null;
              }),
            ),
          ),
        if (_step > 0) const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: ZxButton(
            label: isLastStep ? 'Create Drill' : 'Next',
            isLoading: _isCreating,
            onPressed: isLastStep ? _createDrill : _nextStep,
          ),
        ),
      ],
    );
  }

  void _nextStep() {
    setState(() => _errorMessage = null);

    // Validate current step.
    switch (_step) {
      case 0:
        if (_skillArea == null) {
          setState(() => _errorMessage = 'Select a skill area');
          return;
        }
      case 1:
        // Subskills are optional for technique blocks.
        break;
      case 2:
        if (_drillType == null) {
          setState(() => _errorMessage = 'Select a drill type');
          return;
        }
        if (_drillType == DrillType.techniqueBlock) {
          _requiredSetCount = 1;
          _requiredAttemptsPerSet = null;
          _selectedSubskills.clear();
        }
      case 3:
        if (_metricSchemaId == null) {
          setState(() => _errorMessage = 'Select a metric schema');
          return;
        }
    }

    setState(() => _step++);
  }

  Future<void> _createDrill() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter a drill name');
      return;
    }

    setState(() => _isCreating = true);

    // Build anchors JSON.
    final anchorsMap = <String, Map<String, double>>{};
    for (final entry in _anchors.entries) {
      anchorsMap[entry.key] = {
        'Min': entry.value.min,
        'Scratch': entry.value.scratch,
        'Pro': entry.value.pro,
      };
    }

    final inputMode = _schemas
            .where((s) => s.metricSchemaId == _metricSchemaId)
            .firstOrNull
            ?.inputMode ??
        InputMode.rawDataEntry;

    try {
      await ref.read(drillRepositoryProvider).createCustomDrill(
            _userId,
            DrillsCompanion(
              name: drift.Value(_nameController.text.trim()),
              skillArea: drift.Value(_skillArea!),
              drillType: drift.Value(_drillType!),
              inputMode: drift.Value(inputMode),
              metricSchemaId: drift.Value(_metricSchemaId!),
              subskillMapping: drift.Value(
                  jsonEncode(_selectedSubskills.toList())),
              anchors: drift.Value(jsonEncode(anchorsMap)),
              requiredSetCount: drift.Value(_requiredSetCount),
              requiredAttemptsPerSet:
                  drift.Value(_requiredAttemptsPerSet),
            ),
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCreating = false;
      });
    }
  }

  Future<List<SubskillRef>> _loadSubskillsForArea() async {
    if (_skillArea == null) return [];
    return (await ref
            .read(referenceRepositoryProvider)
            .watchSubskillsBySkillArea(_skillArea!)
            .first);
  }

  String _drillTypeLabel(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Technique Block',
      DrillType.transition => 'Transition',
      DrillType.pressure => 'Pressure',
    };
  }

  String _drillTypeDescription(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Unscored practice for building mechanics',
      DrillType.transition => 'Scored practice for developing consistency',
      DrillType.pressure => 'High-stakes scored practice',
    };
  }

  String _formatSubskillId(String id) {
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }
}

class _AnchorFields extends StatefulWidget {
  final String subskillId;
  final String label;
  final ({double min, double scratch, double pro}) initial;
  final ValueChanged<({double min, double scratch, double pro})> onChanged;

  const _AnchorFields({
    required this.subskillId,
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_AnchorFields> createState() => _AnchorFieldsState();
}

class _AnchorFieldsState extends State<_AnchorFields> {
  late TextEditingController _minCtrl;
  late TextEditingController _scratchCtrl;
  late TextEditingController _proCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl =
        TextEditingController(text: widget.initial.min.toStringAsFixed(0));
    _scratchCtrl = TextEditingController(
        text: widget.initial.scratch.toStringAsFixed(0));
    _proCtrl =
        TextEditingController(text: widget.initial.pro.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _scratchCtrl.dispose();
    _proCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final min = double.tryParse(_minCtrl.text) ?? 0;
    final scratch = double.tryParse(_scratchCtrl.text) ?? 0;
    final pro = double.tryParse(_proCtrl.text) ?? 0;
    widget.onChanged((min: min, scratch: scratch, pro: pro));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColorTokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Row(
          children: [
            Expanded(
              child: ZxInputField(
                label: 'Min',
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxInputField(
                label: 'Scratch',
                controller: _scratchCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxInputField(
                label: 'Pro',
                controller: _proCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _notify(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorTokens.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
