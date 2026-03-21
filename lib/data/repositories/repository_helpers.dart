// Shared repository helper functions.
// Extracted from duplicated patterns across repositories.

import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';

/// Fetch an entity or throw [ValidationException] if null.
/// Replaces the repeated query-then-null-check-then-throw pattern.
Future<T> getRequiredEntity<T>(
  Future<T?> Function() query, {
  required String notFoundMessage,
  Map<String, dynamic>? context,
}) async {
  final entity = await query();
  if (entity == null) {
    throw ValidationException(
      code: ValidationException.requiredField,
      message: notFoundMessage,
      context: context,
    );
  }
  return entity;
}

/// Validate that a slot index is within bounds.
/// Replaces the repeated bounds-check pattern in PlanningRepository.
void validateSlotIndex(int slotIndex, int capacity) {
  if (slotIndex < 0 || slotIndex >= capacity) {
    throw ValidationException(
      code: ValidationException.invalidStructure,
      message: 'Slot index out of range',
      context: {'slotIndex': slotIndex, 'capacity': capacity},
    );
  }
}

/// Execute a database transaction with standard error handling.
/// Rethrows [ZxGolfAppException] subtypes, wraps others in [SystemException].
Future<T> executeTransaction<T>(
  AppDatabase db,
  Future<T> Function() operation, {
  required String errorMessage,
  Map<String, dynamic>? errorContext,
}) async {
  try {
    return await db.transaction(() => operation());
  } on ZxGolfAppException {
    rethrow;
  } on Exception catch (e) {
    throw SystemException(
      code: SystemException.referentialIntegrity,
      message: errorMessage,
      context: {...?errorContext, 'error': e.toString()},
    );
  }
}
