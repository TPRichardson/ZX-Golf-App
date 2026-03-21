// Shared display ordering constants for skill areas and drill types.
// Extracted from active_drills_screen.dart and standard_drills_screen.dart.

import 'package:zx_golf_app/data/enums.dart';

/// Display order for skill areas in drill lists and carousels.
const kSkillAreaDisplayOrder = [
  SkillArea.driving,
  SkillArea.woods,
  SkillArea.approach,
  SkillArea.pitching,
  SkillArea.bunkers,
  SkillArea.chipping,
  SkillArea.putting,
];

/// Sort order for drill types within a skill area.
const kDrillTypeSortOrder = [
  DrillType.techniqueBlock,
  DrillType.transition,
  DrillType.pressure,
  DrillType.benchmark,
];
