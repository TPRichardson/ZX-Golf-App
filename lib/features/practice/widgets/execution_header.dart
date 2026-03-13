// Phase 4 — Execution Header widget.
// S13 §13.6 — Drill name with set progress in top right.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/drill/drill_detail_screen.dart';

/// S13 §13.6 — Header showing drill name. Styled to match ZxAppBar.
class ExecutionHeader extends StatelessWidget implements PreferredSizeWidget {
  final Drill drill;
  final int currentSetIndex;
  final int requiredSetCount;
  final int currentInstanceCount;
  final int? requiredAttemptsPerSet;
  final VoidCallback? onInfoTap;

  const ExecutionHeader({
    super.key,
    required this.drill,
    required this.currentSetIndex,
    required this.requiredSetCount,
    required this.currentInstanceCount,
    this.requiredAttemptsPerSet,
    this.onInfoTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: false,
      child: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: ColorTokens.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DrillDetailScreen(
                drillId: drill.drillId,
                isCustom: drill.origin == DrillOrigin.custom,
              ),
            ),
          ),
          child: Text(
            drill.name,
            style: TextStyle(
              fontSize: TypographyTokens.headerSize,
              fontWeight: TypographyTokens.headerWeight,
              color: ColorTokens.textPrimary,
            ),
          ),
        ),
        actions: [
          if (onInfoTap != null)
            IconButton(
              icon: const Icon(Icons.info_outline,
                  color: ColorTokens.textSecondary),
              onPressed: onInfoTap,
            ),
        ],
        centerTitle: true,
        backgroundColor: ColorTokens.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
