/// Compile-time environment configuration.
///
/// Pass values at build time with --dart-define:
///   flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// Falls back to the hard-coded dev values so the app still launches without
/// --dart-define during local development.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wsjcjeasiwxlsrqaxkem.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndzamNqZWFzaXd4bHNycWF4a2VtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODQwODksImV4cCI6MjA5MzE2MDA4OX0.Q_zT3vXwYLHHGpN-eFGeY441JsVBoyQptLeSFlrpsgc',
  );

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  static bool get isDevelopment => environment == 'development';
}
