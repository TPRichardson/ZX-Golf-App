import 'package:drift/drift.dart';

// Spec: S07 §7.9 — Event type reference table.
class EventTypeRefs extends Table {
  @override
  String get tableName => 'EventTypeRef';

  TextColumn get eventTypeId => text().named('EventTypeID')();
  TextColumn get name => text().named('Name')();
  TextColumn get description => text().named('Description').nullable()();

  @override
  Set<Column> get primaryKey => {eventTypeId};
}
