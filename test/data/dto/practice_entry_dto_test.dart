import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/practice_entry_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('PracticeEntry DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final entry = makePracticeEntry();
      final json = entry.toSyncDto();
      final companion = practiceEntryFromSyncDto(json);

      expect(companion.practiceEntryId.value, entry.practiceEntryId);
      expect(companion.practiceBlockId.value, entry.practiceBlockId);
      expect(companion.drillId.value, entry.drillId);
      expect(companion.sessionId.value, entry.sessionId);
      expect(companion.entryType.value, PracticeEntryType.completedSession);
      expect(companion.positionIndex.value, 0);
    });

    test('nullable SessionID handles null', () {
      final json = makePracticeEntry().toSyncDto();
      json['SessionID'] = null;
      final companion = practiceEntryFromSyncDto(json);
      expect(companion.sessionId.value, isNull);
    });
  });
}
