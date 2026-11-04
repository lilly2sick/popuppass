import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/domain/enums.dart';
import 'package:popup_pass/providers.dart';

import 'support/harness.dart';

void main() {
  setUpAll(loadBrandFonts);

  testWidgets('Settings shows the default schedule and the sheet changes it', (tester) async {
    usePhone(tester);
    final harness = (await tester.runAsync(AppHarness.create))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    harness.router.go('/settings');
    await tester.pumpWidget(harness.app);
    await settle(tester);

    expect(find.text('Weekly at 9:00 AM'), findsOneWidget);

    await tester.tap(find.text('Idea reminders'));
    await settle(tester);
    await tester.tap(find.text('Daily'));
    await settle(tester);

    expect(harness.notifier.scheduled, hasLength(14));
    expect(harness.notifier.lastTitle, isNotEmpty);
    expect(
      (await tester.runAsync(
        () => harness.container.read(recommendationScheduleProvider.future),
      ))!.frequency,
      RecommendationFrequency.daily,
    );

    await tester.tap(find.text('Off'));
    await settle(tester);
    expect(harness.notifier.scheduled, isEmpty);
  });

  testWidgets('Home header opens Saved ideas with sources for right-swiped cards', (tester) async {
    usePhone(tester);
    final harness = (await tester.runAsync(AppHarness.create))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    await tester.pumpWidget(harness.app);
    await settle(tester);

    await tester.scrollUntilVisible(
      find.text('Try it'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Try it'));
    await settle(tester);
    await settle(tester);

    await tester.scrollUntilVisible(
      find.byTooltip('Saved ideas'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Saved ideas'));
    await settle(tester);
    expect(find.textContaining('Sources:'), findsOneWidget);
  });

  testWidgets('Home best seller draft opens Create on that item', (tester) async {
    usePhone(tester);
    final harness = (await tester.runAsync(AppHarness.create))!;
    addTearDown(() => tester.runAsync(harness.dispose));
    await tester.pumpWidget(harness.app);
    await settle(tester);

    await tester.scrollUntilVisible(
      find.text('Create draft'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Create draft'));
    await settle(tester);
    expect(find.text('Cat sticker, holo is back.'), findsWidgets);
  });
}
