import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/practice_block_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('PracticeBlock DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final block = makePracticeBlock();
      final json = block.toSyncDto();
      final companion = practiceBlockFromSyncDto(json);

      expect(companion.practiceBlockId.value, block.practiceBlockId);
      expect(companion.userId.value, block.userId);
      expect(companion.sourceRoutineId.value, block.sourceRoutineId);
      expect(companion.startTimestamp.value, block.startTimestamp);
      expect(companion.endTimestamp.value, block.endTimestamp);
      expect(companion.closureType.value, ClosureType.manual);
      expect(companion.isDeleted.value, block.isDeleted);
    });

    test('DrillOrder JSONB round-trips as array', () {
      final block = makePracticeBlock();
      final json = block.toSyncDto();
      expect(json['DrillOrder'], isA<List>());
      expect(json['DrillOrder'], ['d-001', 'd-002']);

      final companion = practiceBlockFromSyncDto(json);
      final decoded = jsonDecode(companion.drillOrder.value);
      expect(decoded, ['d-001', 'd-002']);
    });

    test('minimal block with nullables null', () {
      final block = makePracticeBlockMinimal();
      final json = block.toSyncDto();

      expect(json['SourceRoutineID'], isNull);
      expect(json['EndTimestamp'], isNull);
      expect(json['ClosureType'], isNull);
      expect(json['DrillOrder'], isEmpty);

      final companion = practiceBlockFromSyncDto(json);
      expect(companion.sourceRoutineId.value, isNull);
      expect(companion.endTimestamp.value, isNull);
      expect(companion.closureType.value, isNull);
      expect(companion.drillOrder.value, '[]');
    });
  });
}
