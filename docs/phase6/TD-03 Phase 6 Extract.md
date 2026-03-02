# TD-03 API Contract Layer — Phase 6 Extract (TD-03v.a5)
Sections: §3.3.4 ScoringRepository (read methods)
============================================================

3.3.4 ScoringRepository

ScoringRepository implements the pure rebuild scoring engine defined in Section 1 and Section 7. It reads raw Instance data and writes to materialised tables. It is the sole writer to materialised tables.

  ---------------------- ------------------------------------------------------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method                 Signature                                                                                                    Description

  watchOverallScore      Stream<MaterialisedOverallScore?> watchOverallScore()                                                        Watches the user’s overall SkillScore. Primary data source for Dashboard.

  watchSkillAreaScores   Stream<List<MaterialisedSkillAreaScore>> watchSkillAreaScores()                                              Watches all 7 Skill Area scores.

  watchSubskillScores    Stream<List<MaterialisedSubskillScore>> watchSubskillScores({SkillArea? filter})                             Watches subskill scores, optionally filtered by Skill Area.

  watchWindowState       Stream<MaterialisedWindowState?> watchWindowState(String subskillId, DrillType practiceType)                 Watches a single window’s state (entries, occupancy, average).

  executeReflow          Future<void> executeReflow(ReflowTrigger trigger)                                                            Core reflow operation. Acquires UserScoringLock. Determines affected subskills from trigger. Rebuilds: Instance scores → Session scores → Window composition → Subskill scores → Skill Area scores → Overall score. Atomic write to materialised tables. Releases lock. Writes EventLog (ReflowComplete). See §4 for full reflow specification.

  executeFullRebuild     Future<void> executeFullRebuild()                                                                            Rebuilds all materialised state from scratch. Used after sync merge (TD-01 §2.5 Step 5) and on data recovery. Acquires RebuildGuard (§4.5) to prevent overlap with concurrent reflow. Truncates and repopulates all materialised tables atomically.

  acquireScoringLock     Future<bool> acquireScoringLock()                                                                            Sets UserScoringLock.IsLocked = true with expiry. Returns false if already locked. Used by reflow and by UI to block Instance logging during reflow.

  releaseScoringLock     Future<void> releaseScoringLock()                                                                            Clears the lock. Called after reflow completes or on timeout.

  isScoringLocked        Stream<bool> isScoringLocked()                                                                               Watches lock state. UI observes this to show blocking indicator during reflow.

  scoreInstance          double scoreInstance(Map<String, dynamic> rawMetrics, Map<String, dynamic> anchors, String metricSchemaId)   Pure function. Given raw metrics and anchors, returns 0–5 score using the scoring adapter bound to the MetricSchema. Two-segment linear interpolation: Min→Scratch (0–3.5), Scratch→Pro (3.5–5). Capped at 5. This is not a repository method but a pure scoring utility exposed alongside the repository.

  scoreSession           double scoreSession(List<double> instanceScores)                                                             Pure function. Simple average of all Instance 0–5 scores across all Sets.
  ---------------------- ------------------------------------------------------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

