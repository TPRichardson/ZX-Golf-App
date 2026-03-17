import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/data/enums.dart';

// Club tier classification for target width percentage lookup.
// Short irons have tighter targets, long irons/hybrids have wider.

/// Returns the target width as a percentage of carry distance for a given club.
/// Only meaningful for iron and hybrid club types.
double targetWidthPercentForClub(ClubType club) {
  switch (club) {
    // Short irons (5%)
    case ClubType.pw:
    case ClubType.i9:
    case ClubType.i8:
      return kShortIronTargetWidthPercent;

    // Mid irons (7%)
    case ClubType.i7:
    case ClubType.i6:
    case ClubType.i5:
      return kMidIronTargetWidthPercent;

    // Long irons + equivalent hybrids (9%)
    case ClubType.i4:
    case ClubType.i3:
    case ClubType.i2:
    case ClubType.i1:
    case ClubType.h1:
    case ClubType.h2:
    case ClubType.h3:
    case ClubType.h4:
      return kLongIronTargetWidthPercent;

    // Mid hybrids — match mid irons (7%)
    case ClubType.h5:
    case ClubType.h6:
    case ClubType.h7:
      return kMidIronTargetWidthPercent;

    // Short hybrids — match short irons (5%)
    case ClubType.h8:
    case ClubType.h9:
      return kShortIronTargetWidthPercent;

    // Wedges (5% — same as short irons)
    case ClubType.aw:
    case ClubType.gw:
    case ClubType.sw:
    case ClubType.uw:
    case ClubType.lw:
      return kShortIronTargetWidthPercent;

    // Woods, driver, chipper, putter — not typically used with this system.
    // Default to mid if somehow selected.
    case ClubType.driver:
    case ClubType.w1:
    case ClubType.w2:
    case ClubType.w3:
    case ClubType.w4:
    case ClubType.w5:
    case ClubType.w6:
    case ClubType.w7:
    case ClubType.w8:
    case ClubType.w9:
    case ClubType.chipper:
    case ClubType.putter:
    case ClubType.trainingClub:
      return kMidIronTargetWidthPercent;
  }
}

/// Returns the target depth as a percentage of target distance for a given club.
/// Used for distance-based drills (3x1 grid) with variable targets.
double targetDepthPercentForClub(ClubType club) {
  switch (club) {
    case ClubType.pw:
    case ClubType.i9:
    case ClubType.i8:
    case ClubType.aw:
    case ClubType.gw:
    case ClubType.sw:
    case ClubType.uw:
    case ClubType.lw:
    case ClubType.h8:
    case ClubType.h9:
      return kShortIronTargetDepthPercent;

    case ClubType.i7:
    case ClubType.i6:
    case ClubType.i5:
    case ClubType.h5:
    case ClubType.h6:
    case ClubType.h7:
      return kMidIronTargetDepthPercent;

    case ClubType.i4:
    case ClubType.i3:
    case ClubType.i2:
    case ClubType.i1:
    case ClubType.h1:
    case ClubType.h2:
    case ClubType.h3:
    case ClubType.h4:
      return kLongIronTargetDepthPercent;

    case ClubType.driver:
    case ClubType.w1:
    case ClubType.w2:
    case ClubType.w3:
    case ClubType.w4:
    case ClubType.w5:
    case ClubType.w6:
    case ClubType.w7:
    case ClubType.w8:
    case ClubType.w9:
    case ClubType.chipper:
    case ClubType.putter:
    case ClubType.trainingClub:
      return kMidIronTargetDepthPercent;
  }
}
