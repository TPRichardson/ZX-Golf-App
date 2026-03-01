import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — UserDevice DTO serialisation.

extension UserDeviceSyncDto on UserDevice {
  Map<String, dynamic> toSyncDto() => {
        'DeviceID': deviceId,
        'UserID': userId,
        'DeviceLabel': deviceLabel,
        'RegisteredAt': registeredAt.toUtc().toIso8601String(),
        'LastSyncAt': lastSyncAt?.toUtc().toIso8601String(),
        'IsDeleted': isDeleted,
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

UserDevicesCompanion userDeviceFromSyncDto(Map<String, dynamic> json) =>
    UserDevicesCompanion(
      deviceId: Value(json['DeviceID'] as String),
      userId: Value(json['UserID'] as String),
      deviceLabel: Value(json['DeviceLabel'] as String?),
      registeredAt:
          Value(DateTime.parse(json['RegisteredAt'] as String)),
      lastSyncAt: Value(json['LastSyncAt'] != null
          ? DateTime.parse(json['LastSyncAt'] as String)
          : null),
      isDeleted: Value(json['IsDeleted'] as bool),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
