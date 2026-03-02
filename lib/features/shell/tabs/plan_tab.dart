import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/planning/screens/calendar_screen.dart';
import 'package:zx_golf_app/features/planning/screens/routine_list_screen.dart';
import 'package:zx_golf_app/features/planning/screens/schedule_list_screen.dart';

// S08 §8.12.1 — Plan tab: Calendar | Create dual-tab layout.

class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plan'),
          backgroundColor: ColorTokens.surfacePrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: ColorTokens.primaryDefault,
            labelColor: ColorTokens.textPrimary,
            unselectedLabelColor: ColorTokens.textSecondary,
            tabs: const [
              Tab(text: 'Calendar'),
              Tab(text: 'Create'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CalendarScreen(),
            _CreateTab(),
          ],
        ),
      ),
    );
  }
}

/// S08 §8.12.1 — Create tab: links to create Drill, Routine, Schedule.
class _CreateTab extends StatelessWidget {
  const _CreateTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.md),
      children: [
        _CreateCard(
          icon: Icons.sports_golf,
          title: 'Routines',
          subtitle: 'Create and manage practice routines',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const RoutineListScreen(),
            ));
          },
        ),
        const SizedBox(height: SpacingTokens.sm),
        _CreateCard(
          icon: Icons.calendar_month,
          title: 'Schedules',
          subtitle: 'Plan practice across date ranges',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ScheduleListScreen(),
            ));
          },
        ),
      ],
    );
  }
}

class _CreateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: ColorTokens.primaryDefault, size: 32),
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
            const Icon(Icons.chevron_right, color: ColorTokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
