import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/user_device_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('UserDevice DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final device = makeUserDevice();
      final json = device.toSyncDto();
      final companion = userDeviceFromSyncDto(json);

      expect(companion.deviceId.value, device.deviceId);
      expect(companion.userId.value, device.userId);
      expect(companion.deviceLabel.value, 'Pixel 8');
      expect(companion.registeredAt.value, device.registeredAt);
      expect(companion.lastSyncAt.value, device.lastSyncAt);
      expect(companion.isDeleted.value, false);
      expect(companion.updatedAt.value, device.updatedAt);
    });

    test('nullable fields handle null', () {
      final json = makeUserDevice().toSyncDto();
      json['DeviceLabel'] = null;
      json['LastSyncAt'] = null;
      final companion = userDeviceFromSyncDto(json);
      expect(companion.deviceLabel.value, isNull);
      expect(companion.lastSyncAt.value, isNull);
    });
  });
}
