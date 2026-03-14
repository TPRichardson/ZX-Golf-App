import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/features/planning/weakness_detection.dart';

// Phase 5 — WeaknessDetectionEngine tests.
// S08 §8.7 — Pure scoring-based drill selection.

void main() {
  late AppDatabase db;
  late WeaknessDetectionEngine engine;

  // In-memory DB only needed for MaterialisedSubskillScore and SubskillRef entities.
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = WeaknessDetectionEngine();
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to create MaterialisedSubskillScore via the DB entity.
  MaterialisedSubskillScore makeScore({
    required String subskill,
    SkillArea skillArea = SkillArea.putting,
    double transAvg = 3.0,
    double pressAvg = 3.0,
    double weightedAvg = 3.0,
    int allocation = 100,
  }) {
    return MaterialisedSubskillScore(
      userId: 'u',
      skillArea: skillArea,
      subskill: subskill,
      transitionAverage: transAvg,
      pressureAverage: pressAvg,
      weightedAverage: weightedAvg,
      subskillPoints: weightedAvg * (allocation / 1000),
      allocation: allocation,
    );
  }

  SubskillRef makeRef({
    required String id,
    SkillArea skillArea = SkillArea.putting,
    int allocation = 100,
  }) {
    return SubskillRef(
      subskillId: id,
      skillArea: skillArea,
      name: id,
      allocation: allocation,
      windowSize: 25,
    );
  }

  group('WeaknessDetectionEngine — rankSubskills (S08 §8.7.2)', () {
    test('WeaknessIndex calculation with known values', () {
      final scores = [
        makeScore(subskill: 'ss1', weightedAvg: 2.0, allocation: 200),
        makeScore(subskill: 'ss2', weightedAvg: 4.0, allocation: 100),
      ];
      final refs = [
        makeRef(id: 'ss1', allocation: 200),
        makeRef(id: 'ss2', allocation: 100),
      ];

      final ranked = engine.rankSubskills(scores, refs);

      // ss1: (5 - 2.0) * (200/1000) = 3.0 * 0.2 = 0.6
      // ss2: (5 - 4.0) * (100/1000) = 1.0 * 0.1 = 0.1
      expect(ranked[0].subskillId, 'ss1');
      expect(ranked[0].weaknessIndex, closeTo(0.6, 0.001));
      expect(ranked[1].subskillId, 'ss2');
      expect(ranked[1].weaknessIndex, closeTo(0.1, 0.001));
    });

    test('incomplete windows ranked above saturated', () {
      final scores = [
        makeScore(subskill: 'ss1', weightedAvg: 1.0, allocation: 200),
        // ss2 has no score (incomplete window).
      ];
      final refs = [
        makeRef(id: 'ss1', allocation: 200),
        makeRef(id: 'ss2', allocation: 50),
      ];

      final ranked = engine.rankSubskills(scores, refs);

      // ss2 should rank first (incomplete).
      expect(ranked[0].subskillId, 'ss2');
      expect(ranked[0].isIncomplete, isTrue);
      expect(ranked[1].subskillId, 'ss1');
      expect(ranked[1].isIncomplete, isFalse);
    });
  });

  group('WeaknessDetectionEngine — selectDrill (S08 §8.7.4)', () {
    final pool = [
      DrillWithScore(
        drillId: 'drill-1',
        name: 'Alpha Drill',
        skillArea: SkillArea.putting,
        drillType: DrillType.transition,
        subskillIds: {'putting_distance'},
        averageScore: 2.5,
        lastPracticed: DateTime(2026, 2, 20),
      ),
      DrillWithScore(
        drillId: 'drill-2',
        name: 'Beta Drill',
        skillArea: SkillArea.putting,
        drillType: DrillType.pressure,
        subskillIds: {'putting_distance'},
        averageScore: 4.0,
        lastPracticed: DateTime(2026, 3, 1),
      ),
      DrillWithScore(
        drillId: 'drill-3',
        name: 'Charlie Drill',
        skillArea: SkillArea.approach,
        drillType: DrillType.transition,
        subskillIds: {'approach_distance'},
        averageScore: 3.0,
        lastPracticed: DateTime(2026, 2, 25),
      ),
    ];

    final ranking = [
      const RankedSubskill(
        subskillId: 'putting_distance',
        skillArea: SkillArea.putting,
        transitionAverage: 2.5,
        pressureAverage: 3.0,
        weightedAverage: 2.8,
        allocation: 150,
        weaknessIndex: 0.33,
        isIncomplete: false,
      ),
      const RankedSubskill(
        subskillId: 'approach_distance',
        skillArea: SkillArea.approach,
        transitionAverage: 3.0,
        pressureAverage: 3.5,
        weightedAverage: 3.3,
        allocation: 100,
        weaknessIndex: 0.17,
        isIncomplete: false,
      ),
    ];

    test('weakest mode selects drill with highest weakness', () {
      final result = engine.selectDrill(
        const GenerationCriterion(mode: GenerationMode.weakest),
        pool,
        ranking,
        {},
      );

      // putting_distance has higher WeaknessIndex; among putting drills,
      // drill-1 has lower avg score → selected.
      expect(result, 'drill-1');
    });

    test('strength mode selects drill with lowest weakness', () {
      final result = engine.selectDrill(
        const GenerationCriterion(mode: GenerationMode.strength),
        pool,
        ranking,
        {},
      );

      // approach_distance has lower WeaknessIndex; drill-3 is only match → selected.
      // Actually both putting drills have higher WI. Strength sorts ascending WI.
      // approach_distance WI=0.17 < putting_distance WI=0.33
      // So drill-3 (irons) ranks first.
      expect(result, 'drill-3');
    });

    test('skill area filter narrows pool', () {
      final result = engine.selectDrill(
        const GenerationCriterion(
          skillArea: SkillArea.approach,
          mode: GenerationMode.weakest,
        ),
        pool,
        ranking,
        {},
      );

      expect(result, 'drill-3');
    });

    test('drill type filter narrows pool', () {
      final result = engine.selectDrill(
        const GenerationCriterion(
          drillTypes: [DrillType.pressure],
          mode: GenerationMode.weakest,
        ),
        pool,
        ranking,
        {},
      );

      expect(result, 'drill-2');
    });

    test('drill repetition block enforced', () {
      final result = engine.selectDrill(
        const GenerationCriterion(mode: GenerationMode.weakest),
        pool,
        ranking,
        {'drill-1'}, // Already selected.
      );

      // drill-1 blocked → drill-2 next best putting drill.
      expect(result, 'drill-2');
    });

    test('empty eligible pool returns null', () {
      final result = engine.selectDrill(
        const GenerationCriterion(
          skillArea: SkillArea.bunkers,
          mode: GenerationMode.weakest,
        ),
        pool,
        ranking,
        {},
      );

      expect(result, isNull);
    });

    test('random mode selects from pool (seeded)', () {
      final rng = Random(42);
      final result = engine.selectDrill(
        const GenerationCriterion(mode: GenerationMode.random),
        pool,
        ranking,
        {},
        random: rng,
      );

      expect(result, isNotNull);
      expect(pool.map((d) => d.drillId), contains(result));
    });

    test('novelty mode prefers least recent', () {
      final result = engine.selectDrill(
        const GenerationCriterion(
          skillArea: SkillArea.putting,
          mode: GenerationMode.novelty,
        ),
        pool,
        ranking,
        {},
      );

      // Both putting drills have same WI. drill-1 last practiced 2/20, drill-2 3/1.
      // Novelty prefers least recent → drill-1.
      expect(result, 'drill-1');
    });
  });

  group('WeaknessDetectionEngine — resolveEntries', () {
    test('resolves mixed fixed + criterion entries', () {
      final pool = [
        DrillWithScore(
          drillId: 'drill-a',
          name: 'A',
          skillArea: SkillArea.putting,
          drillType: DrillType.transition,
          subskillIds: {'putting_distance'},
          averageScore: 2.0,
        ),
      ];

      final ranking = [
        const RankedSubskill(
          subskillId: 'putting_distance',
          skillArea: SkillArea.putting,
          transitionAverage: 2.0,
          pressureAverage: 2.0,
          weightedAverage: 2.0,
          allocation: 100,
          weaknessIndex: 0.3,
          isIncomplete: false,
        ),
      ];

      final entries = [
        const RoutineEntry.fixed('drill-fixed'),
        RoutineEntry.criterion(const GenerationCriterion(
          skillArea: SkillArea.putting,
          mode: GenerationMode.weakest,
        )),
      ];

      final resolved = engine.resolveEntries(entries, pool, ranking, 5);

      expect(resolved.length, 2);
      expect(resolved[0], 'drill-fixed');
      expect(resolved[1], 'drill-a');
    });

    test('repetition block across resolve pass', () {
      final pool = [
        DrillWithScore(
          drillId: 'drill-only',
          name: 'Only',
          skillArea: SkillArea.putting,
          drillType: DrillType.transition,
          subskillIds: {'putting_distance'},
          averageScore: 2.0,
        ),
      ];

      final ranking = [
        const RankedSubskill(
          subskillId: 'putting_distance',
          skillArea: SkillArea.putting,
          transitionAverage: 2.0,
          pressureAverage: 2.0,
          weightedAverage: 2.0,
          allocation: 100,
          weaknessIndex: 0.3,
          isIncomplete: false,
        ),
      ];

      final entries = [
        RoutineEntry.criterion(const GenerationCriterion(
          mode: GenerationMode.weakest,
        )),
        RoutineEntry.criterion(const GenerationCriterion(
          mode: GenerationMode.weakest,
        )),
      ];

      final resolved = engine.resolveEntries(entries, pool, ranking, 5);

      // First criterion gets drill-only, second one can't (repetition block).
      expect(resolved[0], 'drill-only');
      expect(resolved[1], isNull);
    });

    test('limits to availableSlotCount', () {
      final entries = [
        const RoutineEntry.fixed('d1'),
        const RoutineEntry.fixed('d2'),
        const RoutineEntry.fixed('d3'),
      ];

      final resolved = engine.resolveEntries(entries, [], [], 2);
      expect(resolved.length, 2); // Capped at 2.
    });
  });
}
