import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase initialization and gives the rest of the app a single,
/// safe access point to the client. Keys come from .env — never commit
/// real keys to source control.
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'Missing Supabase credentials. Check that .env exists and '
        'contains SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Access the Supabase client from anywhere via SupabaseService.client
  static SupabaseClient get client => Supabase.instance.client;
}