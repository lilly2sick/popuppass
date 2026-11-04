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
}
