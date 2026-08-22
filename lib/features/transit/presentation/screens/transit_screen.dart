// lib/features/transit/presentation/screens/transit_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../trips/data/saved_trip_service.dart';
import '../../data/transit_service.dart';

class TransitScreen extends StatefulWidget {
  const TransitScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TransitScreen> createState() => _TransitScreenState();
}

class _TransitScreenState extends State<TransitScreen> {
  static const _accent = Color(0xFFE3B75E);

  final _service = TransitService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<TransitRoute> _routes = const [];
  TransitMode? _modeFilter;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _error = null);

    try {
      final routes = await _service.searchRoutes(
        query: _searchCtrl.text,
        mode: _modeFilter,
      );
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } on TransitFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  void _openFareSheet(TransitRoute route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FareSheet(service: _service, route: route),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Transit Guide',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              iconTheme: const IconThemeData(color: AppColors.textDark),
            ),
      body: SafeArea(
        top: widget.embedded,
        child: Column(
          children: [
            if (widget.embedded) _buildHeader(),
            _buildSearch(),
            _buildModeFilter(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Transit Guide',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search a town or terminal',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textGrey,
            size: 20,
          ),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textGrey,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    _load();
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E8E6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E8E6)),
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
    );
  }

  Widget _buildModeFilter() {
    final chips = <(TransitMode?, String, IconData?)>[
      (null, 'All', null),
      ...TransitMode.values.map((m) => (m, m.label, m.icon)),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (mode, label, icon) = chips[i];
          final selected = _modeFilter == mode;

          return GestureDetector(
            onTap: () {
              setState(() => _modeFilter = mode);
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryTeal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryTeal
                      : const Color(0xFFE1E8E6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 15,
                      color: selected ? Colors.white : AppColors.textGrey,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
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
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Color(0xFFB9C6C2),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_routes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFFB9C6C2),
              ),
              SizedBox(height: 16),
              Text(
                'No routes found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try a different town, or clear the mode filter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryTeal,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: _routes.length + 1,
        itemBuilder: (context, i) {
          if (i == _routes.length) return _buildFooterNotice();
          final route = _routes[i];
          return _RouteCard(
            route: route,
            onTap: () => _openFareSheet(route),
          );
        },
      ),
    );
  }

  Widget _buildFooterNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _accent.withValues(alpha: 0.30)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: Color(0xFF9A7418)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fares are estimates computed from the LTFRB matrix effective '
              '19 March 2026. Distances are approximate and pending field '
              'verification. Actual fares may differ by operator.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF7A5C12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Route card
// =====================================================================

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});

  final TransitRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6ECEA)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                route.mode.icon,
                size: 20,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          route.origin,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          route.destination,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${route.mode.label} · ${route.distanceLabel} · '
                    '${route.durationLabel}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Fare breakdown sheet
// =====================================================================

class _FareSheet extends StatefulWidget {
  const _FareSheet({required this.service, required this.route});

  final TransitService service;
  final TransitRoute route;

  @override
  State<_FareSheet> createState() => _FareSheetState();
}

class _FareSheetState extends State<_FareSheet> {
  final _tripService = SavedTripService();

  PassengerType _passenger = PassengerType.regular;
  FareBreakdown? _fare;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  Future<void> _compute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fare = await widget.service.calculateForRoute(
        widget.route,
        _passenger,
      );
      if (!mounted) return;
      setState(() {
        _fare = fare;
        _isLoading = false;
      });
    } on TransitFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  /// Bridges the Transit Guide into the Saved Trips module.
  Future<void> _saveAsTrip() async {
    final r = widget.route;
    setState(() => _isSaving = true);

    try {
      await _tripService.create(
        label: '${r.origin} to ${r.destination}',
        origin: r.origin,
        destination: r.destination,
        mode: TripMode.fromDb(r.mode.dbValue),
        estimatedFare: _fare?.finalFare,
        notes: r.terminalNote,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to your saved trips.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } on TripFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.route;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE5E3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    r.mode.icon,
                    size: 21,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.routeLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${r.mode.label} · ${r.distanceLabel} · '
                        '${r.durationLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (r.terminalNote != null) ...[
              const SizedBox(height: 16),
              _infoRow(Icons.place_outlined, r.terminalNote!),
            ],
            if (r.operatingHours != null) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.schedule_rounded, r.operatingHours!),
            ],

            const SizedBox(height: 22),
            const Text(
              'Passenger type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PassengerType.values.map((p) {
                final selected = _passenger == p;
                return GestureDetector(
                  onTap: () {
                    setState(() => _passenger = p);
                    _compute();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryTeal.withValues(alpha: 0.09)
                          : const Color(0xFFF7FAF9),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryTeal
                            : const Color(0xFFE1E8E6),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.primaryTeal
                            : AppColors.textGrey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primaryTeal,
                  ),
                ),
              )
            else if (_error != null)
              _errorBox(_error!)
            else
              _buildBreakdown(_fare!),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: const BorderSide(color: Color(0xFFCBDDD9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSaving || _fare == null ? null : _saveAsTrip,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryTeal,
                        ),
                      )
                    : const Icon(Icons.bookmark_add_outlined, size: 18),
                label: const Text(
                  'Save to my trips',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(FareBreakdown f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECEA)),
      ),
      child: Column(
        children: [
          _fareRow(
            'Base fare (first ${f.baseDistanceKm.toStringAsFixed(0)} km)',
            f.baseLabel,
          ),
          if (f.extraKm > 0) ...[
            const SizedBox(height: 9),
            _fareRow(
              'Additional ${f.extraKm.toStringAsFixed(1)} km',
              f.extraLabel,
            ),
          ],
          if (f.hasDiscount) ...[
            const SizedBox(height: 9),
            _fareRow('Subtotal', f.grossLabel),
            const SizedBox(height: 9),
            _fareRow(
              '${_passenger.label} discount (20%)',
              f.discountLabel,
              color: const Color(0xFF17806B),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: Color(0xFFE1E8E6)),
          ),
          Row(
            children: [
              const Text(
                'Estimated fare',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                f.finalLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rates verified ${f.verifiedLabel}. Source: ${f.source}.',
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: Color(0xFFA9B4B1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value, {Color? color}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textGrey),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.20)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.danger,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }
}