import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../domain/enums.dart';

/// A list of cons the user can add. Nothing is stored until they tap Add.
abstract interface class ConSource {
  String get id;
  String get attribution;
  Future<List<EventsCompanion>> upcoming();
}

/// Reads the public `cons` table our backend refreshes daily from AnimeCons.
/// No auth, no user data sent. Distance is filtered on device.
class AnimeConsFeed implements ConSource {
  AnimeConsFeed({required this.supabaseUrl, required this.anonKey, Dio? http})
    : http = http ?? Dio();

  final String supabaseUrl;
  final String anonKey;
  final Dio http;

  @override
  String get id => 'animecons';

  @override
  String get attribution => 'Via animecons.com';

  @override
  Future<List<EventsCompanion>> upcoming() async {
    final res = await http.get<List<dynamic>>(
      '$supabaseUrl/rest/v1/cons',
      queryParameters: {
        'select': '*',
        'ends_at': 'gte.${DateTime.now().toUtc().toIso8601String()}',
      },
      options: Options(headers: {'apikey': anonKey}),
    );
    return [for (final c in res.data ?? const []) _toEvent(c as Map<String, dynamic>)];
  }

  EventsCompanion _toEvent(Map<String, dynamic> c) => EventsCompanion.insert(
    name: c['name'] as String,
    startsAt: DateTime.parse(c['starts_at'] as String),
    endsAt: DateTime.parse(c['ends_at'] as String),
    venue: Value(c['venue'] as String?),
    city: Value(c['city'] as String?),
    lat: Value((c['lat'] as num?)?.toDouble()),
    lng: Value((c['lng'] as num?)?.toDouble()),
    source: const Value(RecordSource.animecons),
    externalId: Value(c['external_id'] as String),
  );
}

class FakeConSource implements ConSource {
  @override
  String get id => 'fake-cons';

  @override
  String get attribution => 'Sample data';

  @override
  Future<List<EventsCompanion>> upcoming() async {
    final now = DateTime.now();
    EventsCompanion con(String name, int inDays, double lat, double lng) => EventsCompanion.insert(
      name: name,
      startsAt: now.add(Duration(days: inDays)),
      endsAt: now.add(Duration(days: inDays + 2)),
      lat: Value(lat),
      lng: Value(lng),
      source: const Value(RecordSource.animecons),
      externalId: Value('fake-$name'),
    );
    return [
      con('Sample Winter Con', 70, 37.80, -122.27),
      con('Sample Comic Expo', 95, 37.33, -121.89),
      con('Sample Anime Weekend', 140, 38.58, -121.49),
    ];
  }
}

/// Great-circle distance in miles. Runs on device; location never leaves it.
double milesBetween(double lat1, double lng1, double lat2, double lng2) {
  const r = 3958.8;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = pow(sin(dLat / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * r * asin(sqrt(a));
}
