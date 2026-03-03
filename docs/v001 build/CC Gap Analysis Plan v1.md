# CC Gap Analysis Plan — S-Docs vs TD-Docs

## Objective

Systematically compare each specification document (S00–S17) against the full set of technical design documents (TD-01–TD-08) to produce a consolidated list of items that appear in the S-docs but are **not covered** in the TD-docs.

---

## Why Chunking Is Needed

| Doc Set | Count | Approx Total Size |
|---------|-------|--------------------|
| TD-01 to TD-08 | 8 | ~465 KB |
| S00 to S17 | 18 | ~435 KB |
| **Combined** | **26** | **~900 KB** |

Loading everything simultaneously would exceed practical context limits. The strategy below keeps each prompt focused and within budget.

---

## Phase 1 — Build the TD Reference Catalogue

**Goal:** Read all 8 TD-docs and produce a single structured index of every topic, requirement, entity, endpoint, rule, and decision they cover.

### Prompt for CC — Phase 1

```
Read the following 8 technical design documents one at a time and produce a single 
markdown file called "TD Reference Catalogue.md".

Files (in the project directory):
- TD-01v a4 Technology Stack Decisions.md
- TD-02v a6 Complete DDL Schema.md
- TD-03v a5 API Contract Layer.md
- TD-04v a4 Entity State Machines and Reflections.md
- TD-05v a3 Scoring Engine Test Cases.md
- TD-06v a6 Phased Build Plan.md
- TD-07v a4 Error Handling.md
- TD-08v a3 Claude Code Prompt Architecture.md

For each TD document, extract and list:
1. Every distinct topic, feature, or system area covered
2. Every entity, table, or data structure referenced
3. Every API endpoint or contract defined
4. Every rule, constraint, validation, or business logic described
5. Every decision, rationale, or trade-off recorded
6. Every external integration or dependency mentioned

Format as a flat bulleted list grouped under each TD document heading.
Keep entries concise (one line each) but specific enough to match against 
S-doc content later. Do not summarise — catalogue.

If any single TD file is too large to process in one read, split it into 
sections and process sequentially, appending to the catalogue as you go.

Save the output as: TD Reference Catalogue.md
```

### Chunking Notes for Phase 1

- TD-07 (82KB) and TD-03 (77KB) are the largest. CC may need to read these in sections.
- If context is tight, process TDs in two batches:
  - Batch A: TD-01, TD-02, TD-05, TD-08 (smaller files, ~172KB combined)
  - Batch B: TD-03, TD-04, TD-06, TD-07 (larger files, ~293KB combined)
- The output catalogue should be saved to disk so it can be loaded independently in Phase 2.

---

## Phase 2 — Compare Each S-Doc Against the Catalogue

**Goal:** For each S-doc, identify anything it contains that is **not accounted for** in the TD Reference Catalogue.

### Grouping Strategy

Process S-docs in batches of 2–3, grouped by related domain to help CC maintain context. Suggested groupings:

| Batch | S-Docs | Theme | Approx Size |
|-------|--------|-------|-------------|
| 2A | S00, S01, S02 | Terminology, Scoring Engine, Skill Architecture | ~22 KB |
| 2B | S03, S04, S05 | User Journey, Drill Entry, Review/SkillScore | ~29 KB |
| 2C | S06, S07, S08 | Data Model, Reflow Governance, Practice Planning | ~87 KB |
| 2D | S09, S10, S11 | Golf Bag/Clubs, Settings, Metrics Integrity | ~37 KB |
| 2E | S12, S13, S14 | UI/UX Architecture, Live Practice, Drill Entry Screens | ~74 KB |
| 2F | S15, S16, S17 | Branding/Design, Database Architecture, Application Layer | ~130 KB |

### Prompt Template for CC — Phase 2 (repeat per batch)

```
You have previously produced "TD Reference Catalogue.md". Load it now.

Then read the following S-docs:
- [list files for this batch]

For each S-doc, compare its content against the TD Reference Catalogue and 
identify anything that appears in the S-doc but is NOT covered anywhere in the 
TD catalogue. This includes:
- Features, rules, or behaviours specified but not designed
- Entities, fields, or relationships not reflected in the schema or state machines
- UI flows or screens not addressed in any TD
- Scoring logic, constraints, or edge cases not covered in test cases
- Configuration options or settings not represented
- Integration points or dependencies not mentioned
- Any other requirement, detail, or decision with no TD counterpart

Be thorough but avoid false positives. If the TD catalogue covers a topic 
at a general level and the S-doc simply elaborates, note it as 
"Partial — TD covers [x] but S-doc also specifies [y]" rather than a full gap.

Save the output as: Batch [X] Gaps.md

Format:
## [S-Doc Name]
- Gap description (brief, specific)
- Gap description
- ...
(If no gaps found, state "No unmatched items identified.")
```

### Chunking Notes for Phase 2

- Always load the TD Reference Catalogue first — it is the baseline for every batch.
- Batch 2F is the largest (~130KB). If CC struggles, split S16 (80KB) into its own pass.
- If the TD Reference Catalogue itself is very large, CC can load only the relevant TD sections per batch (e.g., for S01/S02 on scoring, focus on TD-05 and TD-04 catalogue entries). However, cross-cutting gaps are easier to catch with the full catalogue loaded.

---

## Phase 3 — Consolidate

**Goal:** Merge all batch outputs into a single gap analysis document.

### Prompt for CC — Phase 3

```
Read the following batch gap files:
- Batch 2A Gaps.md
- Batch 2B Gaps.md
- Batch 2C Gaps.md
- Batch 2D Gaps.md
- Batch 2E Gaps.md
- Batch 2F Gaps.md

Produce a single consolidated document called "S vs TD Gap Analysis.md" with:

1. A summary section listing the total number of gaps found per S-doc
2. The full gap list organised by S-doc (S00 through S17 in order)
3. A cross-reference section grouping gaps by theme (e.g., all scoring gaps 
   together, all UI gaps together, all data model gaps together) so patterns 
   are visible

Do not add or remove any gaps — this is a merge and reorganise task only.
```

---

## Execution Checklist

- [ ] Phase 1: Generate TD Reference Catalogue
- [ ] Phase 2A: S00, S01, S02
- [ ] Phase 2B: S03, S04, S05
- [ ] Phase 2C: S06, S07, S08
- [ ] Phase 2D: S09, S10, S11
- [ ] Phase 2E: S12, S13, S14
- [ ] Phase 2F: S15, S16, S17
- [ ] Phase 3: Consolidate into final gap analysis

---

## Notes

- If CC encounters a file too large to read in one pass, instruct it to process the file in halves or thirds and append findings.
- The TD Reference Catalogue is the critical artefact — if it misses something, gaps will be over-reported. Worth a quick manual sanity check before running Phase 2.
- All intermediate files should be saved to disk so work is not lost between prompts.
