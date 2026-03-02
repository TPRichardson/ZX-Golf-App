# TD-07 Error Handling — Phase 3 Extract (TD-07v.a4)
Sections: §4 Validation Errors
============================================================

4. Validation Errors

Validation errors are the most common error category. They are caused by user input that violates domain rules. They are always preventable by the UI layer (i.e. the UI should make it difficult or impossible to submit invalid input), but the Repository layer enforces validation as a safety net.

4.1 Inline Field Validation

Validation rules are evaluated at two points: eagerly in the UI (on field change or form submission) and defensively in the Repository (on write). The UI validation is the primary enforcement mechanism. The Repository validation is the safety net that guarantees invalid data never reaches the database.

Anchor validation (TD-05 §13): Min < Scratch < Pro (strictly increasing). Evaluated on each field change. If violated, the Save button is disabled and an inline message states the constraint (e.g. “Min must be less than Scratch”). The Repository throws VALIDATION_INVALID_ANCHORS if the UI check is bypassed.

Structural identity (TD-04 §2.4.2): Subskill mapping, Metric Schema, Drill Type, RequiredSetCount, RequiredAttemptsPerSet, Club Selection Mode, and Target Definition are immutable post-creation. The UI hides edit affordances for these fields on existing drills. The Repository throws VALIDATION_INVALID_STRUCTURE if an edit attempts to change an immutable field.

Required fields: The Repository validates that all non-nullable columns have values before insert. Missing required fields throw VALIDATION_REQUIRED_FIELD with context identifying the missing field name.

4.2 State Transition Guard Rejection

Every state machine transition defined in TD-04 has a guard condition. If the guard fails, the Repository throws VALIDATION_STATE_TRANSITION with context containing: the entity type, the current state, the attempted target state, and the guard that failed.

The UI layer prevents most invalid transitions by hiding or disabling action affordances that are not available in the current state (e.g. the End Drill button is not shown for a Session that is not Active). The guard rejection at the Repository layer is a safety net for race conditions where the entity state changed between UI render and user tap.

User message: “This action is no longer available. The screen will refresh.” The UI re-reads the entity state and re-renders. No retry is needed; the UI update resolves the stale state.

4.3 Active Session Conflict

The single-active-Session rule (TD-04 §2.2) prohibits starting a new Session while another Session is Active on the same device. If the user attempts to start a Session and an Active Session exists, the Repository throws VALIDATION_SINGLE_ACTIVE_SESSION.

User message: “You have an active session in progress. End or discard it before starting a new one.” The UI navigates to the active Session or offers a discard action.

Cross-device active Session conflict is a sync concern, handled in §8.1.

