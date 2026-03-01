import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/event_log_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('EventLog DTO round-trip', () {
    test('full entity with all JSONB fields', () {
      final log = makeEventLog();
      final json = log.toSyncDto();
      final companion = eventLogFromSyncDto(json);

      expect(companion.eventLogId.value, log.eventLogId);
      expect(companion.userId.value, log.userId);
      expect(companion.deviceId.value, 'dev-001');
      expect(companion.eventTypeId.value, 'SessionCompletion');
      expect(companion.timestamp.value, log.timestamp);
      expect(companion.createdAt.value, log.createdAt);
    });

    test('no UpdatedAt in output (append-only)', () {
      final json = makeEventLog().toSyncDto();
      expect(json.containsKey('UpdatedAt'), isFalse);
    });

    test('AffectedEntityIDs JSONB round-trips as array', () {
      final json = makeEventLog().toSyncDto();
      expect(json['AffectedEntityIDs'], isA<List>());
      expect(json['AffectedEntityIDs'], ['s-001']);

      final companion = eventLogFromSyncDto(json);
      final decoded = jsonDecode(companion.affectedEntityIds.value!);
      expect(decoded, ['s-001']);
    });

    test('Metadata JSONB round-trips as object', () {
      final json = makeEventLog().toSyncDto();
      expect(json['Metadata'], isA<Map>());
      expect(json['Metadata']['score'], 3.5);
    });

    test('minimal event log with all nullable JSONB null', () {
      final log = makeEventLogMinimal();
      final json = log.toSyncDto();

      expect(json['DeviceID'], isNull);
      expect(json['AffectedEntityIDs'], isNull);
      expect(json['AffectedSubskills'], isNull);
      expect(json['Metadata'], isNull);

      final companion = eventLogFromSyncDto(json);
      expect(companion.deviceId.value, isNull);
      expect(companion.affectedEntityIds.value, isNull);
      expect(companion.affectedSubskills.value, isNull);
      expect(companion.metadata.value, isNull);
    });
  });
}
