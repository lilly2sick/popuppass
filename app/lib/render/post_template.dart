import 'dart:math';

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import 'post_format.dart';

/// Everything a template can show. The brand frame (shop, handle, booth)
/// appears on every template.
class PostContent {
  const PostContent({
    required this.headline,
    required this.shopName,
    this.priceLabel,
    this.handle,
    this.boothLabel,
    this.image,
    this.brandColor = PPColors.violet,
  });

  final String headline;
  final String shopName;
  final String? priceLabel;
  final String? handle;
  final String? boothLabel;
  final ImageProvider? image;
  final Color brandColor;
}

/// Base for every post and flyer template. Subclasses lay out named slots;
/// [build] wraps them at the exact logical size for the format.
abstract class PostTemplate {
  const PostTemplate();

  String get id;
  String get name;

  Widget layout(PostContent c, PostFormat f, double unit);

  /// [unit] = 1% of the short side, so sizes scale across formats.
  Widget build(PostContent c, PostFormat f) {
    final unit = min(f.logicalWidth, f.logicalHeight) / 100;
    return SizedBox(width: f.logicalWidth, height: f.logicalHeight, child: layout(c, f, unit));
  }
}

class StickerDropTemplate extends PostTemplate {
  const StickerDropTemplate();

  @override
  String get id => 'sticker-drop';

  @override
  String get name => 'Sticker drop';

  @override
  Widget layout(PostContent c, PostFormat f, double u) {
    final photo = Container(
      decoration: BoxDecoration(
        color: PPColors.text,
        borderRadius: BorderRadius.circular(5 * u),
        image: c.image == null ? null : DecorationImage(image: c.image!, fit: BoxFit.cover),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          c.headline,
          style: PPType.title(size: 9 * u, color: PPColors.onAccent),
        ),
        SizedBox(height: 2 * u),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              [c.priceLabel, c.boothLabel].whereType<String>().join(' / ').toUpperCase(),
              style: PPType.label(size: 3 * u, color: PPColors.onAccent),
            ),
            if (c.handle != null)
              Text(
                c.handle!.toUpperCase(),
                style: PPType.label(size: 3 * u, color: PPColors.onAccent),
              ),
          ],
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.brandColor, PPColors.pink],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(6 * u),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              c.shopName.toUpperCase(),
              style: PPType.label(size: 3.2 * u, color: PPColors.onAccent),
            ),
            SizedBox(height: 4 * u),
            Expanded(
              child: f.isLandscape
                  ? Row(
                      children: [
                        Expanded(child: photo),
                        SizedBox(width: 5 * u),
                        Expanded(
                          child: Align(alignment: Alignment.bottomLeft, child: text),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: photo),
                        SizedBox(height: 5 * u),
                        text,
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Registry the Create screen reads. Lilly's templates get added here.
const postTemplates = <PostTemplate>[StickerDropTemplate()];
