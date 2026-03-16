import 'package:flutter/material.dart';
import 'package:zx_golf_app/data/enums.dart';

// S15 — Design token architecture. All values from canonical branding spec.
// Token names are product-name agnostic per S15 §15.14.

// S15 §15.3 — Colour tokens.
abstract final class ColorTokens {
  // Interaction layer (cyan accent — never used for scoring outcomes)
  static const primaryDefault = Color(0xFF00B3C6);
  static const primaryHover = Color(0xFF00C8DD);
  static const primaryActive = Color(0xFF007C7F);
  static Color primaryFocus = const Color(0xFF00B3C6).withValues(alpha: 0.6);

  // Success (scoring hit)
  static const successDefault = Color(0xFF1FA463);
  static const successHover = Color(0xFF23B26C);
  static const successActive = Color(0xFF15804A);

  // Miss (neutral cool grey — not red per S15 §15.3)
  static const missDefault = Color(0xFF3A3F46);
  static const missActive = Color(0xFF2C3036);
  static const missBorder = Color(0xFF4A5058);

  // Warning (integrity)
  static const warningIntegrity = Color(0xFFF5A623);
  static const warningMuted = Color(0xFFC88719);

  // Error (destructive)
  static const errorDestructive = Color(0xFFD64545);
  static const errorHover = Color(0xFFE05858);
  static const errorActive = Color(0xFFB63737);

  // Heatmap (grey-to-green continuous)
  static const heatmapBase = Color(0xFF2B2F34);
  static const heatmapMid = Color(0xFF145A3A);
  static const heatmapHigh = Color(0xFF1FA463);

  // Flight trajectory (wedge matrix visualisation)
  static const flightLow = Color(0xFF4A90D9);
  static const flightStandard = successDefault;
  static const flightHigh = warningIntegrity;

  // Surface (dark-first, tonal elevation only)
  static const surfaceBase = Color(0xFF0F1115);
  static const surfacePrimary = Color(0xFF171A1F);
  static const surfaceRaised = Color(0xFF1E232A);
  static const surfaceModal = Color(0xFF242A32);
  static const surfaceBorder = Color(0xFF2A2F36);
  static Color surfaceScrim = Colors.black.withValues(alpha: 0.4);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF); // 70% white
  static const textTertiary = Color(0x80FFFFFF); // 50% white

  // Skill area colours — warm-to-cool gradient (putter → driver).
  static const skillPutting = Color(0xFFD4A535);
  static const skillChipping = Color(0xFFE67E22);
  static const skillPitching = Color(0xFFE05858);
  static const skillBunkers = Color(0xFFC74882);
  static const skillApproach = Color(0xFF8E5BB5);
  static const skillWoods = Color(0xFF5B6ABF);
  static const skillDriving = Color(0xFF3A7BD5);

  // Club category colours — aligned with skill area gradient.
  static const clubPutter = skillPutting;
  static const clubWedge = skillPitching;
  static const clubIron = skillApproach;
  static const clubHybrid = skillChipping;
  static const clubWood = skillWoods;
  static const clubDriver = skillDriving;

  /// Resolve club type to its category colour token.
  static Color clubCategory(ClubType type) {
    if (type == ClubType.driver) {
      return clubDriver;
    }
    if (type == ClubType.putter || type == ClubType.chipper) {
      return clubPutter;
    }
    if (const {
      ClubType.pw, ClubType.aw, ClubType.gw,
      ClubType.sw, ClubType.uw, ClubType.lw,
    }.contains(type)) {
      return clubWedge;
    }
    if (const {
      ClubType.i1, ClubType.i2, ClubType.i3, ClubType.i4,
      ClubType.i5, ClubType.i6, ClubType.i7, ClubType.i8, ClubType.i9,
    }.contains(type)) {
      return clubIron;
    }
    if (const {
      ClubType.h1, ClubType.h2, ClubType.h3, ClubType.h4,
      ClubType.h5, ClubType.h6, ClubType.h7, ClubType.h8, ClubType.h9,
    }.contains(type)) {
      return clubHybrid;
    }
    if (const {
      ClubType.w1, ClubType.w2, ClubType.w3, ClubType.w4,
      ClubType.w5, ClubType.w6, ClubType.w7, ClubType.w8, ClubType.w9,
    }.contains(type)) {
      return clubWood;
    }
    return textSecondary;
  }

  // Achievement
  static const achievementGold = Color(0xFFFFD700);

  // RAG colour constants for scoring visualisation.
  static const ragRed = Color(0xFFE05252);
  static const ragAmber = Color(0xFFE8A830);
  static const ragGreen = Color(0xFF22C55E);
  static const ragPurple = Color(0xFF9333EA);

  /// RAG tile/pill colour: grey (0) → red→amber (≤0.6) → amber→green (>0.6).
  /// Used for heatmap tiles and subskill pills. Returns with 60% alpha.
  static Color ragTileColor(double normalisedScore) {
    if (normalisedScore <= 0) return surfaceRaised;
    if (normalisedScore <= 0.6) {
      return Color.lerp(
        ragRed,
        ragAmber,
        (normalisedScore / 0.6).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.6);
    }
    return Color.lerp(
      ragAmber,
      ragGreen,
      ((normalisedScore - 0.6) / 0.4).clamp(0.0, 1.0),
    )!.withValues(alpha: 0.6);
  }

  /// RAG bar colour: red→green linear interpolation by fill fraction.
  /// Used for SkillScore progress bars.
  static Color ragBarColor(double fill) {
    return Color.lerp(ragRed, ragGreen, fill.clamp(0.0, 1.0))!;
  }

  /// SkillScore ring colour: grey(0) → red→green (≤700) → green→purple (>700).
  /// Used for the overall score display ring.
  static Color ragScoreColor(double score) {
    if (score <= 0) return textTertiary;
    final f = (score / 1000).clamp(0.0, 1.0);
    if (f <= 0.7) {
      return Color.lerp(ragRed, ragGreen, f / 0.7)!;
    }
    return Color.lerp(ragGreen, ragPurple, (f - 0.7) / 0.3)!;
  }

  /// Resolve skill area to its colour token.
  static Color skillArea(SkillArea area) {
    return switch (area) {
      SkillArea.putting => skillPutting,
      SkillArea.chipping => skillChipping,
      SkillArea.pitching => skillPitching,
      SkillArea.bunkers => skillBunkers,
      SkillArea.approach => skillApproach,
      SkillArea.woods => skillWoods,
      SkillArea.driving => skillDriving,
    };
  }
}

