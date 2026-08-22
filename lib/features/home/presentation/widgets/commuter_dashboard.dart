// lib/features/home/presentation/widgets/commuter_dashboard.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../weather/presentation/widgets/weather_card.dart';
import '../../data/sample_data.dart';
import 'dashboard_common.dart';

class CommuterDashboard extends StatelessWidget {
  const CommuterDashboard({
    super.key,
    required this.profile,
    required this.onOpenScanner,
    required this.onRefresh,
  });

  final AppProfile profile;
  final VoidCallback onOpenScanner;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryTeal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          DashboardHeader(
            profile: profile,
            subtitle: 'Saan ka pupunta ngayon?',
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGutter),
              child: _SearchBar(
                onTap: () => showComingSoon(context, 'Trip planner'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Open-Meteo integration — current conditions, four-day
                // forecast, and travel advice for the selected location.
                const WeatherCard(),
                const SizedBox(height: 26),

                _buildQuickActions(context),
                const SizedBox(height: 26),

                const SectionHeader(title: 'Heritage sites near you'),
                SizedBox(
                  height: 196,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: SampleData.heritageSites.length,
                    itemBuilder: (context, i) {
                      final site = SampleData.heritageSites[i];
                      return HeritageCard(
                        site: site,
                        onTap: () => showComingSoon(context, site.name),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                SectionHeader(
                  title: 'Popular routes',
                  actionLabel: 'See all',
                  onAction: () => showComingSoon(context, 'Route directory'),
                ),
                ...SampleData.routes.map(
                  (r) => RouteRow(
                    route: r,
                    onTap: () => showComingSoon(context, 'Fare breakdown'),
                  ),
                ),
                const SizedBox(height: 6),
                const SampleDataNotice(),
                const SizedBox(height: 24),

                _buildLensPromo(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickAction(
            icon: Icons.alt_route_rounded,
            label: 'Plan a Trip',
            color: AppColors.primaryTeal,
            onTap: () => showComingSoon(context, 'Trip planner'),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: QuickAction(
            icon: Icons.payments_outlined,
            label: 'Fare Guide',
            color: const Color(0xFF3E6B7C),
            onTap: () => showComingSoon(context, 'Fare guide'),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: QuickAction(
            icon: Icons.museum_outlined,
            label: 'Heritage Map',
            color: const Color(0xFF8C5A2B),
            onTap: () => showComingSoon(context, 'Heritage map'),
          ),
        ),
      ],
    );
  }

  Widget _buildLensPromo(BuildContext context) {
    return GestureDetector(
      onTap: onOpenScanner,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF14625A), Color(0xFF0C4A46)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.center_focus_strong_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heritage Lens',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Point your camera at a marker or painting to hear its story.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C4A46).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.textGrey, size: 21),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Where are you going?',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
            ),
            Icon(Icons.tune_rounded, color: AppColors.textGrey, size: 19),
          ],
        ),
      ),
    );
  }
}