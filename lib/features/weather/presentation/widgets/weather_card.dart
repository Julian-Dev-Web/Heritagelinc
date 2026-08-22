// lib/features/weather/presentation/widgets/weather_card.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/weather_service.dart';

/// Self-contained weather panel: fetches on mount, shows loading, error and
/// success states, refreshes on demand, and lets the user change location.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, this.showForecast = true});

  final bool showForecast;

  @override
  State<WeatherCard> createState() => WeatherCardState();
}

class WeatherCardState extends State<WeatherCard> {
  final _service = WeatherService();

  WeatherReport? _report;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  double _lat = WeatherService.defaultLatitude;
  double _lon = WeatherService.defaultLongitude;
  String _place = WeatherService.defaultPlaceName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  /// Public so the parent dashboard's pull-to-refresh can drive it too.
  Future<void> refresh() => _load(isRefresh: true);

  Future<void> _load({bool isRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final report = await _service.fetchWeather(
        latitude: _lat,
        longitude: _lon,
        placeName: _place,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
        _isRefreshing = false;
      });
    } on WeatherFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the weather right now.';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _openLocationSearch() async {
    final picked = await showModalBottomSheet<GeoPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSearchSheet(service: _service),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _lat = picked.latitude;
      _lon = picked.longitude;
      _place = picked.name;
    });
    await _load(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();
    if (_error != null && _report == null) return _buildError();
    return _buildReport(_report!);
  }

  // ------------------------------------------------------------- states

  Widget _buildSkeleton() {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(18),
      decoration: _shell,
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.primaryTeal,
            ),
          ),
          SizedBox(width: 14),
          Text(
            'Loading weather…',
            style: TextStyle(fontSize: 13.5, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _shell,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather unavailable',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _load(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 15,
                        color: AppColors.primaryTeal,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Try again',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(WeatherReport r) {
    final c = r.condition;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: _shell,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _openLocationSearch,
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.placeName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 17,
                      color: AppColors.textGrey,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkResponse(
                onTap: _isRefreshing ? null : () => _load(isRefresh: true),
                radius: 20,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: _isRefreshing
                      ? const Padding(
                          padding: EdgeInsets.all(5),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryTeal,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.textGrey,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(c.icon, size: 27, color: c.color),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.temperatureLabel,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.label} · ${r.feelsLikeLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _metric(Icons.water_drop_outlined, r.humidityLabel),
                  const SizedBox(height: 6),
                  _metric(Icons.air_rounded, r.windLabel),
                ],
              ),
            ],
          ),

          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: c.isRain
                  ? const Color(0xFF3E7A9E).withValues(alpha: 0.09)
                  : AppColors.primaryTeal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Icon(
                  c.isRain
                      ? Icons.umbrella_outlined
                      : Icons.directions_walk_rounded,
                  size: 15,
                  color: c.isRain ? const Color(0xFF3E7A9E) : AppColors.primaryTeal,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    r.travelAdvice,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: c.isRain
                          ? const Color(0xFF2C5F80)
                          : const Color(0xFF0C4A46),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (widget.showForecast && r.daily.isNotEmpty) ...[
            const SizedBox(height: 13),
            const Divider(height: 1, color: Color(0xFFF0F5F4)),
            const SizedBox(height: 11),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: r.daily.take(4).map(_forecastColumn).toList(),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            'Weather data by Open-Meteo.com · updated '
            '${_timeLabel(r.fetchedAt)}',
            style: const TextStyle(fontSize: 9.5, color: Color(0xFFA9B4B1)),
          ),
        ],
      ),
    );
  }

  Widget _forecastColumn(DailyForecast d) {
    final c = d.condition;
    return Expanded(
      child: Column(
        children: [
          Text(
            d.dayLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 6),
          Icon(c.icon, size: 19, color: c.color),
          const SizedBox(height: 6),
          Text(
            '${d.maxTemp.round()}°',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Text(
            '${d.minTemp.round()}°',
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
          if (d.rainChance > 0) ...[
            const SizedBox(height: 3),
            Text(
              '${d.rainChance}%',
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF5B8FA8)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textGrey),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  static String _timeLabel(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  static final _shell = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE6ECEA)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0C4A46).withValues(alpha: 0.06),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// =====================================================================
// Location search — the second endpoint
// =====================================================================

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({required this.service});
  final WeatherService service;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<GeoPlace> _results = const [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = const [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.service.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _hasSearched = true;
      });
    } on WeatherFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE5E3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      decoration: InputDecoration(
                        hintText: 'Search a city or municipality',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAF9),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E8E6),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E8E6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primaryTeal,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEDF2F1)),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController controller) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.primaryTeal,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, height: 1.5),
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Type at least two letters to search.',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'No places matched that search.',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 20, color: Color(0xFFF2F6F5)),
      itemBuilder: (context, i) {
        final place = _results[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 2,
          ),
          leading: const Icon(
            Icons.place_outlined,
            color: AppColors.textGrey,
          ),
          title: Text(
            place.name,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: place.subtitle.isEmpty
              ? null
              : Text(
                  place.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
          onTap: () => Navigator.pop(context, place),
        );
      },
    );
  }
}