Section 15 — Branding & Design System

Version 15v.a3 — Consolidated

This document defines the canonical Branding & Design System at implementation depth. It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 4 (Drill Entry System 4v.g8), Section 5 (Review 5v.d6), Section 7 (Reflow Governance System 7v.b9), Section 10 (Settings & Configuration 10v.a5), Section 11 (Metrics Integrity & Safeguards 11v.a5), Section 12 (UI/UX Structural Architecture 12v.a5), Section 13 (Live Practice Workflow 13v.a6), Section 14 (Drill Entry Screens & System Drill Library 14v.a4), and the Canonical Definitions (0v.f1). All identifiers remain product-name agnostic.

15.1 Strategic Positioning

Audience

Serious amateur performance improvers. Users who care about improving, track data deliberately, are not tour professionals, and do not want cartoon celebration effects.

Tonal Direction

Performance-focused and sharp. Crisp, structured, analytical. The product feels like training software, not a lifestyle app or consumer golf companion.

Design Intent

Reinforce the determinism of the scoring engine and structural clarity of the data model. Every visual decision should communicate precision, control, and transparency.

Positioning Characteristics

  -----------------------------------------------------------------------
  Characteristic                                Status
  --------------------------------------------- -------------------------
  Aspirational but not intimidating             Yes

  Performance-focused but not clinical          Yes

  Motivating without being gamified             Yes

  Clean, structured, credible                   Yes

  Slight warmth allowed but not playful         Yes
  -----------------------------------------------------------------------

Explicit Exclusions

Gamification, celebratory theatrics, lifestyle branding, consumer-friendly golf companion positioning, cartoon celebration effects, sports-brand energy. The system must never feel like an elite analytics lab either — it is approachable but serious.

15.2 Tone & Voice Guidelines

Copy Tone

All user-facing text is concise, direct, and informational. No exclamation marks in system messages. No motivational language in scoring or engine-state displays. Achievement text is factual, not celebratory.

Instructional Text

Prompts and instructions use clear imperative language. No hedging. No conversational tone in system-critical UI.

Error & Warning Messages

Errors are factual and actionable. Integrity warnings (Section 11) use observational language only. No blame, no alarm, no emotional framing. Example: “Value outside expected range” not “Warning! Suspicious entry detected!”

Score Communication

Scores are presented neutrally. No emotional framing of drops. No “well done” on increases. The system reports; the user interprets.

15.3 Colour Architecture

The colour system is divided into three architecturally separate layers: Interaction, Semantic, and Heatmap. Interaction tokens must never be used for scoring outcomes. Semantic tokens must never be used for interaction emphasis.

15.3.1 Interaction Tokens

Used for: CTA buttons, selected filters, toggle states, graph active lines, calendar selection highlights, segmented control active state, club selector active state. Never used for scoring outcomes.

  ------------------------------------------------------------------------------------
  Token                    Value           Notes / Usage
  ------------------------ --------------- -------------------------------------------
  color.primary.default    #00B3C6         Primary accent — all interactive elements

  color.primary.hover      #00C8DD         Hover / lighter state

  color.primary.active     #007C7F         Active / pressed state (teal-weighted)

  color.primary.focus      #00B3C6 @ 60%   Focus ring: 2px outline at 60% opacity
  ------------------------------------------------------------------------------------

15.3.2 Semantic Performance Tokens

Performance outcome colours are structurally separate from interaction colours. They encode scoring results, integrity states, and destructive actions.

Hit / Success (Grid centre, Binary Hit)

  ------------------------------------------------------------------------------
  Token                    Value           Notes / Usage
  ------------------------ --------------- -------------------------------------
  color.success.default    #1FA463         Hit state — grid centre, hit button

  color.success.hover      #23B26C         Hover state on hit elements

  color.success.active     #15804A         Pressed state on hit elements
  ------------------------------------------------------------------------------

Miss / Failure (Grid outer cells)

Miss uses neutral cool grey. Failure is informational, not punitive. No red for miss.

  ----------------------------------------------------------------------------
  Token                       Value           Notes / Usage
  --------------------------- --------------- --------------------------------
  color.neutral.miss          #3A3F46         Default miss state

  color.neutral.miss.active   #2C3036         Pressed miss state

  color.neutral.miss.border   #4A5058         Subtle border on miss surfaces
  ----------------------------------------------------------------------------

