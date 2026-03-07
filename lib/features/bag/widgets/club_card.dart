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
                borderRadius: BorderRadius.circular(ShapeTokens.radiusBadge),
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
    return ColorTokens.clubCategory(type);
  }
}
