// Strokes-gained putting lookup: expected putts to hole out by distance.
// Source: PGA Tour ShotLink data (Mark Broadie, "Every Shot Counts", 2014).
// Used by chipping scoring game to compute fractional second-shot strokes.

/// Expected putts to hole out from [distance] feet (PGA Tour pro average).
/// Returns 0.0 for holed (0 ft), linearly interpolates between table entries,
/// and clamps to the 50ft value for distances beyond the table.
double expectedPuttsFromDistance(int distanceFeet) {
  if (distanceFeet <= 0) return 0.0;
  if (distanceFeet >= _kMaxTableDistance) {
    return _puttingTable[_kMaxTableDistance]!;
  }
  return _puttingTable[distanceFeet] ?? _interpolateTable(distanceFeet);
}

double _interpolateTable(int distance) {
  // Find surrounding entries.
  final lower = _puttingTable.entries
      .where((e) => e.key <= distance)
      .reduce((a, b) => a.key > b.key ? a : b);
  final upper = _puttingTable.entries
      .where((e) => e.key >= distance)
      .reduce((a, b) => a.key < b.key ? a : b);
  if (lower.key == upper.key) return lower.value;
  final fraction = (distance - lower.key) / (upper.key - lower.key);
  return lower.value + fraction * (upper.value - lower.value);
}

const _kMaxTableDistance = 50;

/// PGA Tour average putts to hole out from distance (feet).
const _puttingTable = <int, double>{
  1: 1.001,
  2: 1.009,
  3: 1.040,
  4: 1.090,
  5: 1.150,
  6: 1.210,
  7: 1.260,
  8: 1.310,
  9: 1.350,
  10: 1.390,
  11: 1.420,
  12: 1.450,
  13: 1.470,
  14: 1.500,
  15: 1.520,
  16: 1.540,
  17: 1.560,
  18: 1.570,
  19: 1.590,
  20: 1.610,
  21: 1.620,
  22: 1.630,
  23: 1.650,
  24: 1.660,
  25: 1.670,
  26: 1.680,
  27: 1.690,
  28: 1.700,
  29: 1.710,
  30: 1.720,
  31: 1.730,
  32: 1.740,
  33: 1.750,
  34: 1.760,
  35: 1.770,
  36: 1.780,
  37: 1.790,
  38: 1.790,
  39: 1.800,
  40: 1.810,
  41: 1.820,
  42: 1.820,
  43: 1.830,
  44: 1.840,
  45: 1.840,
  46: 1.850,
  47: 1.860,
  48: 1.860,
  49: 1.870,
  50: 1.870,
};
