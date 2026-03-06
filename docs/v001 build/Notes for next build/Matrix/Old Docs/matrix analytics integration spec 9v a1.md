# ZX Golf App — Matrix & Gapping System
# Section 9 — Matrix Analytics Integration

**Version:** 9v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview, Section 2 — Matrix & Gapping Homepage, Section 3 — Gapping Chart Workflow, Section 4 — Wedge Matrix Workflow, Section 5 — Chipping Matrix Workflow, Section 6 — Matrix Runtime Model, Section 7 — Matrix Review Pages, Section 8 — Data Model Extensions

---

## 9.1 Overview

This section defines how matrix datasets generate insights and analytics for the player within the Review system.

Analytics transform raw `MatrixAttempt` records into meaningful measures of distance calibration, coverage, accuracy, and trend — turning the matrix data into actionable player value.

This section defines:

- Analytics data source and scope
- Aggregation eligibility rules
- Outlier trimming
- Weighted vs raw aggregation model
- The four analytics categories
- Automated insights layer
- Insight surfacing rules

---

## 9.2 Analytics Data Source

Matrix analytics operate across all completed `MatrixRun` records, not only those linked to `PerformanceSnapshot` records.

```
Analytics source = All MatrixRuns where RunState = Completed
```

All calculations are derived views computed at query time. No analytics values are stored as permanent fields.

---

## 9.3 Aggregation Eligibility Rules

### 9.3.1 Minimum Attempt Threshold

Analytics are only computed for `MatrixCell` records that meet the minimum attempt threshold.

```
AttemptCount ≥ 3
```

Cells with fewer than 3 attempts are excluded from all analytics calculations.

### 9.3.2 Excluded Cells

Cells marked as soft-excluded are ignored across all analytics.

```
ExcludedFromRun = true → excluded from analytics
```

### 9.3.3 Outlier Trimming

Before analytics values are calculated, outlier attempts are removed using a symmetric trim applied to the attempt dataset per cell.

**Trim rule:**

```
Remove the top 10% and bottom 10% of attempts by carry distance
```

For small datasets, trimming is applied proportionally.

**Example (5 attempts):**

```
Attempts (sorted): 58, 61, 62, 63, 68

10% trim = 0.5 attempts each end → round to nearest whole attempt
→ Remove 1 attempt from each end

Trimmed dataset: 61, 62, 63
```

**Example (10 attempts):**

```
10% trim = 1 attempt each end
→ Remove lowest and highest attempt
```

Trimmed datasets are used as the basis for all derived metrics. Raw attempt records are never modified.

---

## 9.4 Weighted Aggregation Model

### 9.4.1 Weighting Principle

All analytics default to a time-weighted aggregation model where more recent runs contribute more to derived values than older runs. This prevents outdated calibration data from dominating analytics.

### 9.4.2 Weight Formula

Each `MatrixRun` is assigned a weight based on its age in days relative to today.

```
weight = exp(−2.25 × √(age_days / 365))
```

**Example weights:**

| Run Age | Weight |
|---|---|
| 10 days | ≈ 0.90 |
| 30 days | ≈ 0.78 |
| 90 days | ≈ 0.63 |
| 180 days | ≈ 0.50 |
| 365 days | ≈ 0.32 |

### 9.4.3 Weighted Average Formula

For any derived metric (e.g. average carry distance), the weighted average is calculated as:

```
WeightedAverage =
  Σ(value × weight) / Σ(weight)
```

Applied across all eligible attempts from all eligible runs, where each attempt inherits the weight of its parent `MatrixRun`.

### 9.4.4 Raw vs Weighted Toggle

Users may toggle between weighted and raw aggregation on all analytics views.

**Example control:**

```
Aggregation
○ Weighted  ● Raw
```

**Raw mode** treats all eligible attempts equally regardless of run age.

**Weighted mode** (default) applies the decay formula above.

The toggle is available on each analytics view. The selected mode persists within the session but does not need to persist across sessions.

---

## 9.5 Analytics Categories

The Matrix system produces four analytics categories.

```
1. Club Distance Analytics      (Gapping Chart)
2. Wedge Coverage Analytics     (Wedge Matrix)
3. Chipping Accuracy Analytics  (Chipping Matrix)
4. Distance Trend Analytics     (all matrix types)
```

---

## 9.6 Club Distance Analytics

**Source:** Gapping Chart runs

**Location:** Review → Matrices → Gapping Charts (and referenced on Review → Clubs)

