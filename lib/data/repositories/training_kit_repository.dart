import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/club_repository.dart';

// Training Kit repository. Manages UserTrainingItem CRUD with lifecycle-coupled
// specialist training clubs linked to the UserClub table.

class TrainingKitRepository {
  final AppDatabase _db;
  final SyncWriteGate _gate;
  final ClubRepository _clubRepo;

  static const _uuid = Uuid();

  TrainingKitRepository(this._db, this._gate, this._clubRepo);

  /// Reactive stream of non-deleted items ordered by category.
  Stream<List<UserTrainingItem>> watchUserKit(String userId) {
    return (_db.select(_db.userTrainingItems)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.category),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  /// Add an item to the training kit.
  /// For specialistTrainingClub: creates a linked UserClub in a transaction.
  Future<UserTrainingItem> addItem(
    String userId,
    UserTrainingItemsCompanion data,
  ) async {
    await _gate.awaitGateRelease();
    final itemId = _uuid.v4();
    final category = data.category.value;

    if (category == EquipmentCategory.specialistTrainingClub) {
      return _addSpecialistTrainingClub(userId, itemId, data);
    }

    final now = DateTime.now();
    final companion = data.copyWith(
      itemId: Value(itemId),
      userId: Value(userId),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    try {
      return await _db.into(_db.userTrainingItems).insertReturning(companion);
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to add training kit item',
        context: {'error': e.toString()},
      );
    }
  }

  Future<UserTrainingItem> _addSpecialistTrainingClub(
    String userId,
    String itemId,
    UserTrainingItemsCompanion data,
  ) async {
    // Parse properties for club fields.
    final propsJson = data.properties.present ? data.properties.value : '{}';
    final props = jsonDecode(propsJson) as Map<String, dynamic>;

    try {
      return await _db.transaction(() async {
        // Create linked UserClub.
        final club = await _clubRepo.addClub(
          userId,
          UserClubsCompanion(
            clubType: const Value(ClubType.trainingClub),
            make: Value(props['make'] as String?),
            model: Value(props['model'] as String?),
            loft: Value(props['loft'] != null
                ? (props['loft'] as num).toDouble()
                : null),
          ),
        );

        final now = DateTime.now();
        final companion = data.copyWith(
          itemId: Value(itemId),
          userId: Value(userId),
          linkedClubId: Value(club.clubId),
          createdAt: Value(now),
          updatedAt: Value(now),
        );

        return await _db
            .into(_db.userTrainingItems)
            .insertReturning(companion);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to add specialist training club',
        context: {'error': e.toString()},
      );
    }
  }

  /// Update item fields (name, properties, skill area).
  Future<UserTrainingItem> updateItem(
    String itemId,
    UserTrainingItemsCompanion data,
  ) async {
    await _gate.awaitGateRelease();
    try {
      final rows = await (_db.update(_db.userTrainingItems)
            ..where((t) => t.itemId.equals(itemId)))
          .writeReturning(data.copyWith(
        updatedAt: Value(DateTime.now()),
      ));
      if (rows.isEmpty) {
        throw ValidationException(
          code: ValidationException.requiredField,
          message: 'Training kit item not found',
          context: {'itemId': itemId},
        );
      }
      return rows.first;
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update training kit item',
        context: {'itemId': itemId, 'error': e.toString()},
      );
    }
  }

  /// Soft-delete an item. If it has a LinkedClubID, also deletes the linked club.
  Future<void> deleteItem(String userId, String itemId) async {
    await _gate.awaitGateRelease();

    final item = await (_db.select(_db.userTrainingItems)
          ..where((t) => t.itemId.equals(itemId)))
        .getSingleOrNull();
    if (item == null) return;

    await _db.transaction(() async {
      // Soft-delete the training kit item.
      await (_db.update(_db.userTrainingItems)
            ..where((t) => t.itemId.equals(itemId)))
          .write(UserTrainingItemsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      // If linked to a club, delete the club too.
      if (item.linkedClubId != null) {
        try {
          await _clubRepo.deleteClub(userId, item.linkedClubId!);
        } on ValidationException {
          // Club may have instances — just retire it instead.
          try {
            await _clubRepo.retireClub(userId, item.linkedClubId!);
          } catch (_) {
            // Already retired or deleted — proceed.
          }
        }
      }
    });
  }

  /// Check whether the user has at least one non-deleted item in the given category.
  Future<bool> hasCategory(String userId, EquipmentCategory category) async {
    final row = await (_db.select(_db.userTrainingItems)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.category.equalsValue(category))
          ..where((t) => t.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}
