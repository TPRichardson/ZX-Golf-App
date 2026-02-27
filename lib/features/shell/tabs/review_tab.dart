import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';

// TD-06 §4.3 — Review tab placeholder.
// Phase 6 stub — replaced with SkillScore dashboard.

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ZxAppBar(title: 'Review'),
      body: Center(
        child: Text(
          'Review features coming in Phase 6',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColorTokens.textSecondary,
              ),
        ),
      ),
    );
  }
}
