// lib/features/transit/data/transit_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransitFailure implements Exception {
  const TransitFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

enum TransitMode {
  jeepney('jeepney', 'Jeepney', Icons.airport_shuttle_rounded),
  bus('bus', 'Bus', Icons.directions_bus_rounded),
  uvExpress('uv_express', 'UV Express', Icons.local_taxi_rounded),
  tricycle('tricycle', 'Tricycle', Icons.electric_rickshaw_rounded);

  const TransitMode(this.dbValue, this.label, this.icon);

  final String dbValue;
  final String label;
  final IconData icon;

  static TransitMode fromDb(String? value) => TransitMode.values.firstWhere(
    (m) => m.dbValue == value,
    orElse: () => TransitMode.jeepney,
  );
}

/// Who is riding. Students, senior citizens, and PWDs are entitled to a
/// fare discount of not less than 20% on presentation of a valid ID.
enum PassengerType {
  regular('Regular', false),
  student('Student', true),
  senior('Senior Citizen', true),
  pwd('PWD', true);

  const PassengerType(this.label, this.isDiscounted);
  final String label;
  final bool isDiscounted;
}

class TransitRoute {
  const TransitRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.mode,
    required this.vehicleClass,
    required this.distanceKm,
    required this.lastVerified,
    this.typicalMinutes,
    this.terminalNote,
    this.operatingHours,
  });

  final String id;
  final String origin;
  final String destination;
  final TransitMode mode;
  final String vehicleClass;
  final double distanceKm;
  final DateTime lastVerified;
  final int? typicalMinutes;
  final String? terminalNote;
  final String? operatingHours;

  String get routeLabel => '$origin → $destination';
  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
  String get durationLabel =>
      typicalMinutes == null ? '—' : '$typicalMinutes min';

  factory TransitRoute.fromMap(Map<String, dynamic> map) {
    return TransitRoute(
      id: map['id'] as String,
      origin: (map['origin'] ?? '') as String,
      destination: (map['destination'] ?? '') as String,
      mode: TransitMode.fromDb(map['mode'] as String?),
      vehicleClass: (map['vehicle_class'] ?? 'traditional') as String,
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
      lastVerified:
          DateTime.tryParse((map['last_verified_date'] ?? '') as String) ??
          DateTime.now(),
      typicalMinutes: (map['typical_minutes'] as num?)?.toInt(),
      terminalNote: map['terminal_note'] as String?,
      operatingHours: map['operating_hours'] as String?,
    );
  }
}

/// The itemised result of a fare computation, so the interface can show
/// the working rather than only a total.
class FareBreakdown {
  const FareBreakdown({
    required this.baseFare,
    required this.baseDistanceKm,
    required this.extraKm,
    required this.extraFare,
    required this.grossFare,
    required this.discountAmount,
    required this.finalFare,
    required this.verifiedOn,
    required this.source,
  });

  final double baseFare;
  final double baseDistanceKm;
  final double extraKm;
  final double extraFare;
  final double grossFare;
  final double discountAmount;
  final double finalFare;
  final DateTime verifiedOn;
  final String source;

  bool get hasDiscount => discountAmount > 0;

  String peso(double v) => '₱${v.toStringAsFixed(2)}';

  String get finalLabel => peso(finalFare);
  String get grossLabel => peso(grossFare);
  String get baseLabel => peso(baseFare);
  String get extraLabel => peso(extraFare);
  String get discountLabel => '−${peso(discountAmount)}';

  String get verifiedLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[verifiedOn.month - 1]} ${verifiedOn.day}, ${verifiedOn.year}';
  }

  factory FareBreakdown.fromMap(Map<String, dynamic> map) {
    double d(String key) => (map[key] as num?)?.toDouble() ?? 0;

    return FareBreakdown(
      baseFare: d('base_fare'),
      baseDistanceKm: d('base_distance_km'),
      extraKm: d('extra_km'),
      extraFare: d('extra_fare'),
      grossFare: d('gross_fare'),
      discountAmount: d('discount_amount'),
      finalFare: d('final_fare'),
      verifiedOn:
          DateTime.tryParse((map['verified_on'] ?? '') as String) ??
          DateTime.now(),
      source: (map['source'] ?? '') as String,
    );
  }
}

class TransitService {
  TransitService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Routes are public reference data, so this works before sign-in.
  Future<List<TransitRoute>> searchRoutes({
    String? query,
    TransitMode? mode,
    int limit = 50,
  }) async {
    try {
      final rows = await _client.rpc(
        'search_routes',
        params: {
          'q': query?.trim() ?? '',
          'mode_filter': mode?.dbValue,
          'max_results': limit,
        },
      );

      return (rows as List)
          .map((r) => TransitRoute.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw TransitFailure(_mapError(e));
    } catch (_) {
      throw const TransitFailure(
        'Could not load routes. Check your connection and try again.',
      );
    }
  }

  /// Fare computation runs in the database so every client agrees and a
  /// rate change does not require an app release.
  Future<FareBreakdown> calculateFare({
    required TransitMode mode,
    required String vehicleClass,
    required double distanceKm,
    required PassengerType passenger,
  }) async {
    try {
      final rows = await _client.rpc(
        'calculate_fare',
        params: {
          'p_mode': mode.dbValue,
          'p_vehicle_class': vehicleClass,
          'p_distance_km': distanceKm,
          'p_discounted': passenger.isDiscounted,
        },
      );

      final list = rows as List;
      if (list.isEmpty) {
        throw const TransitFailure(
          'No published fare is on file for that transport type.',
        );
      }

      return FareBreakdown.fromMap(
        Map<String, dynamic>.from(list.first as Map),
      );
    } on PostgrestException catch (e) {
      throw TransitFailure(_mapError(e));
    } catch (e) {
      if (e is TransitFailure) rethrow;
      throw const TransitFailure(
        'Could not compute the fare. Check your connection.',
      );
    }
  }

  Future<FareBreakdown> calculateForRoute(
    TransitRoute route,
    PassengerType passenger,
  ) => calculateFare(
    mode: route.mode,
    vehicleClass: route.vehicleClass,
    distanceKm: route.distanceKm,
    passenger: passenger,
  );

  /// Commuter-submitted correction, feeding the maintenance backlog.
  Future<void> reportRoute({
    required String routeId,
    required String issueType,
    String? details,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const TransitFailure('Please sign in to report a route.');
    }

    try {
      await _client.from('route_reports').insert({
        'route_id': routeId,
        'profile_id': uid,
        'issue_type': issueType,
        'details': (details == null || details.trim().isEmpty)
            ? null
            : details.trim(),
      });
    } on PostgrestException catch (e) {
      throw TransitFailure(_mapError(e));
    }
  }

  String _mapError(PostgrestException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('no active fare matrix')) {
      return 'No published fare is on file for that transport type yet.';
    }
    if (msg.contains('row-level security') || msg.contains('permission')) {
      return 'You do not have permission for that action.';
    }
    if (msg.contains('failed host lookup') || msg.contains('socket')) {
      return 'No connection. Route data will load when you are back online.';
    }
    return 'Something went wrong. ${e.message}';
  }
}