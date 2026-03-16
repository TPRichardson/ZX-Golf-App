import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';

import 'repository_providers.dart';

/// Non-deleted training kit items for a user, ordered by category.
final userTrainingKitProvider =
    StreamProvider.family<List<UserTrainingItem>, String>((ref, userId) {
  return ref.watch(trainingKitRepositoryProvider).watchUserKit(userId);
});
