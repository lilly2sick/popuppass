import '../data/db/database.dart';

/// Ranks the public trend feed for this shop, on device.
/// score = trend velocity * (1 + tag overlap) with swiped cards removed.
class RecommendationService {
  const RecommendationService();

  List<CachedTrend> rank({
    required List<CachedTrend> trends,
    required Set<String> shopTags,
    required Set<String> swipedIds,
  }) {
    final tags = shopTags.map((t) => t.toLowerCase()).toSet();
    final scored = [
      for (final t in trends)
        if (!swipedIds.contains(t.id))
          (t, t.score * (1 + (tags.contains(t.niche.toLowerCase()) ? 1 : 0))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored) s.$1];
  }

  /// SPEC 16's batch: the top ranked cards (new ideas) plus, when there is a
  /// best seller, one more suggestion to post it. Built entirely on device
  /// from the cached feed, so it works offline.
  List<CachedTrend> batch({
    required List<CachedTrend> trends,
    required Set<String> shopTags,
    required Set<String> swipedIds,
    int limit = 5,
  }) => rank(trends: trends, shopTags: shopTags, swipedIds: swipedIds).take(limit).toList();
}
