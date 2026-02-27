import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §3.1 — Database instance provider. Singleton for app lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
