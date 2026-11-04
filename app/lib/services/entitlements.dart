/// Everything gated by plan. The server enforces the same rules (RLS and
/// the `ai` function); this class only decides what the UI offers.
enum Feature {
  cloudBackup,
  aiCaption,
  aiHashtags,
  aiSummary,
  aiRestock,
  trendAlerts,
  exportPdf,
  exportXlsx,
}

class Entitlements {
  const Entitlements({required this.isPro});

  static const free = Entitlements(isPro: false);

  final bool isPro;

  static const _free = <Feature>{};

  bool can(Feature f) => isPro || _free.contains(f);
}
