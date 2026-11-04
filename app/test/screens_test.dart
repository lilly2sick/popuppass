import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/app/router.dart';
import 'package:popup_pass/design/components/sticker.dart';
import 'package:popup_pass/design/tokens.dart';

import 'support/harness.dart';

/// Every tab pumped on fakes at 390x844. A layout overflow throws in debug
/// builds, so a null exception means nothing is clipped.
void main() {
  setUpAll(loadBrandFonts);

  for (final tab in AppTab.values) {
    testWidgets('${tab.name} tab renders without overflow', (tester) async {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull);
      expect(find.text('Anime Fest 2026'), findsOneWidget);
    });
  }

  testWidgets('home shows stat tiles, almost gone alert and the ASCII banner', (tester) async {
    await openTab(tester, AppTab.home);
    expect(find.text('GROSS'), findsOneWidget);
    expect(find.text('Cat sticker, holo is almost gone.'), findsOneWidget);
    expect(find.text('Fan favorites'), findsOneWidget);
    expect(find.text('A good day, in four small steps'), findsOneWidget);
  });

  testWidgets('shop low stock filter keeps only low items', (tester) async {
    await openTab(tester, AppTab.shop);
    expect(find.text('Art print A5'), findsOneWidget);
    await tester.tap(find.text('Low stock'));
    await settle(tester);
    expect(find.text('Art print A5'), findsNothing);
    expect(find.text('Cat sticker, holo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shop search filters rows in place', (tester) async {
    await openTab(tester, AppTab.shop);
    await tester.enterText(find.byType(TextField).first, 'frog');
    await settle(tester);
    expect(find.text('Frog pin'), findsOneWidget);
    expect(find.text('Art print A5'), findsNothing);
  });

  testWidgets('sell: +1 and -1 keep stock correct, targets are 56px', (tester) async {
    final harness = await openTab(tester, AppTab.sell);
    final plus = find.text('+1 sold');
    expect(plus, findsOneWidget);
    final button = tester.widget<PPButton>(
      find.ancestor(of: plus, matching: find.byType(PPButton)).first,
    );
    expect(button.height, greaterThanOrEqualTo(PPTap.sell));

    Future<int> stock() async {
      final rows = await tester.runAsync(
        () => harness.db.customSelect('SELECT SUM(delta) AS n FROM inventory_moves').getSingle(),
      );
      return rows!.read<int>('n');
    }

    final before = await stock();
    await tester.tap(plus);
    await settle(tester);
    expect(await stock(), before - 1);

    await tester.tap(find.text('-1'));
    await settle(tester);
    expect(await stock(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sell: grid button shows a three column grid', (tester) async {
    await openTab(tester, AppTab.sell);
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await settle(tester);
    final xs = {
      for (final name in ['Art print A5', 'Cat sticker, ho...', 'Frog pin'])
        tester.getTopLeft(find.textContaining(name.split(',').first).first).dx.round(),
    };
    expect(xs.length, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create: share bar lists the five destinations', (tester) async {
    await openTab(tester, AppTab.create);
    await tester.tap(find.text('Share or save'));
    await settle(tester);
    for (final label in ['Save as PNG', 'Instagram', 'Facebook', 'LinkedIn', 'More apps']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('event bar opens the events sheet', (tester) async {
    await openTab(tester, AppTab.home);
    await tester.tap(find.text('Anime Fest 2026'));
    await settle(tester);
    expect(find.text('Your events'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PUP opens the FAQ sheet', (tester) async {
    await openTab(tester, AppTab.home);
    await tester.tap(find.bySemanticsLabel('Ask PUP'));
    await settle(tester);
    expect(find.text('Need a hand?'), findsOneWidget);
    expect(find.text('Does it work with no signal?'), findsOneWidget);
  });

  testWidgets('search submit opens app-wide results', (tester) async {
    await openTab(tester, AppTab.home);
    await tester.enterText(find.byType(TextField).first, 'frog');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.text('Results for "frog"'), findsOneWidget);
    expect(find.text('Frog pin'), findsWidgets);
  });

  testWidgets('settings renders on the grid', (tester) async {
    final harness = await openTab(tester, AppTab.home);
    harness.router.go('/settings');
    await settle(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lanyard loader shows while bootstrapping', (tester) async {
    usePhone(tester);
    final harness = (await tester.runAsync(
      () => AppHarness.create(seed: false, bootstrapped: false),
    ))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    await tester.pumpWidget(harness.app);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Setting up your table'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
