import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// S15 §15.8 — Club card for bag list display.
// Shows club type, make/model, and status.

class ClubCard extends StatelessWidget {
  final UserClub club;
  final VoidCallback? onTap;

  const ClubCard({
    super.key,
    required this.club,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ZxCard(
      onTap: onTap,
      child: Row(
        children: [
          // Club type icon/indicator.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _categoryColor(club.clubType).withAlpha(30),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            ),
            alignment: Alignment.center,
            child: Text(
              _clubTypeShort(club.clubType),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _categoryColor(club.clubType),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.clubType.dbValue,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ColorTokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (club.make != null || club.model != null)
                  Text(
                    [club.make, club.model]
                        .where((s) => s != null)
                        .join(' '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorTokens.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          if (club.status == UserClubStatus.retired)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: ColorTokens.textTertiary.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Retired',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColorTokens.textTertiary,
                    ),
              ),
            ),
          const SizedBox(width: SpacingTokens.xs),
          Icon(
            Icons.chevron_right,
            color: ColorTokens.textTertiary,
          ),
        ],
      ),
    );
  }

  static String _clubTypeShort(ClubType type) {
    return switch (type) {
      ClubType.driver => 'D',
      ClubType.putter => 'P',
      ClubType.chipper => 'Ch',
      _ => type.dbValue,
    };
  }

  static Color _categoryColor(ClubType type) {
    if (type == ClubType.driver) return const Color(0xFF00B3C6);
    if (type == ClubType.putter) return const Color(0xFFF5A623);
    if (_isIron(type)) return const Color(0xFF1FA463);
    if (_isWedge(type)) return const Color(0xFF9B59B6);
    if (_isWood(type)) return const Color(0xFF3498DB);
    if (_isHybrid(type)) return const Color(0xFFE67E22);
    return ColorTokens.textSecondary;
  }

  static bool _isIron(ClubType type) {
    return const {
      ClubType.i1, ClubType.i2, ClubType.i3, ClubType.i4,
      ClubType.i5, ClubType.i6, ClubType.i7, ClubType.i8, ClubType.i9,
    }.contains(type);
  }

  static bool _isWedge(ClubType type) {
    return const {
      ClubType.pw, ClubType.aw, ClubType.gw,
      ClubType.sw, ClubType.uw, ClubType.lw,
    }.contains(type);
  }

  static bool _isWood(ClubType type) {
    return const {
      ClubType.w1, ClubType.w2, ClubType.w3, ClubType.w4,
      ClubType.w5, ClubType.w6, ClubType.w7, ClubType.w8, ClubType.w9,
    }.contains(type);
  }

  static bool _isHybrid(ClubType type) {
    return const {
      ClubType.h1, ClubType.h2, ClubType.h3, ClubType.h4,
      ClubType.h5, ClubType.h6, ClubType.h7, ClubType.h8, ClubType.h9,
    }.contains(type);
  }
}
