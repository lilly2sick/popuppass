/// Build-time configuration. Pass values with --dart-define; never commit keys.
///
/// When [useFakes] is true (the default) every connector uses its Fake*
/// implementation and the app runs fully offline with sample data.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatAppleKey,
    required this.revenueCatGoogleKey,
    required this.squareAppId,
    required this.metaAppId,
    required this.useFakes,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    revenueCatAppleKey: String.fromEnvironment('RC_APPLE_KEY'),
    revenueCatGoogleKey: String.fromEnvironment('RC_GOOGLE_KEY'),
    squareAppId: String.fromEnvironment('SQUARE_APP_ID'),
    metaAppId: String.fromEnvironment('META_APP_ID'),
    useFakes: bool.fromEnvironment('USE_FAKES', defaultValue: true),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatAppleKey;
  final String revenueCatGoogleKey;
  final String squareAppId;

  /// Meta app id for direct Instagram/Facebook share intents. Empty until a
  /// human registers one; social targets fall back to the system share sheet.
  final String metaAppId;
  final bool useFakes;

  bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Direct Instagram/Facebook intents need a registered Meta app id.
  bool get hasMetaApp => metaAppId.isNotEmpty;
}
