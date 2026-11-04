import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../data/repos/event_repo.dart';
import '../../domain/enums.dart';
import '../connector.dart';

/// Minimal RFC 5545 reader/writer for VEVENTs: UID, SUMMARY, DTSTART,
/// DTEND, LOCATION. Enough for calendar import and export.
class IcsCodec {
  const IcsCodec();

  List<Map<String, String>> parse(String text) {
    final unfolded = text.replaceAll(RegExp(r'\r?\n[ \t]'), '');
    final events = <Map<String, String>>[];
    Map<String, String>? cur;
    for (final line in unfolded.split(RegExp(r'\r?\n'))) {
      if (line == 'BEGIN:VEVENT') {
        cur = {};
      } else if (line == 'END:VEVENT') {
        if (cur != null) events.add(cur);
        cur = null;
      } else if (cur != null) {
        final i = line.indexOf(':');
        if (i <= 0) continue;
        final key = line.substring(0, i).split(';').first.toUpperCase();
        cur[key] = line.substring(i + 1).replaceAll(r'\,', ',').replaceAll(r'\n', '\n');
      }
    }
    return events;
  }

  DateTime? parseDate(String? v) {
    if (v == null) return null;
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$').firstMatch(v);
    if (m == null) return null;
    final parts = [for (var i = 1; i <= 6; i++) int.tryParse(m.group(i) ?? '0') ?? 0];
    return m.group(7) == 'Z'
        ? DateTime.utc(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]).toLocal()
        : DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
  }

  String write(List<ShopEvent> events) {
    String fmt(DateTime d) {
      final u = d.toUtc();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${u.year}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    }

    String esc(String s) => s.replaceAll(',', r'\,').replaceAll('\n', r'\n');
    final b = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Pop-Up Pass//EN');
    for (final e in events) {
      b
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${e.id}@popuppass')
        ..writeln('DTSTAMP:${fmt(DateTime.now())}')
        ..writeln('DTSTART:${fmt(e.startsAt)}')
        ..writeln('DTEND:${fmt(e.endsAt)}')
        ..writeln('SUMMARY:${esc(e.name)}');
      final where = [e.boothLabel, e.venue, e.city].whereType<String>().join(', ');
      if (where.isNotEmpty) b.writeln('LOCATION:${esc(where)}');
      b.writeln('END:VEVENT');
    }
    b.writeln('END:VCALENDAR');
    return b.toString();
  }
}

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
