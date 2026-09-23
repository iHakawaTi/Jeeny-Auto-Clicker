/// Build-time environment configuration.
///
/// All values here are provided via `--dart-define` (or `--dart-define-from-file=.env`)
/// at build time. Nothing is baked in from source — the repo stays free of
/// project-specific Supabase credentials so anyone can fork it.
///
/// Local development / release:
///   flutter run   --dart-define-from-file=.env
///   flutter build apk --release --dart-define-from-file=.env
///
/// See `.env.example` at the project root for the required variables.
class Env {
  const Env._();

  /// Base URL of the Supabase project, e.g. https://xxxx.supabase.co
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Supabase anon (publishable) key. Safe to ship in client binaries —
  /// Row Level Security policies are what actually protect data.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True only when both required values were supplied at build time.
  /// When false, the app falls back to a preview mode that shows the
  /// UI with mock data — useful for designing without a live backend.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
