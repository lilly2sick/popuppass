import '../data/db/database.dart';
import '../data/repos/sales_repo.dart';
import 'enums.dart';

class ProductStats {
  ProductStats(this.productId, this.name);

  final String? productId;
  final String name;
  int units = 0;
  int grossCents = 0;
  int costCents = 0;
  DateTime? firstSold;
  DateTime? lastSold;
  final hourly = List<int>.filled(24, 0);

  int get profitCents => grossCents - costCents;
  double get margin => grossCents == 0 ? 0 : profitCents / grossCents;
}

class EventReport {
  EventReport({required this.boothFeeCents});

  final int boothFeeCents;
  int grossCents = 0;
  int costCents = 0;
  int units = 0;
  final byProduct = <String, ProductStats>{};
  final byMethod = <PaymentMethod, int>{};

  int get netCents => grossCents - costCents - boothFeeCents;

  List<ProductStats> get ranked =>
      byProduct.values.toList()..sort((a, b) => b.profitCents.compareTo(a.profitCents));
  ProductStats? get best => ranked.isEmpty ? null : ranked.first;
  ProductStats? get worst => ranked.length < 2 ? null : ranked.last;
}

/// All numbers are computed on device. AI only ever writes words about them.
class AnalyticsService {
  AnalyticsService(this.sales);

  final SalesRepo sales;

  Future<EventReport> report({
    ShopEvent? event,
    DateTime? from,
    DateTime? to,
    Map<String, String> names = const {},
  }) async {
    final rows = await sales.linesFor(eventId: event?.id, from: from, to: to);
    final r = EventReport(boothFeeCents: event?.boothFeeCents ?? 0);
    for (final (sale, line) in rows) {
      final gross = line.unitPriceCents * line.qty;
      final cost = line.unitCostCents * line.qty;
      r
        ..grossCents += gross
        ..costCents += cost
        ..units += line.qty;
      r.byMethod.update(sale.paymentMethod, (v) => v + gross, ifAbsent: () => gross);

      final key = line.productId ?? 'unmatched:${line.externalName}';
      final p = r.byProduct.putIfAbsent(
        key,
        () => ProductStats(
          line.productId,
          names[line.productId] ?? line.externalName ?? 'Unmatched item',
        ),
      );
      p
        ..units += line.qty
        ..grossCents += gross
        ..costCents += cost
        ..hourly[sale.soldAt.hour] += line.qty;
      if (p.firstSold == null || sale.soldAt.isBefore(p.firstSold!)) p.firstSold = sale.soldAt;
      if (p.lastSold == null || sale.soldAt.isAfter(p.lastSold!)) p.lastSold = sale.soldAt;
    }
    return r;
  }
}
