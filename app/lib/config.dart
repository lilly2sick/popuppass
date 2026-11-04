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
    required this.useFakes,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    revenueCatAppleKey: String.fromEnvironment('RC_APPLE_KEY'),
    revenueCatGoogleKey: String.fromEnvironment('RC_GOOGLE_KEY'),
    squareAppId: String.fromEnvironment('SQUARE_APP_ID'),
    useFakes: bool.fromEnvironment('USE_FAKES', defaultValue: true),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatAppleKey;
  final String revenueCatGoogleKey;
  final String squareAppId;
  final bool useFakes;

  bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
