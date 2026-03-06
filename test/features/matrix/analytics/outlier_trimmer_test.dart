import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/features/matrix/analytics/outlier_trimmer.dart';

// Phase M10 — Outlier trimmer tests (§9.3.3).

void main() {
  group('trimOutliers', () {
    test('5 attempts: removes 1 from each end', () {
      // Spec example: [58, 61, 62, 63, 68] → trim 1 each → [61, 62, 63]
      final result = trimOutliers([58, 61, 62, 63, 68]);
      expect(result, [61, 62, 63]);
    });

    test('10 attempts: removes 1 from each end', () {
      // 10% of 10 = 1
      final values = [50, 52, 54, 56, 58, 60, 62, 64, 66, 68];
      final result = trimOutliers(values.map((v) => v.toDouble()).toList());
      expect(result.length, 8);
      expect(result.first, 52);
      expect(result.last, 66);
    });

    test('3 attempts: no trimming (minimum threshold)', () {
      // 10% of 3 = 0.3, rounds to 0 → no trimming.
      final result = trimOutliers([60, 65, 70]);
      expect(result, [60, 65, 70]);
    });

    test('2 attempts: returns sorted input (below minimum)', () {
      final result = trimOutliers([70, 60]);
      expect(result, [60, 70]);
    });

    test('1 attempt: returns as-is', () {
      final result = trimOutliers([65]);
      expect(result, [65]);
    });

    test('empty list: returns empty', () {
      final result = trimOutliers([]);
      expect(result, isEmpty);
    });

    test('20 attempts: removes 2 from each end', () {
      // 10% of 20 = 2
      final values =
          List.generate(20, (i) => 100 + i.toDouble()); // 100..119
      final result = trimOutliers(values);
      expect(result.length, 16);
      expect(result.first, 102);
      expect(result.last, 117);
    });

    test('returns sorted output', () {
      final result = trimOutliers([68, 58, 63, 61, 62]);
      // After sorting: [58, 61, 62, 63, 68] → trim 1 each → [61, 62, 63]
      expect(result, [61, 62, 63]);
    });
  });
}
