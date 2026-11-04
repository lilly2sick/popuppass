import '../../data/db/database.dart';

/// A list of upcoming cons the user can browse. Unlike the other connectors
/// nothing is stored until the user taps Add, so this is a read-only source
/// instead of a [Connector]; the add goes through `EventRepo.importAll`, which
/// dedupes on (source, externalId).
abstract interface class ConSource {
  String get id;

  /// Credit line shown above the list.
  String get attribution;

  Future<List<EventsCompanion>> upcoming();
}
