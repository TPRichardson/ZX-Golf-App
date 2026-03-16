import 'dart:convert';

import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// Equipment gate: block drill adoption when the user lacks required equipment.
// Migrated from UserPreferences JSON to UserTrainingItems table.

/// Legacy mapping for RequiredEquipment JSON values from old EquipmentType enum.
const _legacyMapping = <String, EquipmentCategory>{
  'AlignmentSticks': EquipmentCategory.alignmentAid,
  'LaunchMonitor': EquipmentCategory.launchMonitor,
  'PuttingGate': EquipmentCategory.puttingGate,
};

/// Parses the RequiredEquipment JSON column into a list of [EquipmentCategory].
List<EquipmentCategory> parseRequiredEquipment(String json) {
  if (json.isEmpty || json == '[]') return const [];
  try {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) {
      final str = e as String;
      // Support legacy values via mapping.
      return _legacyMapping[str] ?? EquipmentCategory.fromString(str);
    }).toList();
  } on Exception {
    return const [];
  }
}

/// Encodes a list of [EquipmentCategory] to JSON for the RequiredEquipment column.
String encodeRequiredEquipment(List<EquipmentCategory> categories) {
  return jsonEncode(categories.map((c) => c.dbValue).toList());
}

/// Validates that the user has all required equipment for a drill.
/// Queries the UserTrainingItems table for each required category.
/// Throws [ValidationException] listing missing equipment if any are absent.
Future<void> validateEquipmentEligibility(
  AppDatabase db,
  String userId,
  String requiredEquipmentJson,
) async {
  final required = parseRequiredEquipment(requiredEquipmentJson);
  if (required.isEmpty) return;

  final missing = <EquipmentCategory>[];
  for (final category in required) {
    final row = await (db.select(db.userTrainingItems)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.category.equalsValue(category))
          ..where((t) => t.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) {
      missing.add(category);
    }
  }

  if (missing.isNotEmpty) {
    final names = missing.map(_equipmentLabel).join(', ');
    throw ValidationException(
      code: ValidationException.invalidStructure,
      message: 'Missing equipment: $names. '
          'Add it in your Training Kit before adopting this drill.',
      context: {
        'missing': missing.map((c) => c.dbValue).toList(),
      },
    );
  }
}

String _equipmentLabel(EquipmentCategory category) {
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
