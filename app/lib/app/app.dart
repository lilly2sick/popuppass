import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../design/components/lanyard_loader.dart';
import '../design/theme.dart';
import '../providers.dart';
import 'router.dart';

class PopUpPassApp extends ConsumerWidget {
  const PopUpPassApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapProvider);
    if (!boot.hasValue) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PPTheme.dark(),
        home: LanyardLoader(
          error: boot.hasError ? 'Something went wrong starting up. Restart the app.' : null,
        ),
      );
    }
    return MaterialApp.router(
      title: 'Pop-Up Pass',
      debugShowCheckedModeBanner: false,
      theme: PPTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
