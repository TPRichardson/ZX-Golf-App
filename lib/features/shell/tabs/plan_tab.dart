import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';

// TD-06 §4.3 — Plan tab placeholder.
// Phase 5 stub — replaced with full planning UI.

class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ZxAppBar(title: 'Plan'),
      body: Center(
        child: Text(
          'Planning features coming in Phase 5',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColorTokens.textSecondary,
              ),
        ),
      ),
    );
  }
}