Warning / Integrity (Section 11)

Integrity indicators are observational only. Must remain visually distinct from hit, miss, interaction, and error colours.

  ----------------------------------------------------------------------------------------
  Token                           Value           Notes / Usage
  ------------------------------- --------------- ----------------------------------------
  color.warning.integrity         #F5A623         Default integrity warning amber

  color.warning.integrity.muted   #C88719         Muted variant for secondary indicators
  ----------------------------------------------------------------------------------------

Error / Destructive Actions

Used only for: drill deletion, session deletion, hard destructive actions (Section 7 deletion triggers). Never used in scoring UI.

  --------------------------------------------------------------------------------
  Token                            Value           Notes / Usage
  -------------------------------- --------------- -------------------------------
  color.error.destructive          #D64545         Default destructive action

  color.error.destructive.hover    #E05858         Hover state

  color.error.destructive.active   #B63737         Pressed state
  --------------------------------------------------------------------------------

15.3.3 Heatmap Colour Model

Model: Grey → Green. Neutral base with proportional green overlay. No red divergence permitted. Continuous opacity scaling mapped to the 0–5 score range. No hard-banded tiers.

  ------------------------------------------------------------------------------
  Token                    Value           Notes / Usage
  ------------------------ --------------- -------------------------------------
  heatmap.base             #2B2F34         Score ≈ 0–1 — neutral, not alarming

  heatmap.base.border      #3A3F46         Tile border at base level

  heatmap.base.text        #E6E8EB         Soft white text on base tiles

  heatmap.mid              #145A3A         Score ≈ 2–3 — muted green wash

  heatmap.high             #1FA463         Score ≈ 4–5 — full semantic green
  ------------------------------------------------------------------------------

Opacity of green overlay increases continuously with score. No discrete 5-step bands. Feels analytical, not badge-tiered.

15.4 Surface & Elevation System

Dark-first interface. Elevation is achieved through tonal contrast only. No long drop shadows, no heavy glow, no neumorphism, no blur-based glass effects.

  -------------------------------------------------------------------------------------------------------------------------------------
  Token                    Value           Notes / Usage
  ------------------------ --------------- --------------------------------------------------------------------------------------------
  surface.base             #0F1115         Level 0 — App shell, behind nav, Live Practice background

  surface.primary          #171A1F         Level 1 — Cards, calendar days, drill list rows, heatmap tile base, queue entries

  surface.raised           #1E232A         Level 2 — Bottom drawer, secondary overlays, bulk entry, expanded club selector, dropdowns

  surface.modal            #242A32         Level 3 — Confirmation dialogs, destructive confirmation (Section 10)

  surface.border           #2A2F36         Optional 1px border on raised surfaces
  -------------------------------------------------------------------------------------------------------------------------------------

Modal Backdrop

  -------------------------------------------------------------------------------
  Token                    Value                 Notes / Usage
  ------------------------ --------------------- --------------------------------
  surface.scrim            Black @ 40% opacity   Backdrop behind modal surfaces

  -------------------------------------------------------------------------------

No blur effects on scrim. Clean darkening only.

On-Press Surface Behaviour

On press: surface darkens by approximately 4%. No scale animation. No bounce. Feels controlled and mechanical.

Elevation Exclusion List

The following are explicitly prohibited: long drop shadows, heavy glow effects, floating neumorphism, blur-based glass/frosted effects, gradient surfaces.

15.5 Typography System

Typeface Category

Technical Geometric Sans. Characteristics: slightly squared curves, open apertures, high legibility numerals, tabular number support (critical), medium contrast between weights. Reference families for evaluation: Manrope, IBM Plex Sans, Satoshi, Space Grotesk.

Text Hierarchy

  ----------------------------------------------------------------------------------------------------------
  Token                    Value                    Notes / Usage
  ------------------------ ------------------------ --------------------------------------------------------
  type.display.xl          32–40px, SemiBold        Overall Score (0–1000) — authoritative, not decorative

  type.display.lg          24–28px, SemiBold        Session Score (0–5)

  type.header.section      18–22px, Medium          Skill Area / Drill Name headers

  type.body                14–16px, Regular         Body text, metadata — off-white, not pure white

  type.micro               12px, Regular @ 70–80%   Set 1/3 – Attempt 4/10, timestamps, secondary labels
  ----------------------------------------------------------------------------------------------------------

