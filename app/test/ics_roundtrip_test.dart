import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/connectors/events/ics_codec.dart';
import 'package:popup_pass/connectors/events/ics_connector.dart';
import 'package:popup_pass/data/db/database.dart';

import 'support/repos.dart';

void main() {
  test('IcsCodec parses folded lines and UTC dates', () {
    const ics =
        'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:abc\r\nSUMMARY:Anime\r\n  Fest\r\n'
        'DTSTART:20261106T170000Z\r\nDTEND:20261108T020000Z\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';
    const codec = IcsCodec();
    final events = codec.parse(ics);
    expect(events, hasLength(1));
    expect(events.first['SUMMARY'], 'Anime Fest');
    expect(codec.parseDate(events.first['DTSTART'])!.toUtc(), DateTime.utc(2026, 11, 6, 17));
  });

  test('events survive export then import, and re-import adds nothing', () async {
    final a = TestRepos();
    final b = TestRepos();
    addTearDown(a.close);
    addTearDown(b.close);
    final start = DateTime.utc(2026, 11, 6, 17);
    final end = DateTime.utc(2026, 11, 8, 2);
    await a.events.save(
      EventsCompanion.insert(
        name: 'Anime Fest, Oakland',
        startsAt: start,
        endsAt: end,
        venue: const Value('Convention Center'),
      ),
    );

    final text = const IcsCodec().write(await a.events.watchAll().first);
    IcsConnector connector() => IcsConnector(b.cursors, b.events);

    final first = await (connector()..pendingText = text).ingest();
    expect(first.added, 1);
    final imported = (await b.events.watchAll().first).single;
    expect(imported.name, 'Anime Fest, Oakland');
    expect(imported.startsAt.toUtc(), start);
    expect(imported.endsAt.toUtc(), end);

    final second = await (connector()..pendingText = text).ingest();
    expect(second.added, 0);
    expect(await b.events.watchAll().first, hasLength(1));
  });
}
