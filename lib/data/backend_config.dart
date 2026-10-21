// Public client configuration. Access is enforced by Supabase Auth and RLS.
abstract final class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://mqpcxptgmqzwylldiotr.supabase.co');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_h8IsP__HWpL3WTgDouIyCw_iieVynm6');
}
