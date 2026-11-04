import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/create/create_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/sell/sell_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shop/shop_screen.dart';
import 'app_shell.dart';

/// The five tabs, in tab-bar order. Sell is the raised center badge.
enum AppTab {
  home('/home'),
  shop('/shop'),
  sell('/sell'),
  create('/create'),
  insights('/insights');

  const AppTab(this.path);
  final String path;
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppTab.home.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          _branch(AppTab.home, const HomeScreen()),
          _branch(AppTab.shop, const ShopScreen()),
          _branch(AppTab.sell, const SellScreen()),
          _branch(AppTab.create, const CreateScreen()),
          _branch(AppTab.insights, const InsightsScreen()),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});

StatefulShellBranch _branch(AppTab tab, Widget screen) => StatefulShellBranch(
      routes: [GoRoute(path: tab.path, builder: (_, __) => screen)],
    );
