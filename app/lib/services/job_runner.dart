import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../connectors/ai/ai_provider.dart';
import '../data/db/database.dart';
import '../data/db/tables.dart' show newId;
import '../domain/enums.dart';

/// Drains the local `ai_jobs` queue. Nothing in the UI ever awaits this:
/// screens show the local template result right away and swap in the AI
/// version when its job row flips to `done`.
///
/// Runs on app start, when connectivity returns, and every minute while
/// foregrounded. Does not rely on iOS background execution.
class JobRunner {
  JobRunner(this.db, this.ai, {Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final AppDatabase db;
  final AiProvider ai;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;
  bool _draining = false;

  static const maxAttempts = 5;

  void start() {
    _sub = _connectivity.onConnectivityChanged.listen((r) {
      if (!r.contains(ConnectivityResult.none)) drain();
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => drain());
    drain();
  }

  void stop() {
    _sub?.cancel();
    _timer?.cancel();
  }

  Future<String> enqueue(AiJobKind kind, Map<String, dynamic> input) async {
    final id = newId();
    await db.into(db.aiJobs).insert(AiJobsCompanion.insert(id: Value(id), kind: kind, input: jsonEncode(input)));
    unawaited(drain());
    return id;
  }

  Stream<AiJob?> watch(String id) => (db.select(db.aiJobs)..where((j) => j.id.equals(id))).watchSingleOrNull();

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final due = await (db.select(db.aiJobs)
            ..where((j) =>
                j.status.isIn([JobStatus.queued.name, JobStatus.failed.name]) &
                j.attempts.isSmallerThanValue(maxAttempts) &
                j.nextAttemptAt.isSmallerOrEqualValue(DateTime.now()))
            ..orderBy([(j) => OrderingTerm.asc(j.createdAt)])
            ..limit(10))
          .get();
      for (final job in due) {
        await _run(job);
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _run(AiJob job) async {
    final q = db.update(db.aiJobs)..where((j) => j.id.equals(job.id));
    await q.write(const AiJobsCompanion(status: Value(JobStatus.running)));
    try {
      final text = await ai.run(job.kind, jsonDecode(job.input) as Map<String, dynamic>);
      await q.write(AiJobsCompanion(status: const Value(JobStatus.done), result: Value(text)));
    } catch (_) {
      final attempts = job.attempts + 1;
      await q.write(AiJobsCompanion(
        status: const Value(JobStatus.failed),
        attempts: Value(attempts),
        nextAttemptAt: Value(DateTime.now().add(Duration(seconds: 30 * (1 << attempts)))),
      ));
    }
  }
}
