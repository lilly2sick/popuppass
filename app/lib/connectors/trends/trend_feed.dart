import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../connector.dart';

/// Downloads the public trend snapshot built by the backend aggregator and
/// caches it. Ranking for this shop happens on device.
class TrendFeed extends Connector<Map<String, dynamic>, TrendCacheCompanion> {
  TrendFeed(super.cursors, this.db, {required this.supabaseUrl, required this.anonKey, Dio? http})
    : http = http ?? Dio();

  final AppDatabase db;
  final String supabaseUrl;
  final String anonKey;
  final Dio http;

  @override
  String get id => 'trends';

  @override
  Future<List<Map<String, dynamic>>> fetch(String? cursor) async {
    final res = await http.get<List<dynamic>>(
      '$supabaseUrl/rest/v1/trends',
      queryParameters: {
        'select': '*',
        'order': 'score.desc',
        'limit': '200',
        if (cursor != null) 'snapshot_version': 'gt.$cursor',
      },
      options: Options(headers: {'apikey': anonKey}),
    );
    return (res.data ?? const []).cast<Map<String, dynamic>>();
  }

  @override
  TrendCacheCompanion normalize(Map<String, dynamic> t) => TrendCacheCompanion.insert(
    id: t['id'] as String,
    keyword: t['keyword'] as String,
    niche: t['niche'] as String,
    score: (t['score'] as num).toDouble(),
    title: t['title'] as String,
    why: t['why'] as String,
    itemIdea: Value(t['item_idea'] as String?),
    sources: (t['sources'] as List).cast<String>(),
    snapshotVersion: t['snapshot_version'] as String,
  );

  @override
  Future<int> sink(List<TrendCacheCompanion> models) async {
    if (models.isEmpty) return 0;
    await db.transaction(() async {
      await db.delete(db.trendCache).go();
      await db.batch((b) => b.insertAll(db.trendCache, models));
    });
    return models.length;
  }

  @override
  String? nextCursor(List<Map<String, dynamic>> raws, String? previous) =>
      raws.isEmpty ? previous : raws.first['snapshot_version'] as String;
}
