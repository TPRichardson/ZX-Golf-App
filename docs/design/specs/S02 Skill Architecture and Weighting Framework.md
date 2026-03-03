Section 2 — Skill Architecture & Weighting Framework

Version 2v.f1 — Consolidated

This document defines the canonical Skill Architecture and Weighting Framework. It is fully harmonised with Section 1 (Scoring Engine 1v.g2) and the Canonical Definitions (0v.f1).

2.1 Canonical Skill Tree

Overall (1000)

Irons (280): Distance Control (110), Direction Control (110), Shape Control (60)

Driving (240): Distance Maximum (95), Direction Control (95), Shape Control (50)

Putting (200): Distance Control (100), Direction Control (100)

Pitching (100): Distance Control (40), Direction Control (40), Flight Control (20)

Chipping (100): Distance Control (40), Direction Control (40), Flight Control (20)

Woods (50): Distance Control (20), Direction Control (20), Shape Control (10)

Bunkers (30): Distance Control (15), Direction Control (15)

Structural Guarantees

1. All Skill Areas sum to 1000.

2. All Subskills sum exactly to their Skill Area allocation.

3. It is impossible to max a Skill Area while ignoring a Subskill.

4. No redistribution occurs for unused Subskills.

5. Skill Area selection determines Skill Area mapping. Eligible clubs are filtered from the user’s configured bag.

2.2 Skill Area Definitions

When creating a drill, the user selects a Skill Area first, then chooses a club. Only clubs from the user’s configured bag that are eligible for the selected Skill Area are shown.

Eligible club types per Skill Area are user-configurable with mandatory minimums and system defaults. The canonical mapping model, including mandatory assignments and default configurations, is defined in Section 9 (§9.2). The following are the mandatory mappings that cannot be removed:

• Driving → Driver (mandatory)

• Irons → i1–i9 (mandatory)

• Putting → Putter (mandatory)

All other Skill Area mappings (Pitching, Chipping, Woods, Bunkers) are user-configurable. See Section 9 for default assignments.

The user defines their bag in the Golf Bag & Club Configuration (Section 9). Eligible clubs are filtered against the user’s bag and Skill Area mappings at drill creation time.

Cross-Skill-Area mapping is prohibited.

2.3 Subskill Definitions

Irons

Distance Control (110): Carry proximity and depth dispersion control.

Direction Control (110): Start-line and lateral dispersion control.

Shape Control (60): Intentional curvature execution (draw/fade).

Driving

Distance Maximum (95): Maximal carry distance production.

Direction Control (95): Fairway/start-line accuracy.

Shape Control (50): Intentional curvature execution off tee.

Putting

Distance Control (100): Pace and leave-distance control.

Direction Control (100): Start-line and make-rate accuracy.

Pitching

Distance Control (40): Partial wedge carry precision.

Direction Control (40): Lateral target accuracy.

Flight Control (20): Intentional trajectory variation.

Chipping

Distance Control (40): Landing spot and roll precision.

Direction Control (40): Start-line and lateral precision.

Flight Control (20): Intentional trajectory variation.

Woods

Distance Control (20): Controlled carry to defined distance.

Direction Control (20): Start-line control.

Shape Control (10): Intentional curvature execution.

Bunkers

Distance Control (15): Carry and depth control from sand.

Direction Control (15): Lateral accuracy from sand.

2.4 Subskill Allocation Mathematics

SubskillPoints = Allocation × (WeightedAverage / 5)

WeightedAverage = (TransitionAvg × 0.35) + (PressureAvg × 0.65)

No redistribution occurs between subskills.

2.5 Drill-to-Subskill Mapping Matrix

A drill must map to at least 1 and at most 2 subskills. Mapping is immutable. Changing mapping requires creating a new drill.

Shared Mode

One score. One anchor set (Min / Scratch / Pro). If 2 subskills → 0.5 occupancy each. Same score applied to both.

Multi-Output Mode

Independent score per subskill. Each subskill has its own independent anchor set (Min / Scratch / Pro). 0.5 occupancy each. Separate window storage.

Cross-Skill-Area mapping prohibited.

2.6 Window Definitions

Each subskill maintains two windows: Transition (25 occupancy units) and Pressure (25 occupancy units). Window size is fixed at 25 occupancy units per window. It is a system-level constant and is not user-configurable.

Technique Block drills do not enter windows. A Technique Block drill is a drill type focused purely on mechanical or technical rehearsal. It is exempt from the requirement to contribute to a subskill and does not map to any subskill. Technique Block drills produce no scored result and generate no occupancy units. Because they have no performance metric, they are excluded entirely from the 0–5 scoring system and do not influence subskill windows, skill areas, or the overall score. They are tracked only for frequency and session logging purposes.

2.7 Weight & Window Versioning

The following parameters are system-controlled and not user-editable:

• Skill Area allocations

• Subskill allocations

• 65/35 weighting

• Window size (fixed at 25)

User-editable structural parameters:

• Drill scoring anchors (User Custom Drills only)

Any change to a structural parameter triggers full historical recalculation and timeline annotation. There is only one canonical scoring model.

2.8 Structural Guarantees

The architecture guarantees:

• Deterministic additive structure

• No cross-area inflation

• No hidden smoothing

• No redistribution

• No time decay

• Full recalculability

End of Section 2 — Skill Architecture (2v.f1 Consolidated)

