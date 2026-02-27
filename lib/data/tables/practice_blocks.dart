import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// TD-02 §3.3 — Practice block table. Groups sessions into a practice session.
class PracticeBlocks extends Table {
  @override
  String get tableName => 'PracticeBlock';

  TextColumn get practiceBlockId => text().named('PracticeBlockID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get sourceRoutineId =>
      text().named('SourceRoutineID').nullable()();
  TextColumn get drillOrder =>
      text().named('DrillOrder').withDefault(const Constant('[]'))();
  DateTimeColumn get startTimestamp =>
      dateTime().named('StartTimestamp').clientDefault(() => DateTime.now())();
  DateTimeColumn get endTimestamp =>
      dateTime().named('EndTimestamp').nullable()();
  TextColumn get closureType => text()
      .named('ClosureType')
      .map(const ClosureTypeConverter())
      .nullable()();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {practiceBlockId};
}
