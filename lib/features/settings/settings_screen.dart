import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/models/user_preferences.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';
import 'execution_defaults_screen.dart';
import 'calendar_defaults_screen.dart';

// S10 — Settings hub screen. Accessed via gear icon in ShellScreen AppBar.

class SettingsScreen extends ConsumerStatefulWidget {
  /// Optional section key to scroll to and highlight on open.
  final String? scrollToSection;

  const SettingsScreen({super.key, this.scrollToSection});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scrollController = ScrollController();
  final _calendarKey = GlobalKey();
  final _practiceKey = GlobalKey();
  String? _highlightedSection;

  @override
  void initState() {
    super.initState();
    if (widget.scrollToSection != null) {
      _highlightedSection = widget.scrollToSection;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection());
      // Clear highlight after 2 seconds.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _highlightedSection = null);
      });
    }
  }

  void _scrollToSection() {
    final keyMap = {'calendar': _calendarKey, 'practice': _practiceKey};
    final key = keyMap[widget.scrollToSection];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPreferencesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final authProfile = ref.watch(authProfileProvider);

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: ColorTokens.surfacePrimary,
      ),
      body: ListView(
        controller: _scrollController,
        children: [
          // --- Profile Section ---
          _SectionHeader(title: 'Profile'),
          userAsync.when(
            data: (user) => Column(
              children: [
                _InfoTile(
                  label: 'Display Name',
                  value: user?.displayName ?? authProfile.displayName ?? 'Not set',
                ),
                _InfoTile(
                  label: 'Email',
                  value: user?.email ?? authProfile.email ?? 'Not set',
                ),
                _InfoTile(
                  label: 'Timezone',
                  value: user?.timezone ?? 'UTC',
                ),
              ],
            ),
            loading: () => const _LoadingTile(),
            error: (_, _) => Column(
              children: [
                _InfoTile(
                  label: 'Display Name',
                  value: authProfile.displayName ?? 'Not set',
                ),
                _InfoTile(
                  label: 'Email',
                  value: authProfile.email ?? 'Not set',
                ),
              ],
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
          _SectionHeader(
            key: _calendarKey,
            title: 'Calendar',
            highlighted: _highlightedSection == 'calendar',
          ),
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

          // --- Practice Section ---
          _SectionHeader(key: _practiceKey, title: 'Practice'),
          _SwitchTile(
            label: 'Screen Always On During Drills',
            value: prefs.screenAlwaysOn,
            onChanged: (v) => updatePreferences(
                ref, prefs.copyWith(screenAlwaysOn: v)),
          ),
          _SwitchTile(
            label: 'Target Bars Show ± Half by Default',
            value: prefs.targetBarSplitView,
            onChanged: (v) => updatePreferences(
                ref, prefs.copyWith(targetBarSplitView: v)),
          ),
          _SwitchTile(
            label: 'Shot Input Sound',
            value: prefs.shotInputSound,
            onChanged: (v) => updatePreferences(
                ref, prefs.copyWith(shotInputSound: v)),
          ),
          _ToggleTile(
            label: 'Shot Input Vibration',
            value: _vibrationLabel(prefs.shotInputVibration),
            onTap: () => _cycleVibration(ref, prefs),
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
          ref.watch(lastSyncTimestampProvider).when(
            data: (ts) => _InfoTile(
              label: 'Last Synced',
              value: ts != null ? _formatSyncTime(ts) : 'Never',
            ),
            loading: () => const _InfoTile(label: 'Last Synced', value: '...'),
            error: (_, _) => const _InfoTile(label: 'Last Synced', value: 'Unknown'),
          ),
          _ActionTile(
            label: 'Sync Now',
            onTap: () => _triggerManualSync(context, ref),
          ),
          _ActionTile(
            label: 'Force Full Sync',
            onTap: () => _triggerFullSync(context, ref),
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

  void _cycleVibration(WidgetRef ref, UserPreferences prefs) {
    const order = ['off', 'soft', 'medium', 'hard'];
    final idx = order.indexOf(prefs.shotInputVibration);
    final next = order[(idx + 1) % order.length];
    updatePreferences(ref, prefs.copyWith(shotInputVibration: next));
  }

  String _vibrationLabel(String value) {
    return switch (value) {
      'off' => 'Off',
      'soft' => 'Soft',
      'hard' => 'Hard',
      _ => 'Medium',
    };
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

  String _formatSyncTime(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  void _triggerManualSync(BuildContext context, WidgetRef ref) {
    ref.read(syncOrchestratorProvider).requestSync(SyncTrigger.manual);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync triggered')),
    );
  }

  void _triggerFullSync(BuildContext context, WidgetRef ref) {
    ref.read(syncOrchestratorProvider).requestSync(SyncTrigger.forceFullSync);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full sync triggered')),
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
    final confirmed = await showSoftConfirmation(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
    );
    if (confirmed) {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    // S10 §10.5 — Strong confirmation: type "DELETE" to confirm.
    final confirmed = await showStrongConfirmation(
      context,
      title: 'Delete Account',
      message: 'This will permanently delete all local data. Type DELETE to confirm.',
      confirmPhrase: 'DELETE',
    );
    if (confirmed) {
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
  final bool highlighted;
  const _SectionHeader({super.key, required this.title, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.lg,
        SpacingTokens.md,
        SpacingTokens.sm,
      ),
      color: highlighted
          ? ColorTokens.primaryDefault.withValues(alpha: 0.1)
          : null,
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

class _EditableTile extends StatefulWidget {
  final String label;
  final String value;
  final String? hint;
  final TextInputType keyboardType;
  final ValueChanged<String> onSubmitted;
  const _EditableTile({
    required this.label,
    required this.value,
    this.hint,
    this.keyboardType = TextInputType.text,
    required this.onSubmitted,
  });

  @override
  State<_EditableTile> createState() => _EditableTileState();
}

class _EditableTileState extends State<_EditableTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_EditableTile old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.xs,
      ),
      child: Row(
        children: [
          const SizedBox(width: SpacingTokens.lg),
          SizedBox(
            width: 80,
            child: Text(
              widget.label,
              style: const TextStyle(
                color: ColorTokens.textSecondary,
                fontSize: TypographyTokens.bodySmSize,
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              style: const TextStyle(
                color: ColorTokens.textPrimary,
                fontSize: TypographyTokens.bodySmSize,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: ColorTokens.textTertiary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ColorTokens.textTertiary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ColorTokens.textTertiary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ColorTokens.primaryDefault),
                ),
              ),
              onSubmitted: widget.onSubmitted,
              onTapOutside: (_) {
                if (_controller.text != widget.value) {
                  widget.onSubmitted(_controller.text);
                }
              },
            ),
          ),
        ],
      ),
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
