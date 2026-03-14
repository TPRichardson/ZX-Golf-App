import 'dart:convert';

import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/models/equipment.dart';
import 'package:zx_golf_app/data/models/user_preferences.dart';

// Equipment gate: block drill adoption when the user lacks required equipment.

/// Parses the RequiredEquipment JSON column into a list of [EquipmentType].
List<EquipmentType> parseRequiredEquipment(String json) {
  if (json.isEmpty || json == '[]') return const [];
  try {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => EquipmentType.fromString(e as String))
        .toList();
  } on Exception {
    return const [];
  }
}

/// Encodes a list of [EquipmentType] to JSON for the RequiredEquipment column.
String encodeRequiredEquipment(List<EquipmentType> types) {
  return jsonEncode(types.map((t) => t.dbValue).toList());
}

/// Validates that the user has all required equipment for a drill.
/// Reads the user's equipment profile from the DB and checks against drill requirements.
/// Throws [ValidationException] listing missing equipment if any are absent.
Future<void> validateEquipmentEligibility(
  AppDatabase db,
  String userId,
  String requiredEquipmentJson,
) async {
  final required = parseRequiredEquipment(requiredEquipmentJson);
  if (required.isEmpty) return;

  // Read user's equipment profile from DB.
  final user = await (db.select(db.users)
        ..where((t) => t.userId.equals(userId)))
      .getSingleOrNull();
  final prefs = user != null
      ? UserPreferences.fromJson(user.unitPreferences)
      : const UserPreferences();

  final missing = <EquipmentType>[];
  for (final type in required) {
    if (!Equipment.hasType(prefs.equipment, type)) {
      missing.add(type);
    }
  }

  if (missing.isNotEmpty) {
    final names = missing.map(_equipmentLabel).join(', ');
    throw ValidationException(
      code: ValidationException.invalidStructure,
      message: 'Missing equipment: $names. '
          'Add it in Settings → Equipment before adopting this drill.',
      context: {
        'missing': missing.map((t) => t.dbValue).toList(),
      },
    );
  }
}

String _equipmentLabel(EquipmentType type) {
  switch (type) {
    case EquipmentType.launchMonitor:
      return 'Launch Monitor';
    case EquipmentType.alignmentSticks:
      return 'Alignment Sticks';
    case EquipmentType.puttingGate:
      return 'Putting Gate';
  }
}
