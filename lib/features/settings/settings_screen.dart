import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/models/user_preferences.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';
import 'execution_defaults_screen.dart';
import 'calendar_defaults_screen.dart';

// S10 — Settings hub screen. Accessed via gear icon in ShellScreen AppBar.

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: ColorTokens.surfacePrimary,
      ),
      body: ListView(
        children: [
          // --- Profile Section ---
          _SectionHeader(title: 'Profile'),
          userAsync.when(
            data: (user) => Column(
              children: [
                _InfoTile(
                  label: 'Display Name',
                  value: user?.displayName ?? 'Not set',
                ),
                _InfoTile(
                  label: 'Email',
                  value: user?.email ?? 'Not set',
                ),
                _InfoTile(
                  label: 'Timezone',
                  value: user?.timezone ?? 'UTC',
                ),
              ],
            ),
            loading: () => const _LoadingTile(),
            error: (_, _) => const _InfoTile(
              label: 'Profile',
              value: 'Unable to load',
            ),
          ),

          // --- Units Section ---
          _SectionHeader(title: 'Units'),
          _ToggleTile(
            label: 'Distance',
            value: prefs.distanceUnit == DistanceUnit.yards
                ? 'Yards'
                : 'Metres',
            onTap: () => _toggleDistanceUnit(ref, prefs),
          ),
          _ToggleTile(
            label: 'Small Length',
            value: prefs.smallLengthUnit == SmallLengthUnit.inches
                ? 'Inches'
                : 'Centimetres',
            onTap: () => _toggleSmallLengthUnit(ref, prefs),
          ),

          // --- Execution Section ---
          _SectionHeader(title: 'Execution'),
          _NavigationTile(
            label: 'Default Club Selection Modes',
            subtitle: 'Per skill area',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExecutionDefaultsScreen(),
              ),
            ),
          ),

          // --- Calendar Section ---
          _SectionHeader(title: 'Calendar'),
          _ToggleTile(
            label: 'Week Starts On',
            value: prefs.weekStartDay == 7 ? 'Sunday' : 'Monday',
            onTap: () => _toggleWeekStartDay(ref, prefs),
          ),
          _NavigationTile(
            label: 'Default Slot Capacity',
            subtitle: '7-day pattern',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CalendarDefaultsScreen(),
              ),
            ),
          ),

          // --- Analytics Section ---
          _SectionHeader(title: 'Analytics'),
          _ToggleTile(
            label: 'Default Resolution',
            value: _resolutionLabel(prefs.defaultAnalysisResolution),
            onTap: () => _cycleResolution(ref, prefs),
          ),

          // --- Notifications Section ---
          _SectionHeader(title: 'Notifications'),
          _SwitchTile(
            label: 'Daily Reminder',
            value: prefs.reminderEnabled,
            onChanged: (v) => _toggleReminder(ref, prefs, v),
          ),
          if (prefs.reminderEnabled)
            _ToggleTile(
              label: 'Reminder Time',
              value: prefs.reminderTime ?? '08:00',
              onTap: () => _pickReminderTime(context, ref, prefs),
            ),

          // --- Sync Section ---
          _SectionHeader(title: 'Sync'),
          _ActionTile(
            label: 'Sync Now',
            onTap: () => _triggerManualSync(context, ref),
          ),

          // --- Data Section ---
          _SectionHeader(title: 'Data'),
          _ActionTile(
            label: 'Export Data (JSON)',
            onTap: () => _exportData(context, ref),
          ),

          // --- Account Section ---
          _SectionHeader(title: 'Account'),
          _ActionTile(
            label: 'Sign Out',
            onTap: () => _signOut(context, ref),
          ),
          _ActionTile(
            label: 'Delete Account',
            isDestructive: true,
            onTap: () => _deleteAccount(context, ref),
          ),
          const SizedBox(height: SpacingTokens.xxl),
        ],
      ),
    );
  }

  void _toggleDistanceUnit(WidgetRef ref, UserPreferences prefs) {
    final next = prefs.distanceUnit == DistanceUnit.yards
        ? DistanceUnit.metres
        : DistanceUnit.yards;
    updatePreferences(ref, prefs.copyWith(distanceUnit: next));
  }

  void _toggleWeekStartDay(WidgetRef ref, UserPreferences prefs) {
    final next = prefs.weekStartDay == 1 ? 7 : 1;
    updatePreferences(ref, prefs.copyWith(weekStartDay: next));
  }

  void _toggleSmallLengthUnit(WidgetRef ref, UserPreferences prefs) {
    final next = prefs.smallLengthUnit == SmallLengthUnit.inches
        ? SmallLengthUnit.centimetres
        : SmallLengthUnit.inches;
    updatePreferences(ref, prefs.copyWith(smallLengthUnit: next));
  }

  void _cycleResolution(WidgetRef ref, UserPreferences prefs) {
    const order = ['daily', 'weekly', 'monthly'];
    final idx = order.indexOf(prefs.defaultAnalysisResolution);
    final next = order[(idx + 1) % order.length];
    updatePreferences(
        ref, prefs.copyWith(defaultAnalysisResolution: next));
  }

  String _resolutionLabel(String resolution) {
    switch (resolution) {
      case 'daily':
        return 'Daily';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Weekly';
    }
  }

  void _toggleReminder(
      WidgetRef ref, UserPreferences prefs, bool enabled) {
    updatePreferences(ref, prefs.copyWith(
      reminderEnabled: enabled,
      reminderTime: enabled ? (prefs.reminderTime ?? '08:00') : prefs.reminderTime,
    ));
    // Phase 8 stub — notification scheduling requires flutter_local_notifications.
  }

  Future<void> _pickReminderTime(
      BuildContext context, WidgetRef ref, UserPreferences prefs) async {
    final parts = (prefs.reminderTime ?? '08:00').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      updatePreferences(ref, prefs.copyWith(reminderTime: timeStr));
    }
  }

  void _triggerManualSync(BuildContext context, WidgetRef ref) {
    ref.read(syncOrchestratorProvider).requestSync(SyncTrigger.manual);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync triggered')),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    // Phase 8 — Data export. See data_export_service.dart.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export not yet implemented')),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    // S10 §10.5 — Strong confirmation: type "DELETE" to confirm.
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: ColorTokens.surfaceModal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
          ),
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete all local data. '
                'Type DELETE to confirm.',
              ),
              const SizedBox(height: SpacingTokens.md),
              TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Type DELETE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: controller.text == 'DELETE'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: Text(
                'Delete Account',
                style: TextStyle(
                  color: controller.text == 'DELETE'
                      ? ColorTokens.errorDestructive
                      : ColorTokens.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      // DEVIATION: Server-side cascade deletion deferred to post-V1.
      // See CLAUDE.md Known Deviations.
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Private tile widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.lg,
        SpacingTokens.md,
        SpacingTokens.sm,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: TypographyTokens.bodySize,
          fontWeight: FontWeight.w600,
          color: ColorTokens.primaryDefault,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: ColorTokens.textPrimary)),
      trailing: Text(
        value,
        style: const TextStyle(color: ColorTokens.textSecondary),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: ColorTokens.textPrimary)),
      trailing: Text(value, style: const TextStyle(color: ColorTokens.textSecondary)),
      onTap: onTap,
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _NavigationTile({
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: ColorTokens.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: ColorTokens.textTertiary))
          : null,
      trailing: const Icon(Icons.chevron_right, color: ColorTokens.textSecondary),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: ColorTokens.textPrimary)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: ColorTokens.primaryDefault,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _ActionTile({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive
              ? ColorTokens.errorDestructive
              : ColorTokens.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      title: Text('Loading...', style: TextStyle(color: ColorTokens.textTertiary)),
    );
  }
}