Numeric Governance

All score displays use tabular lining numerals. No animated counting. No decorative numerals. Numerals must have consistent baseline width and avoid rounded “friendly” zero.

Typography Exclusion List

The following are explicitly prohibited: condensed athletic headers, italics used for energy or emphasis, decorative or display numerals, overly wide letter-spacing, scripted or lifestyle-feeling typefaces, uppercase sports-style wide caps, small caps for micro-labels (too stylised).

15.6 Spacing & Layout Grid

4px base grid. All spacing values are multiples of 4. No arbitrary spacing values (e.g. 13px, 22px) are permitted anywhere in the system.

  ------------------------------------------------------------------------------------------------
  Token                    Value           Notes / Usage
  ------------------------ --------------- -------------------------------------------------------
  spacing.8                8px             Micro: icon-to-label, inside compact components

  spacing.16               16px            Standard: card padding, between list rows

  spacing.24               24px            Section separation between major sections

  spacing.32               32px            Major block separation (e.g. Dashboard sections)

  spacing.48               48px            Visual reset — used only for intentional large breaks
  ------------------------------------------------------------------------------------------------

Application

This spacing system applies uniformly across Drill Entry Screens (Section 14), Review Dashboard (Section 5), Calendar surfaces (Section 8), Live Practice queue (Section 13), and all other UI surfaces.

15.7 Shape Language

  --------------------------------------------------------------------------------------------------------------------------------------------
  Token                    Value           Notes / Usage
  ------------------------ --------------- ---------------------------------------------------------------------------------------------------
  radius.card              8px             Cards, buttons, calendar tiles, heatmap tiles, drawer surfaces, input fields, achievement banners

  radius.grid              6px             Grid cells (1×3, 3×1, future 3×3) — tighter feel, reads as target matrix

  radius.modal             10px            Modals, confirmation dialogs — slightly larger for layering hierarchy
  --------------------------------------------------------------------------------------------------------------------------------------------

Segmented Controls

8px container radius. Internal selection highlight uses the same 8px radius. No pill-shaped 999px radius buttons. This rule is absolute.

Shape Exclusions

Fully rounded pill shapes are prohibited anywhere in the system. All interactive elements use the radius values defined above.

15.8 Component Design System

15.8.1 Buttons

Primary CTA

Filled button using color.primary.default background with high-contrast white text. Hover: color.primary.hover. Active: color.primary.active. Used for: Start Drill, End Practice, Save, Confirm.

Secondary

Outline button using 1px color.primary.default border with color.primary.default text. No fill. Used for: Cancel, Back, alternative actions.

Destructive

Filled button using color.error.destructive background with white text. Used only for irreversible deletion confirmations.

Text Button

No border, no fill. Colour inherits from context. Used for tertiary actions.

15.8.2 Cards

Background: surface.primary. Border: optional 1px surface.border. Corner radius: radius.card (8px). Internal padding: spacing.16. On press: surface darkens ~4%, no scale, no bounce.

15.8.3 Grid Cells (Drill Entry)

Corner radius: radius.grid (6px). Hit cell: color.success.default. Miss cell: color.neutral.miss. Tap feedback: brief colour flash (120ms), single haptic tick. No animation beyond 120ms colour fade. Target dimensions resolved per Instance and displayed before tap.

15.8.4 Achievement Banners

Background: surface.raised. Accent: color.primary.default (restrained, not dominant). Text: factual, not celebratory. Corner radius: radius.card (8px). Entry: fade in 150ms. Exit: fade out 200ms. No slide, no bounce, no scale, no glow pulses, no confetti, no streak fire. Subtle sound ping. Feels informational, not rewarding.

15.8.5 Integrity Indicators

Subtle warning icon at Session level using color.warning.integrity. Appears in Session summary (drill history) only. Does not appear in SkillScore views, score displays, Analysis trend charts, or Window Detail View entries. Carries no scoring connotation — data-quality signal only.

15.9 Iconography

Style

Outlined, geometric, consistent stroke weight. Icons must match the Technical Geometric typeface tone — structured, not decorative or illustrative.

Stroke Weight

