import 'package:zx_golf_app/data/enums.dart';

/// Equipment item in a user's profile.
/// Serialized as part of UserPreferences JSON.
class Equipment {
  final EquipmentType type;
  final Map<String, dynamic> properties;

  const Equipment({
    required this.type,
    this.properties = const {},
  });

  /// Launch monitor with optional brand/model.
  factory Equipment.launchMonitor({String? brand, String? model}) {
    return Equipment(
      type: EquipmentType.launchMonitor,
      properties: {
        if (brand != null) 'brand': brand,
        if (model != null) 'model': model,
      },
    );
  }

  /// Alignment sticks (no properties).
  factory Equipment.alignmentSticks() {
    return const Equipment(type: EquipmentType.alignmentSticks);
  }

  /// Putting gate with width in centimetres.
  factory Equipment.puttingGate({double? widthCm}) {
    return Equipment(
      type: EquipmentType.puttingGate,
      properties: {
        if (widthCm != null) 'widthCm': widthCm,
      },
    );
  }

  /// Whether the user has a specific equipment type.
  static bool hasType(List<Equipment> equipment, EquipmentType type) {
    return equipment.any((e) => e.type == type);
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    final type = EquipmentType.fromString(map['type'] as String);
    final props = Map<String, dynamic>.from(map)..remove('type');
    return Equipment(type: type, properties: props);
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.dbValue,
      ...properties,
    };
  }

  Equipment copyWith({Map<String, dynamic>? properties}) {
    return Equipment(
      type: type,
      properties: properties ?? this.properties,
    );
  }

  /// Convenience getters for launch monitor properties.
  String? get brand => properties['brand'] as String?;
  String? get model => properties['model'] as String?;

  /// Convenience getter for putting gate width (cm).
  double? get widthCm => (properties['widthCm'] as num?)?.toDouble();
}
