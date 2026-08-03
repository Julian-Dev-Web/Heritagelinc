// lib/features/auth/data/school_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/auth_models.dart';

class SchoolService {
  SchoolService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Restricts the picker to the pilot province. Set to null to search
  /// nationwide once the full DepEd and CHED lists are imported.
  static const String? provinceFilter = 'Bulacan';

  final Map<String, List<School>> _cache = {};

  /// Calls the `search_schools` RPC. Readable by anon, so this works on
  /// the signup form before the user has a session.
  Future<List<School>> search(String query, {int limit = 20}) async {
    final q = query.trim();
    final cacheKey = '$q|$limit';

    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      final rows = await _client.rpc(
        'search_schools',
        params: {
          'q': q,
          'province_filter': provinceFilter,
          'max_results': limit,
        },
      );

      final results = (rows as List)
          .map((r) => School.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();

      // Keep the cache small — this is a signup form, not a browser.
      if (_cache.length > 30) _cache.clear();
      _cache[cacheKey] = results;

      return results;
    } on PostgrestException catch (e) {
      throw AuthFailure('Could not load schools. ${e.message}');
    } catch (_) {
      throw const AuthFailure(
        'Could not load schools. Please check your connection.',
      );
    }
  }

  /// The first page shown when the picker opens, before any typing.
  Future<List<School>> initial({int limit = 20}) => search('', limit: limit);

  Future<School?> findById(String id) async {
    try {
      final row = await _client
          .from('schools')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return School.fromMap(row);
    } on PostgrestException {
      return null;
    }
  }

  void clearCache() => _cache.clear();
}