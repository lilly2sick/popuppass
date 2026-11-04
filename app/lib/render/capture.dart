import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures whatever is inside the RepaintBoundary with [key] as PNG bytes.
///
/// With [targetWidth] the image comes out exactly that many pixels wide
/// (height follows the widget's aspect), regardless of how the preview is
/// scaled on screen. Used for posts at platform sizes and for chart PNGs.
Future<Uint8List> capturePng(GlobalKey key, {int? targetWidth, double pixelRatio = 3}) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ratio = targetWidth == null ? pixelRatio : targetWidth / boundary.size.width;
  final image = await boundary.toImage(pixelRatio: ratio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
