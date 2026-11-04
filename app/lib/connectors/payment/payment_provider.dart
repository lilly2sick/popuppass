import '../../data/repos/sales_repo.dart';
import '../connector.dart';

/// Raw payment as a provider reports it, before mapping to our model.
class ExternalPayment {
  const ExternalPayment({required this.id, required this.createdAt, required this.json});

  final String id;
  final DateTime createdAt;
  final Map<String, dynamic> json;
}

/// Base for card-reader / payment providers. Square first; Stripe, SumUp,
/// PayPal later are one subclass each.
abstract class PaymentProvider extends Connector<ExternalPayment, ImportedSale> {
  PaymentProvider(super.cursors, this.sales);

  final SalesRepo sales;

  /// Human name for settings.
  String get displayName;

  Future<bool> get isConnected;

  /// Runs the provider's OAuth flow. Tokens end up in secure storage.
  Future<void> connect();

  Future<void> disconnect();

  /// Event to attach imported sales to (the live event, if any).
  String? eventId;

  @override
  Future<int> sink(List<ImportedSale> models) => sales.importSales(models, eventId: eventId);

  @override
  String? nextCursor(List<ExternalPayment> raws, String? previous) {
    if (raws.isEmpty) return previous;
    final latest = raws.map((r) => r.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.toUtc().toIso8601String();
  }
}