1.5–2px consistent stroke. No filled icons in navigation. Filled variants permitted only for active/selected states.

Size Grid

Icons follow the 4px base grid: 16px (micro), 20px (inline), 24px (standard navigation/action), 32px (prominent feature).

Colour

Default: off-white on dark surfaces. Active/selected: color.primary.default. Integrity: color.warning.integrity. Destructive: color.error.destructive.

Exclusions

No illustrative or pictorial icons. No golf-themed decorative icons (flags, balls, clubs as decoration). Icons are functional indicators only.

15.10 Motion & Microinteraction System

Motion philosophy: minimalist with rare micro-feedback only. Everything feels controlled, deliberate, and instant. The system is nearly static.

15.10.1 Timing Tokens

  --------------------------------------------------------------------------------------------------------
  Token                    Value           Notes / Usage
  ------------------------ --------------- ---------------------------------------------------------------
  motion.fast              120ms           Micro state changes — button press, grid tap colour flash

  motion.standard          150ms           Standard transitions — fade in, accordion expand

  motion.slow              200ms           Maximum permitted duration — achievement banner fade out only
  --------------------------------------------------------------------------------------------------------

Easing: ease-in-out cubic only. No transitions exceed 200ms anywhere in the system.

15.10.2 Permitted Motion

  -----------------------------------------------------------------------------------------------------------
  Interaction                Behaviour
  -------------------------- --------------------------------------------------------------------------------
  Button press               Slight darken + elevation drop. 120ms. No scaling.

  Grid tap (Drill Entry)     Brief colour flash 120ms. Single haptic tick. No animation beyond colour fade.

  Achievement banner         Fade in 150ms. Fade out 200ms. No slide, no bounce. Subtle sound ping.

  Heatmap accordion expand   Height transition 150ms. No overshoot. No bounce. Structural, not playful.

  Surface press              Darken ~4%. No scale. No bounce.
  -----------------------------------------------------------------------------------------------------------

15.10.3 Haptics & Audio

Default mode: silent. Haptic tick on grid cell tap. Subtle sound ping on achievement banners only. No other audio or haptic feedback in the system.

15.10.4 Motion Prohibition List

The following are explicitly prohibited across the entire system:

  -----------------------------------------------------------------------
  Effect                                Status
  ------------------------------------- ---------------------------------
  Bounce / spring physics               Prohibited

  Elastic overscroll theatrics          Prohibited

  Confetti                              Prohibited

  Score pop animations                  Prohibited

  Animated counters / counting up       Prohibited

  Pulsing CTA buttons                   Prohibited

  “Level up” effects                    Prohibited

  Sliding celebration panels            Prohibited

  Streak fire effects                   Prohibited

  Glow pulses                           Prohibited

  Celebratory scale pulses              Prohibited

  Sliding tab theatrics                 Prohibited
  -----------------------------------------------------------------------

15.11 Plan / Track / Review Visual Governance

Rule: Full Visual Unification

Plan, Track, and Review are structurally distinct domains (Section 12) but must feel like one continuous analytical environment. There are no domain colour shifts, no per-domain tints, no accent shifts per domain.

What Is Identical Across All Domains

Same charcoal base everywhere. Same cyan interaction accent. Same semantic green for performance. Same grey neutral for miss. Same amber for integrity. Same red for destructive. Same surface hierarchy. Same typography. Same spacing grid.

Differentiation Mechanism: Structural Only

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Mechanism              Implementation
  ---------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------
  Information Density    Plan: more spacing, calendar geometry, slot blocks. Track: library grouping, collapsible Skill Areas. Review: heatmap grid, charts, numeric dominance.

  Interaction Patterns   Plan: drag-and-drop emphasis. Track: expand/collapse library. Review: tap-to-expand heatmap, filter-driven charts.

  Emphasis Hierarchy     Home: action emphasis. Live Practice: execution emphasis. Review: numeric + analytic emphasis.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Visual language remains constant — layout does the work. This avoids “section personality drift” and reinforces the system as one coherent performance tool.

15.12 Logo & Brand Expression

Expression Level

Minimal typographic wordmark only. No symbol, no golf-referential mark (flag, ball, target), no emblem, no crest, no shield, no badge.

Rationale

