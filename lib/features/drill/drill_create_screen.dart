import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_button.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/core/widgets/zx_input_field.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// Phase 3 — Multi-step drill creation screen.
// S04 §4.2 — Validates all creation constraints before insert.

class DrillCreateScreen extends ConsumerStatefulWidget {
  const DrillCreateScreen({super.key});

  @override
  ConsumerState<DrillCreateScreen> createState() => _DrillCreateScreenState();
}

class _DrillCreateScreenState extends ConsumerState<DrillCreateScreen> {
  static const _userId = kDevUserId;

  int _step = 0;
  final _nameController = TextEditingController();

  // Step 0: Name.
  // Step 1: Skill Area.
  SkillArea? _skillArea;
  // Step 2: Drill Type.
  DrillType? _drillType;
  // Metric Schema.
  String? _metricSchemaId;
  List<MetricSchema> _schemas = [];
  // Set structure (scored only).
  int _requiredSetCount = 1;
  int? _requiredAttemptsPerSet = 10;

  // Controllers for set structure step — must be class-level to survive rebuilds.
  late final TextEditingController _setCountCtrl;
  late final TextEditingController _attemptsCtrl;

  String? _errorMessage;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _setCountCtrl = TextEditingController(text: _requiredSetCount.toString());
    _attemptsCtrl =
        TextEditingController(text: _requiredAttemptsPerSet?.toString() ?? '');
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
    _setCountCtrl.dispose();
    _attemptsCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  // Optional target value for custom drills (replaces anchors).
  double? _target;
  late final TextEditingController _targetCtrl =
      TextEditingController(text: '');

  // Technique: Name→SkillArea→DrillType→MetricSchema (4 steps).
  // Scored: Name→SkillArea→DrillType→MetricSchema→SetStructure→Target (6 steps).
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
      0 => _buildNameStep(),
      1 => _buildSkillAreaStep(),
      2 => _buildDrillTypeStep(),
      // Technique: MetricSchema at step 3 (last step).
      // Scored: MetricSchema→SetStructure→Target.
      3 => _buildMetricSchemaStep(),
      4 => _buildSetStructureStep(),
      5 => _buildTargetStep(),
      _ => _buildTargetStep(),
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
          controller: _setCountCtrl,
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
          controller: _attemptsCtrl,
          keyboardType: TextInputType.number,
          hintText: 'Leave empty for unlimited',
          onChanged: (val) {
            _requiredAttemptsPerSet = int.tryParse(val);
          },
        ),
      ],
    );
  }

  Widget _buildTargetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Target (Optional)',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ColorTokens.textPrimary,
              ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Set a personal target for this drill. '
          'This is for your reference only and does not affect scoring.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColorTokens.textSecondary,
              ),
        ),
        const SizedBox(height: SpacingTokens.md),
        ZxInputField(
          label: 'Target (e.g. hit rate %, distance)',
          controller: _targetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hintText: 'Leave empty for no target',
          onChanged: (val) {
            _target = double.tryParse(val);
          },
        ),
      ],
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
      ],
    );
  }

  Widget _buildNavigation() {
    // Technique: last step is 3. Scored: last step is 6.
    final isLastStep = _step == _totalSteps - 1;

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
        // 7A — Save & Practice shortcut on last step.
        if (isLastStep) ...[
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: ZxButton(
              label: 'Save & Practice',
              variant: ZxButtonVariant.secondary,
              isLoading: _isCreating,
              onPressed: _saveAndPractice,
            ),
          ),
        ],
      ],
    );
  }

  void _nextStep() {
    setState(() => _errorMessage = null);

    // Validate current step.
    switch (_step) {
      case 0: // Name.
        if (_nameController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Enter a drill name');
          return;
        }
      case 1: // Skill Area.
        if (_skillArea == null) {
          setState(() => _errorMessage = 'Select a skill area');
          return;
        }
      case 2: // Drill Type.
        if (_drillType == null) {
          setState(() => _errorMessage = 'Select a drill type');
          return;
        }
        if (_drillType == DrillType.techniqueBlock) {
          _requiredSetCount = 1;
          _requiredAttemptsPerSet = null;
        }
      case 3: // MetricSchema.
        if (_metricSchemaId == null) {
          setState(() => _errorMessage = 'Select a metric schema');
          return;
        }
    }

    setState(() => _step++);
  }

  Future<void> _createDrill() async {
    setState(() => _isCreating = true);

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
              subskillMapping: const drift.Value('[]'),
              anchors: const drift.Value('{}'),
              target: drift.Value(_target),
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

  // 7A — Save drill then create PracticeBlock and navigate to queue.
  Future<void> _saveAndPractice() async {
    setState(() => _isCreating = true);

    final inputMode = _schemas
            .where((s) => s.metricSchemaId == _metricSchemaId)
            .firstOrNull
            ?.inputMode ??
        InputMode.rawDataEntry;

    try {
      final drill = await ref.read(drillRepositoryProvider).createCustomDrill(
            _userId,
            DrillsCompanion(
              name: drift.Value(_nameController.text.trim()),
              skillArea: drift.Value(_skillArea!),
              drillType: drift.Value(_drillType!),
              inputMode: drift.Value(inputMode),
              metricSchemaId: drift.Value(_metricSchemaId!),
              subskillMapping: const drift.Value('[]'),
              anchors: const drift.Value('{}'),
              target: drift.Value(_target),
              requiredSetCount: drift.Value(_requiredSetCount),
              requiredAttemptsPerSet: drift.Value(_requiredAttemptsPerSet),
            ),
          );

      if (!mounted) return;

      // Create PracticeBlock with the new drill.
      final actions = ref.read(practiceActionsProvider);
      final pb = await actions.startPracticeBlock(_userId,
          initialDrillIds: [drill.drillId]);

      if (!mounted) return;
      // Pop drill create from nested tab navigator, then push practice
      // on root navigator so it covers the shell.
      final rootNav = Navigator.of(context, rootNavigator: true);
      Navigator.of(context).pop();
      rootNav.push(
        MaterialPageRoute(
          builder: (_) => PracticeQueueScreen(
            practiceBlockId: pb.practiceBlockId,
            userId: _userId,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCreating = false;
      });
    }
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

}