### 9.6.1 Metrics

For each club with sufficient data, the following metrics are calculated.

| Metric | Definition |
|---|---|
| Average Carry | Weighted mean carry distance (trimmed dataset) |
| Average Total | Weighted mean total distance (trimmed dataset) |
| Carry Consistency | Standard deviation of carry distances (trimmed dataset) |
| Distance Gap | Gap to next club by carry distance |
| Data Sources | Number of contributing runs |

### 9.6.2 Consistency Formula

```
CarryConsistency = StdDev(trimmed carry distances)
```

Lower values indicate more reliable distance control.

### 9.6.3 Example Display

```
7i

Average Carry       170y
Average Total       181y
Carry Consistency   ±2.4y
Distance Gap        +12y to 6i

Derived from 3 gapping sessions
```

### 9.6.4 Gap Analysis

Gap analytics are calculated between every adjacent club pair ordered by average carry distance.

```
Gap(n) = AvgCarry(n+1) − AvgCarry(n)
```

Gaps outside the user-configured thresholds (defined in Section 7.5) trigger visual warnings consistent with the per-run gap highlighting behaviour.

---

## 9.7 Wedge Coverage Analytics

**Source:** Wedge Matrix runs

**Location:** Review → Matrices → Wedge Matrices

### 9.7.1 Coverage Model

Wedge coverage analytics determine which distances the player can reliably produce, and whether any gaps or overlaps exist in their wedge system.

Each `MatrixCell` with sufficient data contributes one coverage point, plotted at its average carry distance.

### 9.7.2 Coverage Chart

The coverage chart plots all eligible shot types (Club × Effort × Flight combinations) along a continuous distance scale.

**Example:**

```
Distance Coverage

30y ─────────────────────────────────────── 110y

  52° 50% Low      ● 38y
  52° 50% Std      ● 42y
  52° 50% High     ● 46y
  56° 70% Low      ● 58y
  56° 70% Std      ● 62y
  56° 70% High     ● 67y
  60° 90% Low      ● 74y
  60° 90% Std      ● 79y
  60° 90% High     ● 84y
```

Flight types are colour-differentiated consistent with Section 7.7.3.

### 9.7.3 Coverage Metrics per Cell

For each plotted shot type:

| Metric | Definition |
|---|---|
| Average Carry | Weighted mean carry (trimmed) |
| Carry Consistency | StdDev of carry (trimmed) |
| Data Sources | Number of contributing runs |

### 9.7.4 Coverage Gap Detection

The system identifies distances within the player's overall wedge range that are not reliably covered by any shot type.

**Gap definition:**

A coverage gap exists where no eligible shot type produces an average carry within a threshold distance of a given yard marker.

This insight is surfaced as an automated observation. See Section 9.9.

### 9.7.5 Chart Filtering

The coverage chart supports filtering by all axes (Club, Effort, Flight), consistent with Section 7.7.4.

---

## 9.8 Chipping Accuracy Analytics

**Source:** Chipping Matrix runs

**Location:** Review → Matrices → Chipping Matrices

### 9.8.1 Metrics

For each `MatrixCell` with sufficient data, the following accuracy metrics are calculated.

| Metric | Definition |
|---|---|
| Average Carry | Weighted mean carry distance (trimmed) |
| Average Error | Mean of `|carry − target|` (trimmed) |
| Average Rollout | Weighted mean rollout distance (trimmed) |
| Average Total | Weighted mean total distance (trimmed) |
| Short Bias | Percentage of trimmed attempts finishing short of target |
| Carry Consistency | StdDev of carry distances (trimmed) |
| Data Sources | Number of contributing runs |

### 9.8.2 Aggregated Accuracy Overview

Accuracy is summarised across all clubs per target distance.

**Example:**

```
Distance Accuracy Overview

Target   Avg Error   Short Bias
5y        0.22y        55%
10y       0.28y        60%
15y       0.36y        58%
20y       0.44y        62%
```

This overview helps players identify which target distances show the weakest control.

### 9.8.3 Rollout Analytics

Average rollout is displayed per measurement unit and aggregated by green condition where sufficient data exists.

**Example:**

```
SW — 10y — Standard

Average Rollout    3.8y
On Firm greens     5.1y  (2 sessions)
On Medium greens   3.6y  (1 session)
```

Green condition metadata from `MatrixRun` (Section 8.3.1) is used to segment rollout analytics where multiple sessions with differing conditions exist.

---

