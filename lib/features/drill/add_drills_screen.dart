import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';

import 'drill_create_screen.dart';
import 'standard_drills_screen.dart';

/// Chooser screen: Add ZX Drills or Create Custom Drill.
class AddDrillsScreen extends StatelessWidget {
  const AddDrillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ZxAppBar(title: 'Add Drills'),
      body: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SpacingTokens.lg),
            _ChoiceCard(
              icon: Icons.library_books,
              title: 'Browse Standard Drills',
              subtitle: 'Add golf drills to your library from our catalogue, build your SkillScore',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const StandardDrillsScreen(),
              )),
            ),
            const SizedBox(height: SpacingTokens.md),
            _ChoiceCard(
              icon: Icons.edit_note,
              title: 'Create Custom Drill',
              subtitle: 'Design your own custom drills',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DrillCreateScreen(),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorTokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Row(
            children: [
              Icon(icon, size: 36, color: ColorTokens.primaryDefault),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: TypographyTokens.headerSize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ColorTokens.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
