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

/// SPEC 16: how often the recommendation schedule delivers fresh cards.
/// Off disables the local notification entirely.
enum RecommendationFrequency {
  off,
  daily,
  weekly,
  biweekly;

  /// Default per SPEC 16.
  static const defaultValue = RecommendationFrequency.weekly;

  /// Days between notifications; null when off.
  int? get intervalDays => switch (this) {
    RecommendationFrequency.off => null,
    RecommendationFrequency.daily => 1,
    RecommendationFrequency.weekly => 7,
    RecommendationFrequency.biweekly => 14,
  };

  String localized(AppLocalizations l10n) => switch (this) {
    RecommendationFrequency.off => l10n.recommendationFrequencyOff,
    RecommendationFrequency.daily => l10n.recommendationFrequencyDaily,
    RecommendationFrequency.weekly => l10n.recommendationFrequencyWeekly,
    RecommendationFrequency.biweekly => l10n.recommendationFrequencyBiweekly,
  };
}
