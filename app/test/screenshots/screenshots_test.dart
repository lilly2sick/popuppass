import 'dart:io';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/app/router.dart';

import '../support/harness.dart';

/// Writes docs/screenshots/*.png from the real widgets, real fonts and the
/// sample shop, at 390x844 and devicePixelRatio 3 (1170x2532 pixels).
///
/// Run with `flutter test test/screenshots`. The PNGs are written on every
/// run so they always reflect the current build; commit them for review.
final _outDir = Directory('../docs/screenshots');
final _boundaryKey = GlobalKey();

/// Pumps [harness]'s app wrapped in a capture boundary and settles it.
Future<void> _mount(WidgetTester tester, AppHarness harness) async {
  await tester.pumpWidget(RepaintBoundary(key: _boundaryKey, child: harness.app));
  await settle(tester);
}

/// Captures whatever is currently on screen under [_boundaryKey] to
/// docs/screenshots/[name].png at devicePixelRatio 3.
Future<void> _shoot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: '$name overflowed or threw');
  final boundary = _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  _outDir.createSync(recursive: true);
  File('${_outDir.path}/$name.png').writeAsBytesSync(bytes!);
}

/// Every render uses the same moment, so sample dates ("NOV 3-5", cons near you)
/// and the committed PNGs do not drift from day to day.
final _frozenNow = DateTime(2026, 11, 4, 12);

void _shot(String description, WidgetTesterCallback callback) => testWidgets(
  description,
  (tester) => withClock(Clock.fixed(_frozenNow), () => callback(tester)),
);

void main() {
  setUpAll(loadBrandFonts);

  Future<void> shootTab(WidgetTester tester, AppTab tab, String name) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    if (tab != AppTab.home) {
      harness.router.go(tab.path);
      await settle(tester);
    }
    await _shoot(tester, name);
  }

  _shot('home', (t) => shootTab(t, AppTab.home, 'home'));
  _shot('shop', (t) => shootTab(t, AppTab.shop, 'shop'));
  _shot('sell', (t) => shootTab(t, AppTab.sell, 'sell'));
  _shot('create', (t) => shootTab(t, AppTab.create, 'create'));
  _shot('insights', (t) => shootTab(t, AppTab.insights, 'insights'));

  _shot('home-bottom', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -3000));
    await settle(tester);
    await _shoot(tester, 'home-bottom');
  });

  _shot('sell-grid', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    harness.router.go(AppTab.sell.path);
    await settle(tester);
    final gridButton = find.byIcon(Icons.grid_view_rounded);
    expect(gridButton, findsOneWidget);
    await tester.tap(gridButton);
    await settle(tester);
    await _shoot(tester, 'sell-grid');
  });

  _shot('events', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.tap(find.textContaining('Anime Fest').first);
    await settle(tester);
    await _shoot(tester, 'events');
  });

  _shot('create-share', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    harness.router.go(AppTab.create.path);
    await settle(tester);
    await tester.tap(find.text('Share or save'));
    await settle(tester);
    await _shoot(tester, 'create-share');
  });

  _shot('pup-faq', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.tap(find.bySemanticsLabel('Ask PUP'));
    await settle(tester);
    await _shoot(tester, 'pup-faq');
  });

  _shot('search', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.enterText(find.byType(TextField).first, 'frog');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    await _shoot(tester, 'search');
  });

  _shot('settings', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    harness.router.go('/settings');
    await _mount(tester, harness);
    await _shoot(tester, 'settings');
  });

  _shot('reminders', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.scrollUntilVisible(
      find.byTooltip('Idea reminders'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Idea reminders'));
    await settle(tester);
    await _shoot(tester, 'reminders');
  });

  _shot('splash', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create(seed: false, bootstrapped: false);
    addTearDown(harness.dispose);
    await tester.pumpWidget(RepaintBoundary(key: _boundaryKey, child: harness.app));
    await tester.pump(const Duration(milliseconds: 50));
    await _shoot(tester, 'splash');
  });
}
