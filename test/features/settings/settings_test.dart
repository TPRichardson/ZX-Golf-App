import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/models/user_preferences.dart';
import 'package:zx_golf_app/data/repositories/user_repository.dart';

// Phase 8 — Settings integration tests.
// Tests preference persistence at the repository level.

void main() {
  late AppDatabase db;
  late UserRepository userRepo;

  const userId = 'test-user-settings';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    userRepo = UserRepository(db, SyncWriteGate());
  });

  tearDown(() async {
    await db.close();
  });

  Future<User> createUser() async {
    return userRepo.create(UsersCompanion.insert(userId: userId));
  }

  group('Settings Persistence', () {
    test('new user has default preferences (empty JSON)', () async {
      final user = await createUser();
      expect(user.unitPreferences, '{}');

      final prefs = UserPreferences.fromJson(user.unitPreferences);
      expect(prefs.distanceUnit, DistanceUnit.yards);
      expect(prefs.smallLengthUnit, SmallLengthUnit.inches);
    });

    test('preferences round-trip through UserRepository', () async {
      await createUser();

      final prefs = UserPreferences(
        distanceUnit: DistanceUnit.metres,
        smallLengthUnit: SmallLengthUnit.centimetres,
        defaultAnalysisResolution: 'monthly',
        defaultClubSelectionModes: {
          SkillArea.driving: ClubSelectionMode.guided,
        },
        reminderEnabled: true,
        reminderTime: '07:00',
      );

      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      final updated = await userRepo.getById(userId);
      expect(updated, isNotNull);

      final restored = UserPreferences.fromJson(updated!.unitPreferences);
      expect(restored.distanceUnit, DistanceUnit.metres);
      expect(restored.smallLengthUnit, SmallLengthUnit.centimetres);
      expect(restored.defaultAnalysisResolution, 'monthly');
      expect(restored.defaultClubSelectionModes[SkillArea.driving],
          ClubSelectionMode.guided);
      expect(restored.reminderEnabled, true);
      expect(restored.reminderTime, '07:00');
    });

    test('updating preferences preserves other user fields', () async {
      await userRepo.create(UsersCompanion.insert(
        userId: userId,
        displayName: const Value('Test User'),
        email: const Value('test@example.com'),
      ));

      final prefs = UserPreferences(distanceUnit: DistanceUnit.metres);
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      final user = await userRepo.getById(userId);
      expect(user!.displayName, 'Test User');
      expect(user.email, 'test@example.com');
    });

    test('distance unit toggle persists correctly', () async {
      await createUser();

      // Toggle to metres.
      var prefs = const UserPreferences();
      prefs = prefs.copyWith(distanceUnit: DistanceUnit.metres);
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      var user = await userRepo.getById(userId);
      var restored = UserPreferences.fromJson(user!.unitPreferences);
      expect(restored.distanceUnit, DistanceUnit.metres);

      // Toggle back to yards.
      prefs = prefs.copyWith(distanceUnit: DistanceUnit.yards);
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      user = await userRepo.getById(userId);
      restored = UserPreferences.fromJson(user!.unitPreferences);
      expect(restored.distanceUnit, DistanceUnit.yards);
    });

    test('small length unit toggle persists correctly', () async {
      await createUser();

      final prefs = const UserPreferences()
          .copyWith(smallLengthUnit: SmallLengthUnit.centimetres);
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      final user = await userRepo.getById(userId);
      final restored = UserPreferences.fromJson(user!.unitPreferences);
      expect(restored.smallLengthUnit, SmallLengthUnit.centimetres);
    });

    test('analysis resolution cycles through valid values', () async {
      await createUser();

      for (final resolution in ['daily', 'weekly', 'monthly']) {
        final prefs = const UserPreferences()
            .copyWith(defaultAnalysisResolution: resolution);
        await userRepo.update(
          userId,
          UsersCompanion(unitPreferences: Value(prefs.toJson())),
        );

        final user = await userRepo.getById(userId);
        final restored = UserPreferences.fromJson(user!.unitPreferences);
        expect(restored.defaultAnalysisResolution, resolution);
      }
    });

    test('club selection modes per skill area persist', () async {
      await createUser();

      final modes = {
        SkillArea.driving: ClubSelectionMode.guided,
        SkillArea.approach: ClubSelectionMode.userLed,
        SkillArea.putting: ClubSelectionMode.random,
      };
      final prefs = const UserPreferences()
          .copyWith(defaultClubSelectionModes: modes);
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      final user = await userRepo.getById(userId);
      final restored = UserPreferences.fromJson(user!.unitPreferences);
      expect(restored.defaultClubSelectionModes.length, 3);
      expect(restored.defaultClubSelectionModes[SkillArea.driving],
          ClubSelectionMode.guided);
    });

    test('reminder settings persist', () async {
      await createUser();

      final prefs = const UserPreferences().copyWith(
        reminderEnabled: true,
        reminderTime: '18:30',
      );
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      final user = await userRepo.getById(userId);
      final restored = UserPreferences.fromJson(user!.unitPreferences);
      expect(restored.reminderEnabled, true);
      expect(restored.reminderTime, '18:30');
    });

    test('multiple preference updates accumulate correctly', () async {
      await createUser();

      // First update: change distance.
      var prefs = const UserPreferences()
          .copyWith(distanceUnit: DistanceUnit.metres);
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      // Second update: read current, then add reminder.
      final user = await userRepo.getById(userId);
      prefs = UserPreferences.fromJson(user!.unitPreferences);
      prefs = prefs.copyWith(reminderEnabled: true, reminderTime: '09:00');
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      // Both changes should be present.
      final final_ = await userRepo.getById(userId);
      final restored = UserPreferences.fromJson(final_!.unitPreferences);
      expect(restored.distanceUnit, DistanceUnit.metres);
      expect(restored.reminderEnabled, true);
      expect(restored.reminderTime, '09:00');
    });

    test('empty defaultClubSelectionModes serializes as empty map', () async {
      await createUser();

      final prefs = const UserPreferences();
      await userRepo.update(
        userId,
        UsersCompanion(unitPreferences: Value(prefs.toJson())),
      );

      final user = await userRepo.getById(userId);
      final restored = UserPreferences.fromJson(user!.unitPreferences);
      expect(restored.defaultClubSelectionModes, isEmpty);
    });
  });
}
