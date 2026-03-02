import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';

import 'routine_create_screen.dart';
import 'routine_detail_screen.dart';

// S08 §8.12.3 — Routine list screen.

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  static const _userId = kDevUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider(_userId));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Routines'),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add,
                      size: 48, color: ColorTokens.textTertiary),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'No routines yet',
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'Create a routine to plan your practice',
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
            itemCount: routines.length,
            separatorBuilder: (_, _) => const SizedBox(height: SpacingTokens.sm),
            itemBuilder: (context, index) {
              final routine = routines[index];
              final entries = _parseEntries(routine.entries);

              return _RoutineListTile(
                routine: routine,
                entryCount: entries.length,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        RoutineDetailScreen(routineId: routine.routineId),
                  ));
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: ColorTokens.primaryDefault),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: TextStyle(color: ColorTokens.textSecondary)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const RoutineCreateScreen(),
          ));
        },
        backgroundColor: ColorTokens.primaryDefault,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<RoutineEntry> _parseEntries(String json) {
    try {
      return (jsonDecode(json) as List<dynamic>)
          .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class _RoutineListTile extends StatelessWidget {
  final Routine routine;
  final int entryCount;
  final VoidCallback onTap;

  const _RoutineListTile({
    required this.routine,
    required this.entryCount,
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
                    routine.name,
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: TypographyTokens.headerWeight,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  Text(
                    '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
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
