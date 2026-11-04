import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../design/components/lanyard_loader.dart';
import '../design/theme.dart';
import '../l10n/app_localizations.dart';
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LanyardLoader(hasError: boot.hasError),
      );
    }
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: PPTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
