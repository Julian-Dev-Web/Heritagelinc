// lib/features/trips/data/saved_trip_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown for any failure the UI should surface to the user.
class TripFailure implements Exception {
  const TripFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

enum TripMode {
  jeepney('jeepney', 'Jeepney', Icons.airport_shuttle_rounded),
  bus('bus', 'Bus', Icons.directions_bus_rounded),
  uvExpress('uv_express', 'UV Express', Icons.local_taxi_rounded),
  tricycle('tricycle', 'Tricycle', Icons.electric_rickshaw_rounded);

  const TripMode(this.dbValue, this.label, this.icon);

  final String dbValue;
  final String label;
  final IconData icon;

  static TripMode fromDb(String? value) => TripMode.values.firstWhere(
    (m) => m.dbValue == value,
    orElse: () => TripMode.jeepney,
  );
}

class SavedTrip {
  const SavedTrip({
    required this.id,
    required this.label,
    required this.origin,
    required this.destination,
    required this.mode,
    required this.isFavorite,
    required this.createdAt,
    this.estimatedFare,
    this.notes,
  });

  final String id;
  final String label;
  final String origin;
  final String destination;
  final TripMode mode;
  final bool isFavorite;
  final DateTime createdAt;
  final double? estimatedFare;
  final String? notes;

  String get routeLabel => '$origin → $destination';

  String get fareLabel =>
      estimatedFare == null ? '—' : '₱${estimatedFare!.toStringAsFixed(2)}';

  factory SavedTrip.fromMap(Map<String, dynamic> map) {
    return SavedTrip(
      id: map['id'] as String,
      label: (map['label'] ?? '') as String,
      origin: (map['origin'] ?? '') as String,
      destination: (map['destination'] ?? '') as String,
      mode: TripMode.fromDb(map['mode'] as String?),
      isFavorite: (map['is_favorite'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '') as String) ??
          DateTime.now(),
      estimatedFare: (map['estimated_fare'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }
}

/// Full CRUD against `public.saved_trips`.
///
/// Every method relies on Row Level Security rather than filtering by user
/// in the query. The policies key on auth.uid(), so a request can only ever
/// touch the caller's own rows even if the client were modified.
class SavedTripService {
  SavedTripService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'saved_trips';

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const TripFailure('You are not signed in.');
    return id;
  }

  // ------------------------------------------------------------- CREATE

  Future<SavedTrip> create({
    required String label,
    required String origin,
    required String destination,
    required TripMode mode,
    double? estimatedFare,
    String? notes,
  }) async {
    try {
      final row = await _client
          .from(_table)
          .insert({
            'profile_id': _uid,
            'label': label.trim(),
            'origin': origin.trim(),
            'destination': destination.trim(),
            'mode': mode.dbValue,
            'estimated_fare': estimatedFare,
            'notes': _blankToNull(notes),
          })
          .select()
          .single();

      return SavedTrip.fromMap(row);
    } on PostgrestException catch (e) {
      throw TripFailure(_mapError(e));
    }
  }

  // --------------------------------------------------------------- READ

  Future<List<SavedTrip>> fetchAll({bool favoritesFirst = true}) async {
    try {
      final query = _client.from(_table).select();

      final rows = favoritesFirst
          ? await query
                .order('is_favorite', ascending: false)
                .order('created_at', ascending: false)
          : await query.order('created_at', ascending: false);

      return (rows as List)
          .map((r) => SavedTrip.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw TripFailure(_mapError(e));
    }
  }

  Future<SavedTrip?> fetchById(String id) async {
    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      return row == null ? null : SavedTrip.fromMap(row);
    } on PostgrestException catch (e) {
      throw TripFailure(_mapError(e));
    }
  }

  /// Simple text filter across label, origin, and destination.
  Future<List<SavedTrip>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return fetchAll();

    try {
      final rows = await _client
          .from(_table)
          .select()
          .or('label.ilike.%$q%,origin.ilike.%$q%,destination.ilike.%$q%')
          .order('created_at', ascending: false);

      return (rows as List)
          .map((r) => SavedTrip.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw TripFailure(_mapError(e));
    }
  }

  // ------------------------------------------------------------- UPDATE

  Future<SavedTrip> update({
    required String id,
    String? label,
    String? origin,
    String? destination,
    TripMode? mode,
    double? estimatedFare,
    String? notes,
    bool? isFavorite,
  }) async {
    final changes = <String, dynamic>{
      if (label != null) 'label': label.trim(),
      if (origin != null) 'origin': origin.trim(),
      if (destination != null) 'destination': destination.trim(),
      if (mode != null) 'mode': mode.dbValue,
      if (estimatedFare != null) 'estimated_fare': estimatedFare,
      if (notes != null) 'notes': _blankToNull(notes),
      if (isFavorite != null) 'is_favorite': isFavorite,
    };

    if (changes.isEmpty) {
      throw const TripFailure('Nothing to update.');
    }

    try {
      final row = await _client
          .from(_table)
          .update(changes)
          .eq('id', id)
          .select()
          .single();

      return SavedTrip.fromMap(row);
    } on PostgrestException catch (e) {
      throw TripFailure(_mapError(e));
    }
  }

  Future<SavedTrip> toggleFavorite(SavedTrip trip) =>
      update(id: trip.id, isFavorite: !trip.isFavorite);

  // ------------------------------------------------------------- DELETE

  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw TripFailure(_mapError(e));
    }
  }

  // ------------------------------------------------------------ helpers

  String? _blankToNull(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  String _mapError(PostgrestException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('saved_trips_unique_per_user') ||
        msg.contains('duplicate key')) {
      return 'You already have a saved trip with that name.';
    }
    if (msg.contains('saved_trips_label_len')) {
      return 'The trip name must be between 1 and 60 characters.';
    }
    if (msg.contains('saved_trips_fare_positive')) {
      return 'The fare cannot be negative.';
    }
    if (msg.contains('saved_trips_mode_valid')) {
      return 'That transport mode is not recognised.';
    }
    if (msg.contains('row-level security') || msg.contains('permission')) {
      return 'You do not have permission to change this trip.';
    }
    if (msg.contains('failed host lookup') || msg.contains('socket')) {
      return 'No connection. Your changes will need to be made again online.';
    }
    return 'Could not save your changes. ${e.message}';
  }
}