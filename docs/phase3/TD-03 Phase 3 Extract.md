# TD-03 API Contract Layer — Phase 3 Extract (TD-03v.a5)
Sections: §3.3.2 DrillRepository, §3.3.5 ClubRepository
============================================================

## §3.3.2 DrillRepository

3.3.2 DrillRepository

  -------------------- ------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method               Signature                                                                       Description

  watchUserDrills      Stream<List<Drill>> watchUserDrills({SkillArea? filter, DrillStatus? status})   Watches all drills accessible to the user: System Drills (UserID = null) + user’s own custom drills. Excludes IsDeleted = true.

  watchAdoptedDrills   Stream<List<DrillWithAdoption>> watchAdoptedDrills({SkillArea? filter})         Watches drills the user has adopted (Practice Pool). Joins Drill with UserDrillAdoption.

  createCustomDrill    Future<Drill> createCustomDrill(DrillCompanion data)                            Creates a User Custom Drill. Validates: SubskillMapping references valid SubskillRef IDs for the selected SkillArea; MetricSchemaID references a valid schema; if Scored, ScoringMode is set; Anchors structure matches ScoringMode.

  updateDrill          Future<Drill> updateDrill(String drillId, DrillCompanion data)                  Updates a User Custom Drill. System Drills cannot be updated by user. Anchor edits on scored drills trigger reflow (delegated to ScoringRepository).

  retireDrill          Future<void> retireDrill(String drillId)                                        Sets Status = Retired. Drill remains in windows but is excluded from Practice Pool selection. Triggers reflow if sessions exist in windows. Writes EventLog entry.

  deleteDrill          Future<void> deleteDrill(String drillId)                                        Soft deletes drill. Cascades: UserDrillAdoption soft-deleted. Active PracticeEntry references removed. Completed Sessions in windows remain until rolled off. Triggers reflow. Writes EventLog entry.

  adoptDrill           Future<UserDrillAdoption> adoptDrill(String drillId)                            Creates UserDrillAdoption with Status = Active. Idempotent: re-adopting a Retired adoption reactivates it.

  retireAdoption       Future<void> retireAdoption(String drillId)                                     Sets UserDrillAdoption.Status = Retired. Drill removed from Practice Pool but remains in windows.

  getMetricSchema      Future<MetricSchema> getMetricSchema(String schemaId)                           Reads a MetricSchema definition. Used during Session execution to determine input mode and validation bounds.
  -------------------- ------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


## §3.3.5 ClubRepository

3.3.5 ClubRepository

  ------------------------ -------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------
  Method                   Signature                                                                                    Description

  watchUserBag             Stream<List<UserClub>> watchUserBag({UserClubStatus? status})                                Watches all clubs in the user’s bag. Default: Active clubs only.

  addClub                  Future<UserClub> addClub(UserClubCompanion data)                                             Adds a club to the bag. Validates ClubType is valid. Creates default UserSkillAreaClubMapping entries per Section 9 mandatory mapping rules.

  updateClub               Future<UserClub> updateClub(String clubId, UserClubCompanion data)                           Updates club details (Make, Model, Loft). Does not affect scoring.

  retireClub               Future<void> retireClub(String clubId)                                                       Sets Status = Retired. Club remains on historical Instances but excluded from future selection.

  addPerformanceProfile    Future<ClubPerformanceProfile> addPerformanceProfile(String clubId, ProfileCompanion data)   Insert-only. Creates a new time-versioned performance profile. The most recent profile (by EffectiveFromDate) is the active profile.

  getActiveProfile         Future<ClubPerformanceProfile?> getActiveProfile(String clubId)                              Returns the most recent profile for a club (highest EffectiveFromDate ≤ today).

  watchClubsForSkillArea   Stream<List<UserClub>> watchClubsForSkillArea(SkillArea skillArea)                           Watches clubs mapped to a Skill Area via UserSkillAreaClubMapping. Used by club selector during Session execution.

  updateSkillAreaMapping   Future<void> updateSkillAreaMapping(String clubType, SkillArea skillArea, bool mapped)       Creates or deletes a UserSkillAreaClubMapping entry. Mandatory mappings (Section 9) cannot be removed.
  ------------------------ -------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------

