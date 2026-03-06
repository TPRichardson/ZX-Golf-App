# V2 Change Register

> **Purpose:** Structured record of all changes identified for V2. Each item captured during the workflow audit is logged here with enough detail to plan, prioritise, and implement.
>
> **How to use:**
> 1. Walk through the V2 Workflow Audit Checklist (A → M).
> 2. For every change needed, add an entry below under the relevant category.
> 3. Once the audit is complete, use the Priority Matrix and Phase Assignment sections at the bottom to organise implementation.

---

## Entry Format

Copy this block for each new item:

```
### [ID] — [Short Title]

**Workflow ref:** [Checklist ref, e.g. D3, F7, J5]
**Type:** Bug / Enhancement / New Feature / Spec Gap / Tech Debt / UX Polish
**Priority:** P0 (Blocker) / P1 (Must-have) / P2 (Should-have) / P3 (Nice-to-have)
**Effort:** XS (<1h) / S (1–4h) / M (4h–1d) / L (1–3d) / XL (3d+)

**Current behaviour:**
[What happens now]

**Desired behaviour:**
[What should happen in V2]

**Affected files:**
- [file paths, if known]

**Dependencies:**
- [Other item IDs this depends on, or "None"]

**Acceptance criteria:**
- [ ] [Testable statement 1]
- [ ] [Testable statement 2]

**Notes:**
[Any additional context, spec references, design decisions, or open questions]

---
```

---

## A — First Launch & Onboarding

_Items from audit section A go here._

---

## B — Home Dashboard

_Items from audit section B go here._

---

## C — Golf Bag & Club Management

_Items from audit section C go here._

---

## D — Drill Lifecycle

_Items from audit section D go here._

---

## E — Practice Planning

_Items from audit section E go here._

---

## F — Live Practice

_Items from audit section F go here._

---

## G — Drill Execution

_Items from audit section G go here._

---

## H — Session Close & Post-Session

_Items from audit section H go here._

---

## I — Scoring & Reflow

_Items from audit section I go here._

---

## J — Review & Analysis

_Items from audit section J go here._

---

## K — Settings & Configuration

_Items from audit section K go here._

---

## L — Sync & Offline

_Items from audit section L go here._

---

## M — Cross-Cutting Concerns

_Items from audit section M go here._

---

## Planning Tools

### Priority Matrix

Once all items are logged, tally them here:

| Priority | Count | Description |
|----------|-------|-------------|
| P0 | | Blockers — must fix before any V2 release |
| P1 | | Must-have — core V2 scope |
| P2 | | Should-have — include if time permits |
| P3 | | Nice-to-have — defer if needed |

### Effort Distribution

| Effort | Count | Estimated Total |
|--------|-------|-----------------|
| XS (<1h) | | |
| S (1–4h) | | |
| M (4h–1d) | | |
| L (1–3d) | | |
| XL (3d+) | | |

### Phase Assignment

Group items into implementation phases. Each phase should be independently shippable and testable.

| Phase | Items | Theme | Est. Duration |
|-------|-------|-------|---------------|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| ... | | | |

### Dependency Graph

List any chains where one item must be completed before another:

```
[Item ID] → [Item ID] → [Item ID]
```

---

## Deferred from V1

The following items were explicitly deferred during V1 gap remediation. Review each during the V2 audit and either promote to a V2 item or re-defer with updated rationale.

| Item | V1 Reason | V2 Decision |
|------|-----------|-------------|
| System-initiated parallel reflow (S07 Gap 44) | Server-side orchestration | |
| Global scoring lock trigger (S07 Gap 43) | Requires server-side reflow | |
| Calendar drag-and-drop (S12 §12.4) | Major UX overhaul | |
| Calendar Bottom Drawer (S12 §12.4) | Coupled with drag-and-drop | |
| Diagnostic visualisations — grid, 3×3, histograms, hit/miss ratio (S05 Gaps 23–26) | Analysis nice-to-haves | |
| Comparative Analytics (S12 §12.6) | Significant new analysis feature | |
| Create Drill from Session (S13 §13.4.1) | Quality-of-life | |
| Crash recovery UX (S13 §13.14) | Edge case | |
| Per-drill unit override (S10 §10.6) | Architectural decision needed | |
| Sync-triggered rebuild priority model (S17 §17.4) | Requires priority queue architecture | |
| 80% Screen Takeover pattern (S14 §14.10.7) | Visual design pattern | |
| Submit + Save dual-action buttons (S14 §14.9) | Current pattern functional | |

---

*End of Change Register Template*
