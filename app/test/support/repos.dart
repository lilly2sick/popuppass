import 'package:drift/native.dart';
import 'package:popup_pass/connectors/sync_cursor.dart';
import 'package:popup_pass/data/db/database.dart';
import 'package:popup_pass/data/repos/event_repo.dart';
import 'package:popup_pass/data/repos/inventory_repo.dart';
import 'package:popup_pass/data/repos/product_repo.dart';
import 'package:popup_pass/data/repos/repository.dart';
import 'package:popup_pass/data/repos/sales_repo.dart';
import 'package:popup_pass/domain/analytics_service.dart';

/// Repositories over an in-memory database, no widgets and no Riverpod.
class TestRepos {
  TestRepos() : db = AppDatabase(NativeDatabase.memory()) {
    const tracker = NoopChangeTracker();
    products = ProductRepo(db, tracker, 'test-device');
    inventory = InventoryRepo(db, tracker, 'test-device');
    events = EventRepo(db, tracker, 'test-device');
    sales = SalesRepo(db, tracker, 'test-device', products, inventory);
    cursors = SyncCursor(db);
    analytics = AnalyticsService(sales);
  }

  final AppDatabase db;
  late final ProductRepo products;
  late final InventoryRepo inventory;
  late final EventRepo events;
  late final SalesRepo sales;
  late final SyncCursor cursors;
  late final AnalyticsService analytics;

  Future<void> close() => db.close();
}