Keeps the system analytical and software-grade. Avoids anchoring the product to golf-specific aesthetic. Preserves expansion optionality. Consistent with performance-focused, not sports-branded, positioning.

Product Title Governance

The current product title is a working title and is not final. The title must not appear in:

  -----------------------------------------------------------------------
  Location                              Status
  ------------------------------------- ---------------------------------
  Core file names                       Prohibited

  Environment variables                 Prohibited

  Database schemas                      Prohibited

  Namespaces                            Prohibited

  Token systems                         Prohibited

  Constants                             Prohibited

  Design system identifiers             Prohibited
  -----------------------------------------------------------------------

Use neutral system identifiers only: app, core, practice_engine, scoring_engine, ui_system, design_tokens, practice_block, skill_area, etc. This ensures a future rebrand requires only a wordmark swap with no refactor, no migration, no schema rewrite, no token rename cascade, and no analytics rename.

15.13 Accessibility Standards

Global Minimum: WCAG AA

All body text, interactive text, numeric score displays, filter labels, drill metadata, and calendar labels meet WCAG AA minimum contrast: 4.5:1 for normal text, 3:1 for large text.

Selective AAA Surfaces

WCAG AAA (7:1 contrast) is required on the following cognitively critical surfaces:

  --------------------------------------------------------------------------------
  Surface                                             Standard
  --------------------------------------------------- ----------------------------
  Overall Score display (0–1000)                      AAA required

  Session 0–5 score                                   AAA required

  Integrity warning text (Section 11)                 AAA required

  Destructive confirmation dialog text (Section 10)   AAA required
  --------------------------------------------------------------------------------

Heatmap Accessibility

Full AAA is not required for heatmap tiles. AA is sufficient for non-primary numeric overlays. Full AAA would force near-white text on mid-greens, reduce continuous opacity scaling nuance, and flatten the analytical subtlety of the Review surface.

Outdoor Usage Consideration

Drill Entry Screens will be used outdoors in sunlight. Large numeric values (score, attempt count) must be very high contrast. Small micro-labels meet AA without requiring AAA.

15.14 Token & Naming Governance

All tokens must be semantic and product-name agnostic. Token names describe function, not brand.

Valid Token Examples

  -----------------------------------------------------------------------
  Token                          Purpose
  ------------------------------ ----------------------------------------
  color.primary                  Interaction accent colour

  color.success                  Hit / positive outcome

  color.warning.integrity        Integrity flag indicator

  surface.base                   App shell background

  spacing.16                     Standard internal padding

  radius.card                    Card corner radius

  motion.fast                    Micro state change duration

  heatmap.mid                    Mid-range heatmap tile
  -----------------------------------------------------------------------

Prohibited Token Names

Any brand, product name, or working-title identifier is prohibited in token names. Examples of prohibited patterns: zx_primary, caddie_green, brand_teal, or any product-name-derived string.

15.15 Theming & Future Scalability

The design system is built token-first. Theme overrides must modify tokens only, not component logic. This architecture supports:

  -------------------------------------------------------------------------------------------------------------------
  Capability                  Implementation
  --------------------------- ---------------------------------------------------------------------------------------
  Light mode                  Optional in future. Achieved via token swap only. Dark remains default.

  White-label branding        Supported. Coach or third-party branding via token override.

  Platform adaptation         Token values can adjust for platform-specific requirements without component changes.
  -------------------------------------------------------------------------------------------------------------------

15.16 Structural Guarantees

The Branding & Design System guarantees:

• Product-name agnostic — all identifiers remain neutral; rebrand requires wordmark swap only

• Interaction/semantic colour separation — accent colour never used for scoring outcomes

• Non-punitive visual language — no red for miss, no emotional framing of drops

• Deterministic visual consistency — same colour language across Plan, Track, and Review

• No gamification — motion, colour, and copy explicitly prohibit celebratory or game-like patterns

• WCAG AA global minimum — selective AAA on cognitively critical surfaces

• Token-first architecture — theme overrides modify tokens only, not component logic

• 4px spacing integrity — no arbitrary spacing values anywhere in the system

• Continuous heatmap scaling — no hard-banded tiers, grey-to-green only

• Architectural isolation — visual system does not influence scoring engine, window mechanics, or reflow governance

End of Section 15 — Branding & Design System (15v.a3 Consolidated)

