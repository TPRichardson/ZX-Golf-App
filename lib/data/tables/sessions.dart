import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// TD-02 §3.4 — Session table. One session per drill execution within a block.
class Sessions extends Table {
  @override
  String get tableName => 'Session';

  TextColumn get sessionId => text().named('SessionID')();
  TextColumn get drillId => text().named('DrillID')();
  TextColumn get practiceBlockId => text().named('PracticeBlockID')();
  DateTimeColumn get completionTimestamp =>
      dateTime().named('CompletionTimestamp').nullable()();
  TextColumn get status => text()
      .named('Status')
      .withDefault(const Constant('Active'))
      .map(const SessionStatusConverter())();
  BoolColumn get integrityFlag =>
      boolean().named('IntegrityFlag').withDefault(const Constant(false))();
  BoolColumn get integritySuppressed =>
      boolean().named('IntegritySuppressed').withDefault(const Constant(false))();
  TextColumn get surfaceType => text()
      .named('SurfaceType')
      .map(const SurfaceTypeConverter())
      .nullable()();
  TextColumn get userDeclaration =>
      text().named('UserDeclaration').nullable()();
  IntColumn get sessionDuration =>
      integer().named('SessionDuration').nullable()();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {sessionId};
}
