import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/pup.dart';
import '../design/components/tab_bar.dart';
import '../providers.dart';
import '../services/haptics_service.dart';

/// Hosts the five tab branches, the bottom tab bar, and PUP in the corner.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          shell,
          const Positioned(right: 16, bottom: 16, child: PupCornerButton()),
        ],
      ),
      bottomNavigationBar: PPTabBar(
        currentIndex: shell.currentIndex,
        onTap: (index) {
          ref.read(hapticsProvider).play(HapticMoment.selection);
          shell.goBranch(index, initialLocation: index == shell.currentIndex);
        },
      ),
    );
  }
}
