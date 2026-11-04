import '../../domain/enums.dart';
import '../db/database.dart';
import '../db/tables.dart' show newId;

export '../db/tables.dart' show newId;

/// Receives every local write so Pro users can push it to the cloud.
/// Free users get [NoopChangeTracker]; nothing leaves the phone.
abstract interface class ChangeTracker {
  Future<void> record(String entity, String rowId, SyncOp op);
}

class NoopChangeTracker implements ChangeTracker {
  const NoopChangeTracker();
  @override
  Future<void> record(String entity, String rowId, SyncOp op) async {}
}

/// Base for every repository: owns the database handle, the device id and
/// change tracking. Subclasses expose typed queries for one aggregate.
abstract class Repository<T> {
  Repository(this.db, this.tracker, this.deviceId);

  final AppDatabase db;
  final ChangeTracker tracker;
  final String deviceId;

  /// Cloud table name, used by the sync outbox.
  String get entity;

  Stream<List<T>> watchAll();
  Future<T?> byId(String id);
  Future<void> softDelete(String id);

  Future<void> touched(String id, [SyncOp op = SyncOp.upsert]) => tracker.record(entity, id, op);

  String makeId() => newId();
}
