import 'package:drift/drift.dart';

// TD-02 §3.5 — Set table. Groups instances within a session.
// DEVIATION: @DataClassName('PracticeSet') avoids clash with dart:core.Set.
// See CLAUDE.md Known Deviations.
@DataClassName('PracticeSet')
class Sets extends Table {
  @override
  String get tableName => 'Set';

  TextColumn get setId => text().named('SetID')();
  TextColumn get sessionId => text().named('SessionID')();
  IntColumn get setIndex => integer().named('SetIndex')();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {setId};

  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionId, setIndex},
      ];
}
