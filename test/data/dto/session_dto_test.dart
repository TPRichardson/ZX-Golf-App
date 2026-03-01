import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/session_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('Session DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final session = makeSession();
      final json = session.toSyncDto();
      final companion = sessionFromSyncDto(json);

      expect(companion.sessionId.value, session.sessionId);
      expect(companion.drillId.value, session.drillId);
      expect(companion.practiceBlockId.value, session.practiceBlockId);
      expect(companion.completionTimestamp.value, session.completionTimestamp);
      expect(companion.status.value, SessionStatus.closed);
      expect(companion.integrityFlag.value, false);
      expect(companion.integritySuppressed.value, false);
      expect(companion.userDeclaration.value, isNull);
      expect(companion.sessionDuration.value, 300);
      expect(companion.isDeleted.value, false);
    });

    test('no UserID in output (child entity)', () {
      final json = makeSession().toSyncDto();
      expect(json.containsKey('UserID'), isFalse);
    });

    test('nullable fields handle null', () {
      final json = makeSession().toSyncDto();
      json['CompletionTimestamp'] = null;
      json['SessionDuration'] = null;
      final companion = sessionFromSyncDto(json);
      expect(companion.completionTimestamp.value, isNull);
      expect(companion.sessionDuration.value, isNull);
    });
  });
}
