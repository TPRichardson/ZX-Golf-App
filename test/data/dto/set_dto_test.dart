import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/set_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('PracticeSet DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final set = makePracticeSet();
      final json = set.toSyncDto();
      final companion = practiceSetFromSyncDto(json);

      expect(companion.setId.value, set.setId);
      expect(companion.sessionId.value, set.sessionId);
      expect(companion.setIndex.value, set.setIndex);
      expect(companion.isDeleted.value, set.isDeleted);
      expect(companion.createdAt.value, set.createdAt);
      expect(companion.updatedAt.value, set.updatedAt);
    });

    test('uses correct key names matching DB column names', () {
      final json = makePracticeSet().toSyncDto();
      expect(json.containsKey('SetID'), isTrue);
      expect(json.containsKey('SessionID'), isTrue);
      expect(json.containsKey('SetIndex'), isTrue);
    });
  });
}
