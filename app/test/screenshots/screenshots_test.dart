import 'dart:io';
import 'dart:ui' as ui;

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

  testWidgets('home', (t) => shootTab(t, AppTab.home, 'home'));
  testWidgets('shop', (t) => shootTab(t, AppTab.shop, 'shop'));
  testWidgets('sell', (t) => shootTab(t, AppTab.sell, 'sell'));
  testWidgets('create', (t) => shootTab(t, AppTab.create, 'create'));
  testWidgets('insights', (t) => shootTab(t, AppTab.insights, 'insights'));

  testWidgets('home-bottom', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -3000));
    await settle(tester);
    await _shoot(tester, 'home-bottom');
  });

  testWidgets('sell-grid', (tester) async {
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

  testWidgets('events', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.tap(find.textContaining('Anime Fest').first);
    await settle(tester);
    await _shoot(tester, 'events');
  });

  testWidgets('create-share', (tester) async {
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

  testWidgets('pup-faq', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.tap(find.bySemanticsLabel('Ask PUP'));
    await settle(tester);
    await _shoot(tester, 'pup-faq');
  });

  testWidgets('search', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await _mount(tester, harness);
    await tester.enterText(find.byType(TextField).first, 'frog');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    await _shoot(tester, 'search');
  });

  testWidgets('settings', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    harness.router.go('/settings');
    await _mount(tester, harness);
    await _shoot(tester, 'settings');
  });

  testWidgets('splash', (tester) async {
    usePhone(tester);
    final harness = await AppHarness.create(seed: false, bootstrapped: false);
    addTearDown(harness.dispose);
    await tester.pumpWidget(RepaintBoundary(key: _boundaryKey, child: harness.app));
    await tester.pump(const Duration(milliseconds: 50));
    await _shoot(tester, 'splash');
  });
}
