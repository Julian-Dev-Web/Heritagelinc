// lib/features/weather/data/weather_service.dart
//
// Open-Meteo integration.
//   Forecast:  https://api.open-meteo.com/v1/forecast
//   Geocoding: https://geocoding-api.open-meteo.com/v1/search
//
// No API key is required, which is deliberate: nothing secret is compiled
// into the client and no credential can expire before the defense.
// Data licence: CC BY 4.0 — attribution to Open-Meteo.com is required and
// is rendered in the weather card footer.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Thrown for any failure the UI should surface to the user.
class WeatherFailure implements Exception {
  const WeatherFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A place returned by the geocoding endpoint, used by the search feature.
class GeoPlace {
  const GeoPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.admin2,
    this.country,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? admin1; // region
  final String? admin2; // province
  final String? country;

  String get subtitle {
    final parts = [
      if (admin2 != null && admin2!.isNotEmpty) admin2!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  factory GeoPlace.fromJson(Map<String, dynamic> json) {
    return GeoPlace(
      name: (json['name'] ?? '') as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      admin1: json['admin1'] as String?,
      admin2: json['admin2'] as String?,
      country: json['country'] as String?,
    );
  }
}

/// One day of the forecast.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
    required this.rainChance,
  });

  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
  final int rainChance;

  String get dayLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    if (date.day == today.day && date.month == today.month) return 'Today';
    return days[date.weekday - 1];
  }

  WeatherCondition get condition => WeatherCondition.fromCode(weatherCode);
}

/// Current conditions plus the next few days.
class WeatherReport {
  const WeatherReport({
    required this.placeName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    required this.precipitation,
    required this.daily,
    required this.fetchedAt,
  });

  final String placeName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;
  final double precipitation;
  final List<DailyForecast> daily;
  final DateTime fetchedAt;

  WeatherCondition get condition => WeatherCondition.fromCode(weatherCode);

  String get temperatureLabel => '${temperature.round()}°C';
  String get feelsLikeLabel => 'Feels like ${feelsLike.round()}°C';
  String get humidityLabel => '$humidity%';
  String get windLabel => '${windSpeed.round()} km/h';

  /// Plain-language guidance for someone about to travel or walk a heritage
  /// route. This is what turns raw data into something the app can act on.
  String get travelAdvice {
    if (precipitation > 2 || condition.isStorm) {
      return 'Heavy rain expected. Consider postponing outdoor site visits.';
    }
    if (condition.isRain) {
      return 'Rain likely. Bring an umbrella if you are walking between stops.';
    }
    if (temperature >= 34) {
      return 'Very hot. Carry water and plan shaded rest stops.';
    }
    if (temperature >= 31) {
      return 'Warm day. Good for travel, but pace outdoor walking.';
    }
    return 'Good conditions for travel and heritage site visits.';
  }

  factory WeatherReport.fromJson(
    Map<String, dynamic> json,
    String placeName,
  ) {
    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw const WeatherFailure('The weather service returned no readings.');
    }

    final dailyJson = json['daily'] as Map<String, dynamic>?;
    final days = <DailyForecast>[];

    if (dailyJson != null) {
      final times = (dailyJson['time'] as List?) ?? const [];
      final maxTemps = (dailyJson['temperature_2m_max'] as List?) ?? const [];
      final minTemps = (dailyJson['temperature_2m_min'] as List?) ?? const [];
      final codes = (dailyJson['weather_code'] as List?) ?? const [];
      final rain =
          (dailyJson['precipitation_probability_max'] as List?) ?? const [];

      for (var i = 0; i < times.length; i++) {
        if (i >= maxTemps.length || i >= minTemps.length) break;
        days.add(
          DailyForecast(
            date: DateTime.parse(times[i] as String),
            maxTemp: (maxTemps[i] as num?)?.toDouble() ?? 0,
            minTemp: (minTemps[i] as num?)?.toDouble() ?? 0,
            weatherCode: (codes.length > i ? codes[i] as num? : null)
                    ?.toInt() ??
                0,
            rainChance:
                (rain.length > i ? rain[i] as num? : null)?.toInt() ?? 0,
          ),
        );
      }
    }

    return WeatherReport(
      placeName: placeName,
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      isDay: (current['is_day'] as num?)?.toInt() == 1,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0,
      daily: days,
      fetchedAt: DateTime.now(),
    );
  }
}

