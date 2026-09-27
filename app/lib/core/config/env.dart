/// Compile-time configuration, passed via `--dart-define` (see `.env.example`
/// at the repo root for the values and README.md for the run command).
/// The anon key is safe to ship in the client — Supabase RLS is what
/// actually protects data, not secrecy of this key.
class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
