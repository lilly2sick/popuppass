import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../data/repos/event_repo.dart';
import '../../domain/enums.dart';
import '../connector.dart';
import 'ics_codec.dart';

/// Imports a .ics file the user picked. Set [pendingText] then call ingest().
class IcsConnector extends Connector<Map<String, String>, EventsCompanion> {
  IcsConnector(super.cursors, this.events, {this.codec = const IcsCodec()});

  final EventRepo events;
  final IcsCodec codec;
  String? pendingText;

  @override
  String get id => 'ics';

  @override
  Future<List<Map<String, String>>> fetch(String? cursor) async {
    final text = pendingText;
    pendingText = null;
    if (text == null) return const [];
    return codec.parse(text).where((e) => codec.parseDate(e['DTSTART']) != null).toList();
  }

  @override
  EventsCompanion normalize(Map<String, String> raw) {
    final start = codec.parseDate(raw['DTSTART'])!;
    return EventsCompanion.insert(
      name: raw['SUMMARY'] ?? 'Untitled event',
      startsAt: start,
      endsAt: codec.parseDate(raw['DTEND']) ?? start.add(const Duration(hours: 8)),
      venue: Value(raw['LOCATION']),
      source: const Value(RecordSource.ics),
      externalId: Value(raw['UID'] ?? '${raw['SUMMARY']}-${raw['DTSTART']}'),
    );
  }

  @override
  Future<int> sink(List<EventsCompanion> models) => events.importAll(models);
}
