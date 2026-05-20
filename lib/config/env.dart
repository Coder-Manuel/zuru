import 'dart:developer';

enum Environment { staging, prod }

abstract class Env {
  static Environment env = Environment.staging;
  static bool get isProd => env == Environment.prod;

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseURL = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // ── Firebase ──────────────────────────────────────────────────────────────
  static const String fbIosApiKey = String.fromEnvironment('FB_IOS_API_KEY');
  static const String fbAndroidApiKey =
      String.fromEnvironment('FB_ANDROID_API_KEY');

  // ── Analytics ─────────────────────────────────────────────────────────────
  static const String mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');

  // ── Google Maps (client role — location picker) ───────────────────────────
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static void init() {
    const envString = String.fromEnvironment('env', defaultValue: 'staging');
    env = Environment.values.firstWhere(
      (v) => v.name == envString.toLowerCase(),
      orElse: () => Environment.staging,
    );
    log('==== Env Initialized [${env.name}]');
  }
}
