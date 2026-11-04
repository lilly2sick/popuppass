import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/enums.dart';
import 'tables.dart';

part 'database.g.dart';

/// The on-device source of truth. Run `dart run build_runner build` after
/// changing any table.
@DriftDatabase(
  tables: [
    Events,
    Products,
    BomLines,
    Sales,
    SaleLines,
    InventoryMoves,
    Brands,
    PriceHistory,
    AiJobs,
    SyncOutbox,
    ConnectorCursors,
    TrendCache,
    SwipeFeedback,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'popup_pass'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE UNIQUE INDEX sales_source_external ON sales (source, external_id) WHERE external_id IS NOT NULL',
          );
          await customStatement(
            'CREATE UNIQUE INDEX events_source_external ON events (source, external_id) WHERE external_id IS NOT NULL',
          );
          await customStatement('CREATE INDEX moves_product ON inventory_moves (product_id)');
          await customStatement('CREATE INDEX sales_event ON sales (event_id, sold_at)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
