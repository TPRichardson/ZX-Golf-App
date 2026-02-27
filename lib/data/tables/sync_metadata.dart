import 'package:drift/drift.dart';

// TD-02 §4 — Local-only sync metadata. Not synced to server.
class SyncMetadataEntries extends Table {
  @override
  String get tableName => 'SyncMetadata';

  TextColumn get key => text().named('Key')();
  TextColumn get value => text().named('Value')();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {key};
}
