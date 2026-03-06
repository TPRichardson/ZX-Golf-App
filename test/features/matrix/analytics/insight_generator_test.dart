import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/features/matrix/analytics/analytics_types.dart';
import 'package:zx_golf_app/features/matrix/analytics/insight_generator.dart';

// Phase M10 — Insight generator tests (§9.10).

void main() {
  group('generateGappingInsights', () {
    test('small gap triggers insight', () {
      final results = [
        ClubDistanceResult(
          clubLabel: 'PW',
          axisValueId: 'v-pw',
          avgCarry: 135,
          avgTotal: 142,
          carryConsistency: 2,
          distanceGap: 4, // < 6 min
          dataSources: 2,
          attemptCount: 10,
        ),
        ClubDistanceResult(
          clubLabel: '9i',
          axisValueId: 'v-9i',
          avgCarry: 139,
          avgTotal: 147,
          carryConsistency: 2,
          distanceGap: null,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateGappingInsights(results);
      expect(insights.length, 1);
      expect(insights.first.type, InsightType.smallGap);
      expect(insights.first.message, contains('PW'));
      expect(insights.first.message, contains('9i'));
      expect(insights.first.message, contains('4y'));
    });

    test('large gap triggers insight', () {
      final results = [
        ClubDistanceResult(
          clubLabel: 'PW',
          axisValueId: 'v-pw',
          avgCarry: 135,
          avgTotal: 142,
          carryConsistency: 2,
          distanceGap: 25, // > 20 max
          dataSources: 2,
          attemptCount: 10,
        ),
        ClubDistanceResult(
          clubLabel: '9i',
          axisValueId: 'v-9i',
          avgCarry: 160,
          avgTotal: 168,
          carryConsistency: 2,
          distanceGap: null,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateGappingInsights(results);
      expect(insights.length, 1);
      expect(insights.first.type, InsightType.largeGap);
      expect(insights.first.message, contains('25y'));
    });

    test('high inconsistency triggers insight', () {
      final results = [
        ClubDistanceResult(
          clubLabel: '7i',
          axisValueId: 'v-7i',
          avgCarry: 170,
          avgTotal: 181,
          carryConsistency: 7, // > 5 threshold
          distanceGap: null,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateGappingInsights(results);
      expect(insights.length, 1);
      expect(insights.first.type, InsightType.highInconsistency);
      expect(insights.first.message, contains('7i'));
    });

    test('no insights for normal gaps', () {
      final results = [
        ClubDistanceResult(
          clubLabel: 'PW',
          axisValueId: 'v-pw',
          avgCarry: 135,
          avgTotal: 142,
          carryConsistency: 2,
          distanceGap: 13, // within [6, 20]
          dataSources: 2,
          attemptCount: 10,
        ),
        ClubDistanceResult(
          clubLabel: '9i',
          axisValueId: 'v-9i',
          avgCarry: 148,
          avgTotal: 156,
          carryConsistency: 2,
          distanceGap: null,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateGappingInsights(results);
      expect(insights, isEmpty);
    });

    test('max 3 insights enforced', () {
      // 5 clubs all with small gaps + high inconsistency = many triggers.
      final results = List.generate(5, (i) => ClubDistanceResult(
            clubLabel: 'Club$i',
            axisValueId: 'v-$i',
            avgCarry: 130 + i * 3.0, // gaps of 3 < 6
            avgTotal: 140 + i * 3.0,
            carryConsistency: 8, // > 5
            distanceGap: i < 4 ? 3 : null,
            dataSources: 2,
            attemptCount: 10,
          ));

      final insights = generateGappingInsights(results);
      expect(insights.length, lessThanOrEqualTo(3));
    });
  });

  group('generateWedgeInsights', () {
    test('coverage gap detected', () {
      final results = [
        WedgeCoverageResult(
          cellLabel: '52° 50% Low',
          cellKey: '["v-52","v-50","v-low"]',
          flightLabel: 'Low',
          avgCarry: 38,
          carryConsistency: 2,
          dataSources: 2,
          attemptCount: 10,
        ),
        WedgeCoverageResult(
          cellLabel: '56° 70% Low',
          cellKey: '["v-56","v-70","v-low"]',
          flightLabel: 'Low',
          avgCarry: 58, // gap of 20 > 10 threshold
          carryConsistency: 2,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateWedgeInsights(results);
      expect(insights.any((i) => i.type == InsightType.coverageGap), isTrue);
    });

    test('distance overlap detected', () {
      final results = [
        WedgeCoverageResult(
          cellLabel: '56° 70% High',
          cellKey: '["v-56","v-70","v-high"]',
          flightLabel: 'High',
          avgCarry: 67,
          carryConsistency: 2,
          dataSources: 2,
          attemptCount: 10,
        ),
        WedgeCoverageResult(
          cellLabel: '60° 90% Low',
          cellKey: '["v-60","v-90","v-low"]',
          flightLabel: 'Low',
          avgCarry: 66, // 1y apart < 3y threshold
          carryConsistency: 2,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateWedgeInsights(results);
      expect(
          insights.any((i) => i.type == InsightType.distanceOverlap), isTrue);
      expect(insights.first.message, contains('similar distances'));
    });

    test('no insight when well-spaced', () {
      final results = [
        WedgeCoverageResult(
          cellLabel: '52° 50% Low',
          cellKey: '["v-52","v-50","v-low"]',
          flightLabel: 'Low',
          avgCarry: 38,
          carryConsistency: 2,
          dataSources: 2,
          attemptCount: 10,
        ),
        WedgeCoverageResult(
          cellLabel: '52° 50% Std',
          cellKey: '["v-52","v-50","v-std"]',
          flightLabel: 'Standard',
          avgCarry: 42, // 4y apart, within threshold
          carryConsistency: 2,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateWedgeInsights(results);
      expect(insights, isEmpty);
    });

    test('empty results returns no insights', () {
      expect(generateWedgeInsights([]), isEmpty);
    });
  });

  group('generateChippingInsights', () {
    test('short bias insight generated', () {
      final results = [
        ChippingAccuracyResult(
          cellLabel: 'SW — 10 — Low',
          cellKey: '["v-sw","v-10","v-low"]',
          clubLabel: 'SW',
          targetDistance: 10,
          avgCarry: 9.5,
          avgError: 0.5,
          avgRollout: 3.2,
          avgTotal: 12.7,
          shortBias: 0.67, // > 0.60
          carryConsistency: 0.3,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateChippingInsights(results);
      expect(insights.any((i) => i.type == InsightType.shortBias), isTrue);
      expect(insights.first.message, contains('10y'));
      expect(insights.first.message, contains('short'));
    });

    test('high error insight generated', () {
      final results = [
        ChippingAccuracyResult(
          cellLabel: 'SW — 10 — Low',
          cellKey: '["v-sw","v-10","v-low"]',
          clubLabel: 'SW',
          targetDistance: 10,
          avgCarry: 10.1,
          avgError: 0.2,
          avgRollout: 3,
          avgTotal: 13.1,
          shortBias: 0.3,
          carryConsistency: 0.2,
          dataSources: 2,
          attemptCount: 10,
        ),
        ChippingAccuracyResult(
          cellLabel: 'SW — 20 — Low',
          cellKey: '["v-sw","v-20","v-low"]',
          clubLabel: 'SW',
          targetDistance: 20,
          avgCarry: 19.0,
          avgError: 0.8, // much higher than 0.2 — triggers
          avgRollout: 4,
          avgTotal: 23.0,
          shortBias: 0.4,
          carryConsistency: 0.5,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateChippingInsights(results);
      expect(insights.any((i) => i.type == InsightType.highError), isTrue);
      expect(insights.first.message, contains('20y'));
    });

    test('no insights when accuracy is uniform', () {
      final results = [
        ChippingAccuracyResult(
          cellLabel: 'SW — 10 — Low',
          cellKey: '["v-sw","v-10","v-low"]',
          clubLabel: 'SW',
          targetDistance: 10,
          avgCarry: 10.1,
          avgError: 0.3,
          avgRollout: 3,
          avgTotal: 13.1,
          shortBias: 0.5, // at threshold, not over
          carryConsistency: 0.2,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateChippingInsights(results);
      expect(insights, isEmpty);
    });

    test('max 3 insights enforced', () {
      // 5 cells all with short bias > threshold.
      final results = List.generate(
          5,
          (i) => ChippingAccuracyResult(
                cellLabel: 'SW — ${5 + i * 5} — Low',
                cellKey: '["v-sw","v-${5 + i * 5}","v-low"]',
                clubLabel: 'SW',
                targetDistance: (5 + i * 5).toDouble(),
                avgCarry: (4 + i * 5).toDouble(),
                avgError: 0.5,
                avgRollout: 3,
                avgTotal: (7 + i * 5).toDouble(),
                shortBias: 0.70 + i * 0.05,
                carryConsistency: 0.3,
                dataSources: 2,
                attemptCount: 10,
              ));

      final insights = generateChippingInsights(results);
      expect(insights.length, lessThanOrEqualTo(3));
    });
  });

  group('ranking', () {
    test('insights ranked by magnitude (highest first)', () {
      final results = [
        ClubDistanceResult(
          clubLabel: 'PW',
          axisValueId: 'v-pw',
          avgCarry: 135,
          avgTotal: 142,
          carryConsistency: 2,
          distanceGap: 4, // magnitude = 6-4 = 2
          dataSources: 2,
          attemptCount: 10,
        ),
        ClubDistanceResult(
          clubLabel: '9i',
          axisValueId: 'v-9i',
          avgCarry: 139,
          avgTotal: 147,
          carryConsistency: 10, // magnitude = 10-5 = 5
          distanceGap: 2, // magnitude = 6-2 = 4
          dataSources: 2,
          attemptCount: 10,
        ),
        ClubDistanceResult(
          clubLabel: '8i',
          axisValueId: 'v-8i',
          avgCarry: 141,
          avgTotal: 149,
          carryConsistency: 2,
          distanceGap: null,
          dataSources: 2,
          attemptCount: 10,
        ),
      ];

      final insights = generateGappingInsights(results);
      expect(insights.length, 3);
      // Highest magnitude first.
      expect(insights[0].magnitude, greaterThanOrEqualTo(insights[1].magnitude));
      expect(insights[1].magnitude, greaterThanOrEqualTo(insights[2].magnitude));
    });
  });
}
