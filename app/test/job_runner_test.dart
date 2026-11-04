import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/connectors/ai/ai_provider.dart';
import 'package:popup_pass/data/db/database.dart';
import 'package:popup_pass/domain/enums.dart';
import 'package:popup_pass/services/job_runner.dart';

class _FailingAi implements AiProvider {
  _FailingAi(this.error);
  final Object error;
  int calls = 0;

  @override
  Future<String> run(AiJobKind kind, Map<String, dynamic> input) async {
    calls++;
    throw error;
  }
}

DioException _http(int status) {
  final req = RequestOptions(path: '/ai');
  return DioException(
    requestOptions: req,
    response: Response<dynamic>(requestOptions: req, statusCode: status),
    type: DioExceptionType.badResponse,
  );
}

Future<AiJob> _runOnce(Object error) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final ai = _FailingAi(error);
  final runner = JobRunner(db, ai);
  // Insert directly: enqueue() starts its own unawaited drain, which would race this one.
  const id = 'job-1';
  await db
      .into(db.aiJobs)
      .insert(
        AiJobsCompanion.insert(
          id: const Value(id),
          kind: AiJobKind.caption,
          input: '{"product":"Print"}',
        ),
      );
  await runner.drain();
  return (db.select(db.aiJobs)..where((j) => j.id.equals(id))).getSingle();
}

void main() {
  test('403 pro_required is terminal: failed with attempts exhausted', () async {
    final job = await _runOnce(_http(403));
    expect(job.status, JobStatus.failed);
    expect(job.attempts, JobRunner.maxAttempts);
  });

  test('422 declined is terminal', () async {
    final job = await _runOnce(_http(422));
    expect(job.attempts, JobRunner.maxAttempts);
  });

  test('5xx is retried with one attempt counted', () async {
    final job = await _runOnce(_http(503));
    expect(job.status, JobStatus.failed);
    expect(job.attempts, 1);
  });

  test('429 and network errors are retried', () async {
    expect((await _runOnce(_http(429))).attempts, 1);
    final net = DioException(
      requestOptions: RequestOptions(path: '/ai'),
      type: DioExceptionType.connectionError,
    );
    expect((await _runOnce(net)).attempts, 1);
  });
}
