# S16 Database Architecture — Phase 2B Extract
Sections: §16.1.6 Materialised Tables
============================================================

16.1.6 Materialised Tables

Materialised tables store derived scoring state computed during reflow. They are a replaceable cache, not a source of truth (Section 7, §7.11.1). They may be truncated and fully rebuilt from raw Instance data and the canonical scoring model at any time.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table                        Purpose                                                  Key Fields                                                                                                                                                                 Rebuild Source
  ---------------------------- -------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------
  MaterialisedWindowState      Current window contents per subskill per practice type   UserID, SkillArea, Subskill, PracticeType (Transition/Pressure), Entries (JSON: ordered list of SessionID, score, occupancy), TotalOccupancy, WeightedSum, WindowAverage   Instance data + Drill anchors + occupancy rules

  MaterialisedSubskillScore    Current subskill weighted averages and point values      UserID, SkillArea, Subskill, TransitionAverage, PressureAverage, WeightedAverage, SubskillPoints, Allocation                                                               MaterialisedWindowState + 65/35 weighting + allocation

  MaterialisedSkillAreaScore   Current skill area scores                                UserID, SkillArea, SkillAreaScore, Allocation                                                                                                                              Sum of child MaterialisedSubskillScore.SubskillPoints

  MaterialisedOverallScore     Current overall score                                    UserID, OverallScore                                                                                                                                                       Sum of all MaterialisedSkillAreaScore.SkillAreaScore
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

All materialised tables are keyed by UserID. During reflow, the affected rows are recomputed in isolation and swapped atomically (Section 7, §7.7). No partial materialised state is ever visible to the user.

16.1.7 System Tables

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table                   Purpose          Key Fields                                                                                                                                                                   Notes
  ----------------------- ---------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------
  EventLog                §6.2, §7.9       EventLogID (PK), UserID (FK), DeviceID (UUID, nullable, FK → UserDevice), EventTypeID (FK), Timestamp, AffectedEntityIDs (JSON), AffectedSubskills (JSON), Metadata (JSON)   Append-only. No updates or deletions. Cold storage archival policy applies (§16.7.4)

  UserDevice              §17.4.1, §17.9   DeviceID (PK, UUID), UserID (FK), DeviceLabel (string, nullable), RegisteredAt (UTC), LastSyncAt (UTC, nullable)                                                             Sync infrastructure. No scoring impact. Deregistration removes from sync roster only.

  UserScoringLock         §16.4.3          UserID (PK), IsLocked, LockedAt, LockExpiresAt                                                                                                                               Application-level scoring lock per user

  SystemMaintenanceLock   §16.4.4          LockID (PK), IsActive, ActivatedAt, Reason                                                                                                                                   System-wide maintenance flag. Single-row table
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

