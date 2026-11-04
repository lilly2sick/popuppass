import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';

const _uuid = Uuid();
String newId() => _uuid.v7();

/// Columns every syncable row carries. Mirrors the cloud tables
/// (which add user_id).
mixin Syncable on Table {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text().nullable()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromDb) => (jsonDecode(fromDb) as List).cast<String>();
  @override
  String toSql(List<String> value) => jsonEncode(value);
}

// ---------- syncable ----------

@DataClassName('ShopEvent')
class Events extends Table with Syncable {
  TextColumn get name => text()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  TextColumn get venue => text().nullable()();
  TextColumn get city => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  IntColumn get boothFeeCents => integer().withDefault(const Constant(0))();
  TextColumn get boothLabel => text().nullable()();
  TextColumn get source => textEnum<RecordSource>().withDefault(Constant(RecordSource.manual.name))();
  TextColumn get externalId => text().nullable()();
}

class Products extends Table with Syncable {
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  IntColumn get priceCents => integer()();

  /// Manual unit cost. When BOM lines exist, the BOM total wins.
  IntColumn get unitCostCents => integer().withDefault(const Constant(0))();
  IntColumn get minutesToMake => integer().nullable()();
  TextColumn get tags => text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get photoPaths => text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(3))();
  TextColumn get squareItemId => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

class BomLines extends Table with Syncable {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get material => text()();
  RealColumn get qty => real().withDefault(const Constant(1))();
  TextColumn get unit => text().nullable()();
  IntColumn get costCents => integer()();
}

/// Append-only ledger. Voids are a soft delete plus a `voided` move.
class Sales extends Table with Syncable {
  TextColumn get eventId => text().nullable().references(Events, #id)();
  DateTimeColumn get soldAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();
  TextColumn get source => textEnum<RecordSource>().withDefault(Constant(RecordSource.manual.name))();
  TextColumn get externalId => text().nullable()();
  IntColumn get totalCents => integer()();
  TextColumn get note => text().nullable()();
}

class SaleLines extends Table with Syncable {
  TextColumn get saleId => text().references(Sales, #id)();

  /// Null until an imported line is matched to a product.
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get externalName => text().nullable()();
  IntColumn get qty => integer()();
  IntColumn get unitPriceCents => integer()();

  /// Snapshot at sale time so later cost edits do not rewrite history.
  IntColumn get unitCostCents => integer()();
}

/// Append-only. Stock = SUM(delta).
class InventoryMoves extends Table with Syncable {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get eventId => text().nullable().references(Events, #id)();
  IntColumn get delta => integer()();
  TextColumn get reason => textEnum<MoveReason>()();
  TextColumn get saleLineId => text().nullable().references(SaleLines, #id)();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}

class Brands extends Table with Syncable {
  TextColumn get shopName => text()();
  TextColumn get handle => text().nullable()();
  TextColumn get colors => text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get logoPath => text().nullable()();
  TextColumn get boothLabel => text().nullable()();
  TextColumn get nicheTags => text().map(const StringListConverter()).withDefault(const Constant('[]'))();
}

@DataClassName('PricePoint')
class PriceHistory extends Table with Syncable {
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get priceCents => integer()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}

// ---------- local only ----------

class AiJobs extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get kind => textEnum<AiJobKind>()();
  TextColumn get input => text()(); // json
  TextColumn get status => textEnum<JobStatus>().withDefault(Constant(JobStatus.queued.name))();
  TextColumn get result => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OutboxEntry')
class SyncOutbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entity => text()(); // cloud table name

  TextColumn get rowId => text()();
  TextColumn get op => textEnum<SyncOp>()();
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
}

class ConnectorCursors extends Table {
  TextColumn get connectorId => text()();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get lastRunAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {connectorId};
}

@DataClassName('CachedTrend')
class TrendCache extends Table {
  TextColumn get id => text()();
  TextColumn get keyword => text()();
  TextColumn get niche => text()();
  RealColumn get score => real()();
  TextColumn get title => text()();
  TextColumn get why => text()();
  TextColumn get itemIdea => text().nullable()();
  TextColumn get sources => text().map(const StringListConverter())();
  TextColumn get snapshotVersion => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('Swipe')
class SwipeFeedback extends Table {
  TextColumn get trendId => text()();
  BoolColumn get liked => boolean()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {trendId};
}
