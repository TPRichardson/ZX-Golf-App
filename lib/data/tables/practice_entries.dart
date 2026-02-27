import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// TD-02 §3.7 — Practice entry table. Links drills to practice blocks with ordering.
class PracticeEntries extends Table {
  @override
  String get tableName => 'PracticeEntry';

  TextColumn get practiceEntryId => text().named('PracticeEntryID')();
  TextColumn get practiceBlockId => text().named('PracticeBlockID')();
  TextColumn get drillId => text().named('DrillID')();
  TextColumn get sessionId => text().named('SessionID').nullable()();
  TextColumn get entryType => text()
      .named('EntryType')
      .withDefault(const Constant('PendingDrill'))
      .map(const PracticeEntryTypeConverter())();
  IntColumn get positionIndex => integer().named('PositionIndex')();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {practiceEntryId};

  @override
  List<Set<Column>> get uniqueKeys => [
        {practiceBlockId, positionIndex},
      ];
}
