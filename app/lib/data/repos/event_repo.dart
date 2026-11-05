import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/database.dart';
import 'repository.dart';

class EventRepo extends Repository<ShopEvent> {
  EventRepo(super.db, super.tracker, super.deviceId);

  @override
  String get entity => 'events';

  @override
  Stream<List<ShopEvent>> watchAll() =>
      (db.select(db.events)
            ..where((e) => e.deleted.equals(false))
            ..orderBy([(e) => OrderingTerm.asc(e.startsAt)]))
          .watch();

  @override
  Future<ShopEvent?> byId(String id) =>
      (db.select(db.events)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// The live event, else the next upcoming one, else the most recent.
  Stream<ShopEvent?> watchCurrent({DateTime? now}) => watchAll().map((events) {
    final t = now ?? clock.now();
    for (final e in events) {
      if (!t.isBefore(e.startsAt) && !t.isAfter(e.endsAt)) return e;
    }
    for (final e in events) {
      if (e.startsAt.isAfter(t)) return e;
    }
    return events.isEmpty ? null : events.last;
  });

  Future<String> save(EventsCompanion data) async {
    final id = data.id.present ? data.id.value : makeId();
    await db
        .into(db.events)
        .insertOnConflictUpdate(
          data.copyWith(id: Value(id), updatedAt: Value(clock.now()), deviceId: Value(deviceId)),
        );
    await touched(id);
    return id;
  }

  /// Upsert by (source, externalId) so feeds and .ics files can be re-imported.
  Future<int> importAll(List<EventsCompanion> incoming) async {
    var added = 0;
    await db.transaction(() async {
      for (final e in incoming) {
        final existing =
            await (db.select(db.events)..where(
                  (x) =>
                      x.source.equalsValue(e.source.value) &
                      x.externalId.equals(e.externalId.value!),
                ))
                .getSingleOrNull();
        if (existing == null) added++;
        await save(existing == null ? e : e.copyWith(id: Value(existing.id)));
      }
    });
    return added;
  }

  @override
  Future<void> softDelete(String id) async {
    await (db.update(db.events)..where((e) => e.id.equals(id))).write(
      EventsCompanion(deleted: const Value(true), updatedAt: Value(clock.now())),
    );
    await touched(id, SyncOp.delete);
  }
}
