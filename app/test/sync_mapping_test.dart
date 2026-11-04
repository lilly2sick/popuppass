import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/services/sync_mapping.dart';

void main() {
  test('local rows become cloud rows: bools, JSON lists, ISO timestamps', () {
    final cloud = SyncMapping.toCloud({
      'id': 'p1',
      'deleted': 0,
      'archived': 1,
      'tags': '["holo","cat"]',
      'updated_at': 1793988000,
      'price_cents': 700,
      'note': null,
    });
    expect(cloud['deleted'], false);
    expect(cloud['archived'], true);
    expect(cloud['tags'], ['holo', 'cat']);
    expect(cloud['updated_at'], '2026-11-06T18:00:00.000Z');
    expect(cloud['price_cents'], 700);
    expect(cloud['note'], isNull);
  });

  test('cloud rows become local rows and drop user_id', () {
    final local = SyncMapping.toLocal({
      'id': 'p1',
      'user_id': 'u1',
      'deleted': true,
      'tags': ['holo'],
      'updated_at': '2026-11-06T18:00:00Z',
    });
    expect(local.containsKey('user_id'), isFalse);
    expect(local['deleted'], 1);
    expect(local['tags'], '["holo"]');
    expect(local['updated_at'], 1793988000);
  });

  test('round trip is lossless', () {
    final row = {'id': 'x', 'deleted': 1, 'tags': '["a"]', 'created_at': 1700000000};
    final back = SyncMapping.toLocal(SyncMapping.toCloud(row));
    expect(back['deleted'], 1);
    expect(back['tags'], '["a"]');
    expect(back['created_at'], 1700000000);
  });
}
