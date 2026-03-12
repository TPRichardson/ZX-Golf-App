import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';

import 'schedule_create_screen.dart';
import 'schedule_detail_screen.dart';

// S08 §8.12.3 — Schedule list screen.

class ScheduleListScreen extends ConsumerWidget {
  const ScheduleListScreen({super.key});

  static const _userId = kDevUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesProvider(_userId));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Schedules'),
      body: schedulesAsync.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month,
                      size: 48, color: ColorTokens.textTertiary),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'No schedules yet',
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'Create a schedule to plan practice across days',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(SpacingTokens.md),
            itemCount: schedules.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: SpacingTokens.sm),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _ScheduleListTile(
                schedule: schedule,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ScheduleDetailScreen(
                        scheduleId: schedule.scheduleId),
                  ));
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: ColorTokens.primaryDefault),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: TextStyle(color: ColorTokens.textSecondary)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ScheduleCreateScreen(),
          ));
        },
        backgroundColor: ColorTokens.primaryDefault,
        child: const Icon(Icons.add, color: ColorTokens.textPrimary),
      ),
    );
  }
}

class _ScheduleListTile extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;

  const _ScheduleListTile({
    required this.schedule,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.name,
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: TypographyTokens.headerWeight,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  Text(
                    schedule.applicationMode.dbValue,
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: ColorTokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
