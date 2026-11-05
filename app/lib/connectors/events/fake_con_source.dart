import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../domain/enums.dart';
import 'con_source.dart';

/// Three sample cons so the Events sheet has something to add offline.
class FakeConSource implements ConSource {
  @override
  String get id => 'fake-cons';

  @override
  String get attribution => 'Sample data';

  @override
  Future<List<EventsCompanion>> upcoming() async {
    final now = clock.now();
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
