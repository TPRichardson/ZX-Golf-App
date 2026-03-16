import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/database_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';

// Training Kit item detail/create screen.
// Supports all 8 equipment categories with category-specific property fields.

class TrainingKitItemDetailScreen extends ConsumerStatefulWidget {
  final EquipmentCategory category;
  /// If non-null, we're editing an existing item.
  final String? existingItemId;

  const TrainingKitItemDetailScreen({
    super.key,
    required this.category,
    this.existingItemId,
  });

  @override
  ConsumerState<TrainingKitItemDetailScreen> createState() =>
      _TrainingKitItemDetailScreenState();
}

class _TrainingKitItemDetailScreenState
    extends ConsumerState<TrainingKitItemDetailScreen> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _makeController = TextEditingController();
  final _loftController = TextEditingController();
  final _widthController = TextEditingController();
  final _selectedSkillAreas = <SkillArea>{};
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existingItemId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadItem();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadItem() async {
    final db = ref.read(databaseProvider);
    final item = await (db.select(db.userTrainingItems)
          ..where((t) => t.itemId.equals(widget.existingItemId!)))
        .getSingleOrNull();
    if (item != null && mounted) {
      _nameController.text = item.name;
      // Parse skill areas from JSON array.
      try {
        final list = jsonDecode(item.skillAreas) as List<dynamic>;
        _selectedSkillAreas.addAll(
          list.map((e) => SkillArea.fromString(e as String)),
        );
      } on Exception {
        // Ignore malformed skill areas.
      }
      _applyProperties(item.properties);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyProperties(String propertiesJson) {
    if (propertiesJson == '{}' || propertiesJson.isEmpty) return;
    try {
      final map = jsonDecode(propertiesJson) as Map<String, dynamic>;
      if (map['brand'] != null) _brandController.text = map['brand'] as String;
      if (map['model'] != null) _modelController.text = map['model'] as String;
      if (map['make'] != null) _makeController.text = map['make'] as String;
      if (map['loft'] != null) _loftController.text = map['loft'].toString();
      if (map['widthCm'] != null) {
        _widthController.text = map['widthCm'].toString();
      }
    } on Exception {
      // Ignore malformed properties.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _makeController.dispose();
    _loftController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: ZxAppBar(title: _categoryLabel(widget.category)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: ZxAppBar(
        title: _isEditing ? 'Edit Item' : _categoryLabel(widget.category),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: ColorTokens.errorDestructive),
              onPressed: _deleteItem,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          // Name field — required, all categories.
          _FieldLabel('Name'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('Enter a name'),
          ),
          const SizedBox(height: SpacingTokens.lg),

          // Skill Areas — multi-select checkboxes matching golf bag pattern.
          _FieldLabel('Skill Areas'),
          const SizedBox(height: SpacingTokens.xs),
          for (final area in SkillArea.values)
            CheckboxListTile(
              title: Text(
                area.dbValue,
                style: const TextStyle(color: ColorTokens.textPrimary),
              ),
              value: _selectedSkillAreas.contains(area),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedSkillAreas.add(area);
                  } else {
                    _selectedSkillAreas.remove(area);
                  }
                });
              },
              activeColor: ColorTokens.primaryDefault,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: SpacingTokens.lg),

          // Category-specific fields.
          ..._categoryFields(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: ZxPillButton(
            label: _isEditing ? 'Save' : 'Add to Training Kit',
            variant: ZxPillVariant.primary,
            expanded: true,
            centered: true,
            isLoading: _isSaving,
            onTap: _isSaving ? null : _save,
          ),
        ),
      ),
    );
  }

  List<Widget> _categoryFields() {
    switch (widget.category) {
      case EquipmentCategory.launchMonitor:
        return [
          _FieldLabel('Brand'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _brandController,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('e.g. Garmin, Trackman'),
          ),
          const SizedBox(height: SpacingTokens.lg),
          _FieldLabel('Model'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _modelController,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('e.g. Approach R10'),
          ),
        ];
      case EquipmentCategory.puttingGate:
        return [
          _FieldLabel('Width (cm)'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _widthController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('Gate width in cm'),
          ),
        ];
      case EquipmentCategory.specialistTrainingClub:
        return [
          _FieldLabel('Make'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _makeController,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('e.g. Titleist'),
          ),
          const SizedBox(height: SpacingTokens.lg),
          _FieldLabel('Model'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _modelController,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('e.g. Vokey SM9'),
          ),
          const SizedBox(height: SpacingTokens.lg),
          _FieldLabel('Loft'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _loftController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('Degrees'),
          ),
        ];
      case EquipmentCategory.impactTrainer:
      case EquipmentCategory.tempoTrainer:
      case EquipmentCategory.puttingStrokeTrainer:
        return [
          _FieldLabel('Brand'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _brandController,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('Brand'),
          ),
          const SizedBox(height: SpacingTokens.lg),
          _FieldLabel('Model'),
          const SizedBox(height: SpacingTokens.xs),
          TextField(
            controller: _modelController,
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: _inputDecoration('Model'),
          ),
        ];
      case EquipmentCategory.alignmentAid:
      case EquipmentCategory.shortGameTarget:
        return [];
    }
  }

  Map<String, dynamic> _buildProperties() {
    final props = <String, dynamic>{};
    switch (widget.category) {
      case EquipmentCategory.launchMonitor:
        if (_brandController.text.trim().isNotEmpty) {
          props['brand'] = _brandController.text.trim();
        }
        if (_modelController.text.trim().isNotEmpty) {
          props['model'] = _modelController.text.trim();
        }
      case EquipmentCategory.puttingGate:
        final width = double.tryParse(_widthController.text.trim());
        if (width != null && width > 0) {
          props['widthCm'] = width;
        }
      case EquipmentCategory.specialistTrainingClub:
        if (_makeController.text.trim().isNotEmpty) {
          props['make'] = _makeController.text.trim();
        }
        if (_modelController.text.trim().isNotEmpty) {
          props['model'] = _modelController.text.trim();
        }
        final loft = double.tryParse(_loftController.text.trim());
        if (loft != null) {
          props['loft'] = loft;
        }
      case EquipmentCategory.impactTrainer:
      case EquipmentCategory.tempoTrainer:
      case EquipmentCategory.puttingStrokeTrainer:
        if (_brandController.text.trim().isNotEmpty) {
          props['brand'] = _brandController.text.trim();
        }
        if (_modelController.text.trim().isNotEmpty) {
          props['model'] = _modelController.text.trim();
        }
      case EquipmentCategory.alignmentAid:
      case EquipmentCategory.shortGameTarget:
        break;
    }
    return props;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final kitRepo = ref.read(trainingKitRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    final properties = jsonEncode(_buildProperties());
    final skillAreasJson = jsonEncode(
      _selectedSkillAreas.map((a) => a.dbValue).toList(),
    );

    try {
      if (_isEditing) {
        await kitRepo.updateItem(
          widget.existingItemId!,
          UserTrainingItemsCompanion(
            name: drift.Value(name),
            skillAreas: drift.Value(skillAreasJson),
            properties: drift.Value(properties),
          ),
        );
      } else {
        await kitRepo.addItem(
          userId,
          UserTrainingItemsCompanion(
            category: drift.Value(widget.category),
            name: drift.Value(name),
            skillAreas: drift.Value(skillAreasJson),
            properties: drift.Value(properties),
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showSoftConfirmation(
      context,
      title: 'Delete Item',
      message: 'Remove this item from your Training Kit?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    final kitRepo = ref.read(trainingKitRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await kitRepo.deleteItem(userId, widget.existingItemId!);
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: ColorTokens.textTertiary),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.sm + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorTokens.textTertiary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorTokens.textTertiary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ColorTokens.primaryDefault),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: TypographyTokens.bodySize,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textSecondary,
      ),
    );
  }
}

String _categoryLabel(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.specialistTrainingClub:
      return 'Specialist Training Club';
    case EquipmentCategory.launchMonitor:
      return 'Launch Monitor';
    case EquipmentCategory.puttingGate:
      return 'Putting Gate';
    case EquipmentCategory.alignmentAid:
      return 'Alignment Aid';
    case EquipmentCategory.impactTrainer:
      return 'Impact Trainer';
    case EquipmentCategory.tempoTrainer:
      return 'Tempo Trainer';
    case EquipmentCategory.puttingStrokeTrainer:
      return 'Putting Stroke Trainer';
    case EquipmentCategory.shortGameTarget:
      return 'Short Game Target';
  }
}
