/// Enums stored by name in SQLite (drift textEnum) and in Postgres
/// (check constraints). Renaming a value is a migration.

enum PaymentMethod {
  cash('Cash'),
  card('Card'),
  zelle('Zelle'),
  venmo('Venmo'),
  cashapp('Cash App'),
  paypal('PayPal'),
  other('Other');

  const PaymentMethod(this.label);
  final String label;
}

/// Where a record came from. Imported rows also carry an externalId so
/// re-importing never double counts.
enum RecordSource { manual, square, csv, animecons, ics }

enum MoveReason { restock, sale, adjust, voided }

enum AiJobKind { caption, hashtags, eventSummary, restockIdeas }

enum JobStatus { queued, running, done, failed }

enum SyncOp { upsert, delete }