## 9.9 Distance Trend Analytics

**Source:** All matrix types

**Location:** Surfaced within each matrix type's review page

### 9.9.1 Eligibility

Distance trend analytics are displayed for any club or cell where the combined attempt dataset (across all contributing runs) meets the minimum threshold.

```
Total eligible attempts ≥ 3
```

Trend data is shown as soon as this threshold is met, even if only one run contributes.

### 9.9.2 Trend Data

Trend analytics plot average carry distance over time, one point per completed `MatrixRun`.

**Example:**

```
7i Carry Distance Trend

Run Jan   168y
Run Mar   170y
Run Jun   172y
```

Each point represents the per-run average carry for that cell, calculated from the trimmed attempt dataset for that run only (not the cross-run weighted average).

### 9.9.3 Trend Sources by Matrix Type

| Matrix Type | Trend dimension |
|---|---|
| Gapping Chart | Per-club carry trend |
| Wedge Matrix | Per-cell carry trend (Club × Effort × Flight) |
| Chipping Matrix | Per-cell carry and rollout trend |

### 9.9.4 Weighted vs Raw in Trend View

The weighted/raw toggle (Section 9.4.4) applies to trend views. In weighted mode, the plotted trend points are weighted averages; in raw mode they are unweighted per-run averages.

---

## 9.10 Automated Insights

### 9.10.1 Insight Model

The analytics system generates short automated observations based on the computed analytics data. These observations are displayed contextually within matrix review pages — they do not appear in a separate dedicated section.

Insights are lightweight observations, not coaching recommendations.

### 9.10.2 Surfacing Rule

Insights appear inline on the relevant matrix review page, in close proximity to the data that triggered them.

**Example placement:**

```
[Distance Ladder Chart]

⚑ Your 8i and 9i carry only 7y apart. Consider recalibrating one club.

[Numerical Table]
```

### 9.10.3 Insight Types by Category

**Gapping Chart Insights:**

| Trigger | Example Insight |
|---|---|
| Gap below minimum threshold | *"Your 8i–9i gap is 7y — below your minimum of 10y."* |
| Gap above maximum threshold | *"Your 5i–6i gap is 24y — above your maximum of 20y."* |
| High carry inconsistency | *"Your 7i carry varies by ±5y. More data may improve reliability."* |

**Wedge Matrix Insights:**

| Trigger | Example Insight |
|---|---|
| Coverage gap detected | *"No shot type reliably covers 55–65y in your current wedge system."* |
| Distance overlap detected | *"Your 56° 70% High and 60° 90% Low produce similar distances (67y / 66y)."* |

**Chipping Matrix Insights:**

| Trigger | Example Insight |
|---|---|
| Consistent short bias | *"Your 10y chips land short on average. Check carry target alignment."* |
| High average error at a distance | *"Your 20y chip accuracy (avg error 0.8y) is significantly lower than shorter distances."* |
| Rollout variance by condition | *"Your rollout on firm greens averages 5.1y vs 3.6y on medium greens."* |

### 9.10.4 Insight Display Rules

- Insights are generated only when sufficient data exists (minimum 3 eligible attempts)
- A maximum of **3 insights** are displayed per review page to avoid noise
- Insights are ranked by relevance (magnitude of the detected issue)
- Insights do not replace or duplicate the gap warning indicators already defined in Section 7.5

---

## 9.11 Decision Log

| # | Decision |
|---|---|
| 9.1 | Analytics operate across all completed MatrixRuns, not only snapshot-linked runs |
| 9.2 | All analytics values are derived at query time; none are stored permanently |
| 9.3 | Analytics require a minimum of 3 eligible attempts per cell |
| 9.4 | Excluded cells (ExcludedFromRun = true) are ignored in all analytics |
| 9.5 | Outlier trimming removes the top and bottom 10% of attempts per cell before calculation |
| 9.6 | All analytics default to time-weighted aggregation using the defined decay formula |
| 9.7 | Users may toggle between weighted and raw aggregation on all analytics views |
| 9.8 | Automated insights are displayed contextually within matrix review pages only |
| 9.9 | A maximum of 3 insights are shown per review page, ranked by relevance |
| 9.10 | Trend analytics are eligible as soon as 3 total attempts exist across all runs |
| 9.11 | Trend points represent per-run averages from trimmed data, not cross-run weighted averages |
| 9.12 | Rollout analytics are segmented by green condition where sufficient data exists |

---

*End of Section 9 — Matrix Analytics Integration*
