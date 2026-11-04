/// Every size a post or flyer renders at. Templates lay out relative to the
/// short side so one template works for all of them.
enum PostFormat {
  instagramPortrait('Insta post', 1080, 1350),
  square('Square', 1080, 1080),
  story('Story', 1080, 1920),
  facebookLink('Facebook', 1200, 630),
  linkedin('LinkedIn', 1200, 627),
  shopListing('Shop listing', 2048, 2048),
  flyerLetter('Print flyer', 2550, 3300);

  const PostFormat(this.label, this.width, this.height);

  final String label;
  final int width;
  final int height;

  double get aspect => width / height;
  bool get isLandscape => width > height;
  String get sizeLabel => '${width}x$height';

  /// Layout at a third of the final pixels, capture at 3x. Keeps text crisp
  /// without huge widget trees.
  static const capturePixelRatio = 3.0;
  double get logicalWidth => width / capturePixelRatio;
  double get logicalHeight => height / capturePixelRatio;
}
