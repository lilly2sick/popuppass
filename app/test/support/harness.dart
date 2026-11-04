import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:popup_pass/app/app.dart';
import 'package:popup_pass/app/router.dart';
import 'package:popup_pass/config.dart';
import 'package:popup_pass/data/db/database.dart';
import 'package:popup_pass/data/sample_seed.dart';
import 'package:popup_pass/providers.dart';

/// The phone the artboards are drawn for.
const phone = Size(390, 844);

/// Registers the bundled brand fonts so text measures and paints like it does
/// on a device instead of falling back to the test font.
Future<void> loadBrandFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));

  final ronzino = FontLoader('Ronzino')
    ..addFont(bytes('assets/fonts/Ronzino-Regular.otf'))
    ..addFont(bytes('assets/fonts/Ronzino-Medium.otf'))
    ..addFont(bytes('assets/fonts/Ronzino-Bold.otf'));
  final bdo = FontLoader('BDOGrotesk')..addFont(bytes('assets/fonts/BDO-Grotesk-VF.ttf'));
  await ronzino.load();
  await bdo.load();

  // Material icons ship with the SDK, not the app; load them so icons paint
  // as glyphs instead of placeholder boxes.
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = root == null
      ? null
      : File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(bytes(icons.path))).load();
  }
}

/// A running copy of the app on fakes with seeded sample data.
class AppHarness {
  AppHarness._(this.db, this.container);

  final AppDatabase db;
  final ProviderContainer container;

  GoRouter get router => container.read(routerProvider);

  /// [introSeen] skips PUP's first-launch greeting sheet.
  static Future<AppHarness> create({
    bool seed = true,
    bool bootstrapped = true,
    bool introSeen = true,
  }) async {
    FlutterSecureStorage.setMockInitialValues({if (introSeen) 'pup_intro_seen': '1'});
    final db = AppDatabase(NativeDatabase.memory());
    if (seed) await SampleSeed(db).seedIfEmpty();
    final container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        bootstrapProvider.overrideWith(
          (_) => bootstrapped ? Future<void>.value() : Completer<void>().future,
        ),
        connectionLabelProvider.overrideWith((_) => Stream.value('Saved on phone')),
      ],
    );
    return AppHarness._(db, container);
  }

  Widget get app => UncontrolledProviderScope(
    container: container,
    child: PopUpPassApp(config: AppConfig.fromEnvironment()),
  );

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

/// Sizes the test surface to the phone at [pixelRatio].
void usePhone(WidgetTester tester, {double pixelRatio = 1}) {
  tester.view.physicalSize = phone * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
}

/// Pumps frames until the database streams settle. Animations in the app
/// repeat forever, so pumpAndSettle would never return.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens [tab] on a fresh app and returns once data has loaded.
Future<AppHarness> openTab(WidgetTester tester, AppTab tab, {double pixelRatio = 1}) async {
  usePhone(tester, pixelRatio: pixelRatio);
  final harness = (await tester.runAsync(AppHarness.create))!;
  addTearDown(() => tester.runAsync(harness.dispose));
  await tester.pumpWidget(harness.app);
  await settle(tester);
  if (tab != AppTab.home) {
    harness.router.go(tab.path);
    await settle(tester);
  }
  return harness;
}