/// Maps a WMO weather code to a label, an icon, and a colour.
class WeatherCondition {
  const WeatherCondition({
    required this.label,
    required this.icon,
    required this.color,
    this.isRain = false,
    this.isStorm = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isRain;
  final bool isStorm;

  static WeatherCondition fromCode(int code) {
    return switch (code) {
      0 => const WeatherCondition(
        label: 'Clear sky',
        icon: Icons.wb_sunny_rounded,
        color: Color(0xFFE3A93E),
      ),
      1 || 2 => const WeatherCondition(
        label: 'Partly cloudy',
        icon: Icons.wb_cloudy_outlined,
        color: Color(0xFF6F9BB5),
      ),
      3 => const WeatherCondition(
        label: 'Overcast',
        icon: Icons.cloud_rounded,
        color: Color(0xFF7B8A94),
      ),
      45 || 48 => const WeatherCondition(
        label: 'Foggy',
        icon: Icons.foggy,
        color: Color(0xFF98A5AC),
      ),
      51 || 53 || 55 || 56 || 57 => const WeatherCondition(
        label: 'Drizzle',
        icon: Icons.grain_rounded,
        color: Color(0xFF5B8FA8),
        isRain: true,
      ),
      61 || 63 || 66 => const WeatherCondition(
        label: 'Rain',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF3E7A9E),
        isRain: true,
      ),
      65 || 67 => const WeatherCondition(
        label: 'Heavy rain',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF2C5F80),
        isRain: true,
        isStorm: true,
      ),
      71 || 73 || 75 || 77 || 85 || 86 => const WeatherCondition(
        label: 'Snow',
        icon: Icons.ac_unit_rounded,
        color: Color(0xFF8FB8CC),
      ),
      80 || 81 => const WeatherCondition(
        label: 'Rain showers',
        icon: Icons.grain_rounded,
        color: Color(0xFF3E7A9E),
        isRain: true,
      ),
      82 => const WeatherCondition(
        label: 'Violent showers',
        icon: Icons.thunderstorm_rounded,
        color: Color(0xFF2C5F80),
        isRain: true,
        isStorm: true,
      ),
      95 || 96 || 99 => const WeatherCondition(
        label: 'Thunderstorm',
        icon: Icons.thunderstorm_rounded,
        color: Color(0xFF4A4E7C),
        isRain: true,
        isStorm: true,
      ),
      _ => const WeatherCondition(
        label: 'Unknown',
        icon: Icons.help_outline_rounded,
        color: Color(0xFF8A9490),
      ),
    };
  }
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _forecastHost = 'api.open-meteo.com';
  static const _geocodingHost = 'geocoding-api.open-meteo.com';
  static const _timeout = Duration(seconds: 12);

  /// Malolos City — the project's pilot location.
  static const defaultLatitude = 14.8433;
  static const defaultLongitude = 120.8114;
  static const defaultPlaceName = 'Malolos City';

  /// ENDPOINT 1 — current conditions plus a short daily forecast.
  Future<WeatherReport> fetchWeather({
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
    String placeName = defaultPlaceName,
    int forecastDays = 4,
  }) async {
    final uri = Uri.https(_forecastHost, '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,'
          'precipitation,weather_code,wind_speed_10m,is_day',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,'
          'precipitation_probability_max',
      'timezone': 'Asia/Manila',
      'forecast_days': '$forecastDays',
    });

    final json = await _getJson(uri);
    return WeatherReport.fromJson(json, placeName);
  }

  /// ENDPOINT 2 — place search, backing the "change location" feature.
  Future<List<GeoPlace>> searchPlaces(String query, {int limit = 8}) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final uri = Uri.https(_geocodingHost, '/v1/search', {
      'name': q,
      'count': '$limit',
      'language': 'en',
      'format': 'json',
    });

    final json = await _getJson(uri);
    final results = json['results'] as List?;
    if (results == null) return const [];

    return results
        .map((r) => GeoPlace.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Single place where the HTTP GET, the status handling, and the JSON
  /// decode live, so every endpoint reports failures the same way.
  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 429) {
        throw const WeatherFailure(
          'Weather service is busy right now. Please try again shortly.',
        );
      }
      if (response.statusCode >= 500) {
        throw const WeatherFailure(
          'The weather service is temporarily unavailable.',
        );
      }
      if (response.statusCode != 200) {
        throw WeatherFailure(
          'Weather request failed (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherFailure(
          'The weather service returned an unexpected format.',
        );
      }

      // Open-Meteo signals bad parameters with 200 + {"error": true}.
      if (decoded['error'] == true) {
        throw WeatherFailure(
          (decoded['reason'] as String?) ?? 'Weather request was rejected.',
        );
      }

      return decoded;
    } on SocketException {
      throw const WeatherFailure(
        'No internet connection. Weather will update when you are back online.',
      );
    } on TimeoutException {
      throw const WeatherFailure(
        'The weather service took too long to respond.',
      );
    } on FormatException {
      throw const WeatherFailure('Could not read the weather data.');
    } on http.ClientException {
      throw const WeatherFailure(
        'Could not reach the weather service. Check your connection.',
      );
    }
  }

  void dispose() => _client.close();
}