// S15 §15.5 — Typography tokens.
abstract final class TypographyTokens {
  // Display XL: 32-40px, SemiBold
  static const displayXlSize = 36.0;
  static const displayXlHeight = 40.0 / 36.0;
  static const displayXlWeight = FontWeight.w600;

  // Display LG: 24-28px, SemiBold
  static const displayLgSize = 28.0;
  static const displayLgHeight = 28.0 / 24.0;
  static const displayLgWeight = FontWeight.w600;

  // Display MD: 24px, SemiBold
  static const displayMdSize = 24.0;

  // Header section: 20px, Medium
  static const headerSize = 20.0;
  static const headerHeight = 24.0 / 20.0;
  static const headerWeight = FontWeight.w500;

  // Body LG: 18px, Regular
  static const bodyLgSize = 18.0;
  static const bodyLgHeight = 24.0 / 18.0;
  static const bodyLgWeight = FontWeight.w400;

  // Body: 16px, Regular
  static const bodySize = 16.0;
  static const bodyHeight = 22.0 / 16.0;
  static const bodyWeight = FontWeight.w400;

  // Body SM: 14px, Regular @ 70-80% opacity
  static const bodySmSize = 14.0;
  static const bodySmHeight = 18.0 / 14.0;
  static const bodySmWeight = FontWeight.w400;

  // Display XXL: 64px, SemiBold — timer/score hero displays
  static const displayXxlSize = 64.0;
  static const displayXxlWeight = FontWeight.w600;
}

// S15 §15.6 — Spacing tokens (all multiples of 4).
abstract final class SpacingTokens {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// S15 §15.7 — Shape tokens.
abstract final class ShapeTokens {
  static const radiusMicro = 2.0;
  static const radiusBadge = 4.0;
  static const radiusGrid = 6.0;
  static const radiusCard = 8.0;
  static const radiusInput = 8.0;
  static const radiusSegmented = 8.0;
  static const radiusModal = 10.0;
}

// S15 §15.10 — Motion tokens.
abstract final class MotionTokens {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 150);
  static const slow = Duration(milliseconds: 200);
  static const curve = Curves.easeInOut;
}
