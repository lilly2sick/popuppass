import '../l10n/app_localizations.dart';

// Enums stored by name in SQLite (drift textEnum) and in Postgres
// (check constraints). Renaming a value is a migration.

enum PaymentMethod {
  cash('Cash'),
  card('Card'),
  zelle('Zelle'),
  venmo('Venmo'),
  cashapp('Cash App'),
  paypal('PayPal'),
  other('Other');

  const PaymentMethod(this.label);

  /// Stable English name used in exports and data files.
  final String label;

  /// Name shown to the user.
  String localized(AppLocalizations l10n) => switch (this) {
    PaymentMethod.cash => l10n.paymentCash,
    PaymentMethod.card => l10n.paymentCard,
    PaymentMethod.zelle => l10n.paymentZelle,
    PaymentMethod.venmo => l10n.paymentVenmo,
    PaymentMethod.cashapp => l10n.paymentCashapp,
    PaymentMethod.paypal => l10n.paymentPaypal,
    PaymentMethod.other => l10n.paymentOther,
  };
}

/// Where a record came from. Imported rows also carry an externalId so
/// re-importing never double counts.
enum RecordSource { manual, square, csv, animecons, ics }

enum MoveReason { restock, sale, adjust, voided }

enum AiJobKind { caption, hashtags, eventSummary, restockIdeas }

enum JobStatus { queued, running, done, failed }

enum SyncOp { upsert, delete }
