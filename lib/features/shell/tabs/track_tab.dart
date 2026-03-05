import 'package:flutter/material.dart';
import 'package:zx_golf_app/features/drill/practice_pool_screen.dart';

// Phase 4 — Track tab: displays PracticePoolScreen.
// S12 §12.3 — Track tab primary view.
// Resume/Discard controls moved to shell-level persistent bar.

class TrackTab extends StatelessWidget {
  const TrackTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PracticePoolScreen();
  }
}
