import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/render/capture.dart';
import 'package:popup_pass/render/post_format.dart';
import 'package:popup_pass/render/post_template.dart';

void main() {
  const content = PostContent(headline: 'Cat sticker is back.', shopName: 'Mochi Paws');

  for (final format in PostFormat.values) {
    testWidgets('${format.label} captures exactly ${format.sizeLabel}', (tester) async {
      // Big enough surface that no format is clamped by the test window.
      tester.view.physicalSize = const Size(2000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(key: key, child: postTemplates.first.build(content, format)),
          ),
        ),
      );
      final bytes = (await tester.runAsync(() => capturePng(key, targetWidth: format.width)))!;
      final codec = (await tester.runAsync(() => ui.instantiateImageCodec(bytes)))!;
      final frame = (await tester.runAsync(codec.getNextFrame))!;
      expect(frame.image.width, format.width);
      expect(frame.image.height, format.height);
    });
  }

  test('the supported sizes match SPEC 10', () {
    expect(
      {for (final f in PostFormat.values) f.sizeLabel},
      {'1080x1350', '1080x1080', '1080x1920', '1200x630', '1200x627', '2048x2048', '2550x3300'},
    );
  });
}
