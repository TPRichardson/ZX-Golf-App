# TD-04 Entity State Machines — Phase 3 Extract (TD-04v.a4)
Sections: §2.4 Drill, §2.5 UserDrillAdoption, §2.10 UserClub
============================================================

## §2.4 Drill & §2.5 UserDrillAdoption

2.4 Drill

Drill state is tracked via the Status enum column (Active, Retired, Deleted). System Drills and User Custom Drills share the same state machine but differ in permitted operations.

2.4.1 State Transitions

  --------- ---------------- ----------------------------------- --------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------------------------------------------------
  From      To               Trigger                             Guard Conditions                                                                                                Side Effects                                                                                                                                                                                        Spec Reference

  (None)    Active           Drill creation (User Custom only)   Valid SubskillMapping, MetricSchemaID, Anchors (if scored). System Drills are seeded, not created at runtime.   Drill row created. UserDrillAdoption auto-created if adopted.                                                                                                                                       Section 3 §3.1.1; TD-03 §3.3.2 createCustomDrill

  Active    Retired          User retires drill                  User Custom: user-owned. System: via UserDrillAdoption retirement.                                              Status = Retired. Hidden from Practice Pool. Historical Sessions retained in windows. Roll-off continues naturally. Reflow triggered if sessions exist in windows. EventLog entry.                  Section 1 §1.17; TD-03 §3.3.2 retireDrill

  Retired   Active           Reactivation                        User Custom: user-owned. System: UserDrillAdoption re-adopted.                                                  Status = Active. Drill returns to Practice Pool. No reflow (windows unchanged).                                                                                                                     Section 1 §1.17

  Active    Deleted (soft)   User deletes drill                  User Custom only. System Drills cannot be deleted by users.                                                     IsDeleted=true. UserDrillAdoption soft-deleted. Active PracticeEntry references removed (PendingDrill entries). Completed Sessions remain until rolled off. Full reflow. EventLog: DrillDeletion.   Section 1 §1.17; Section 7 §7.2; TD-03 §3.3.2 deleteDrill

  Retired   Deleted (soft)   User deletes retired drill          User Custom only.                                                                                               Same as Active → Deleted.                                                                                                                                                                           Section 1 §1.17
  --------- ---------------- ----------------------------------- --------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------------------------------------------------

2.4.2 Drill Immutability Rules

The following fields are immutable post-creation for all drills (System and User Custom): Subskill mapping, Metric Schema, Drill Type, RequiredSetCount, RequiredAttemptsPerSet, Club Selection Mode, Target Definition. Changing any of these requires creation of a new Drill. Anchor edits are permitted for User Custom Drills and trigger reflow. System Drill anchors are changed centrally only.

2.5 UserDrillAdoption

UserDrillAdoption links a user to a System Drill. It governs whether the System Drill appears in the user's Practice Pool. Status is an enum: Active or Retired.

2.5.1 State Transitions

  --------- ----------- ------------------------------- ----------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------
  From      To          Trigger                         Guard Conditions                                                  Side Effects                                                                                                                Spec Reference

  (None)    Active      User adopts System Drill        Drill exists. No existing adoption (or re-adoption of Retired).   UserDrillAdoption created with Status=Active. Drill appears in Practice Pool.                                               TD-03 §3.3.2 adoptDrill

  Active    Retired     User unadopts (Keep)            None.                                                             Status = Retired. Drill hidden from Practice Pool. Historical Sessions retained. No reflow.                                 Section 6 §6.2; TD-03 §3.3.2 retireAdoption

  Active    (Deleted)   User unadopts (Remove/Delete)   None.                                                             UserDrillAdoption soft-deleted. Child Sessions of the Drill soft-deleted. Full reflow triggered. EventLog: DrillDeletion.   Section 6 §6.2

  Retired   Active      User re-adopts                  None.                                                             Status = Active. Drill returns to Practice Pool. Historical Sessions reconnected. No reflow.                                Section 6 §6.2; TD-03 §3.3.2 adoptDrill
  --------- ----------- ------------------------------- ----------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------


## §2.10 UserClub

2.10 UserClub

UserClub represents a club in the user's bag. Status governs Active/Retired lifecycle. Club changes have no direct scoring impact.

2.10.1 State Transitions

  --------- --------- ------------------- ------------------ --------------------------------------------------------------------------------------------------- ---------------------------------
  From      To        Trigger             Guard Conditions   Side Effects                                                                                        Spec Reference

  (None)    Active    User adds club      Valid ClubType.    UserClub created. Default UserSkillAreaClubMapping entries created per Section 9 mandatory rules.   Section 9; TD-03 §3.3.5 addClub

  Active    Retired   User retires club   None.              Status = Retired. Club remains on historical Instances. Excluded from future selection.             TD-03 §3.3.5 retireClub

  Retired   Active    User reactivates    None.              Status = Active. Returns to selection.                                                              Section 9
  --------- --------- ------------------- ------------------ --------------------------------------------------------------------------------------------------- ---------------------------------

