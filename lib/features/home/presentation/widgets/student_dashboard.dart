// lib/features/home/presentation/widgets/student_dashboard.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../weather/presentation/widgets/weather_card.dart';
import '../../data/sample_data.dart';
import 'dashboard_common.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({
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
            subtitle: profile.gradeLevel ?? 'Handa na para sa field trip?',
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGutter),
              child: _JoinTripCard(
                onScan: () => showComingSoon(context, 'QR scanner'),
                onEnterCode: () => _showRoomIdSheet(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Open-Meteo integration — matters here because students
                // travel to sites their teacher has scheduled.
                const WeatherCard(),
                const SizedBox(height: 26),

                const SectionHeader(title: 'Your field trips'),
                const EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No trips yet',
                  message:
                      'When your teacher opens a field trip lobby, scan the QR '
                      'code or enter the Room ID to join.',
                ),
                const SizedBox(height: 26),

                _buildQuickActions(context),
                const SizedBox(height: 26),

                const SectionHeader(title: 'Explore before you go'),
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
                const SizedBox(height: 22),

                _buildSchoolCard(context),
                const SizedBox(height: 16),
                const SampleDataNotice(
                  text:
                      'Heritage entries shown here are placeholders. Final '
                      'content comes from the curated NHCP-sourced dataset.',
                ),
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
            icon: Icons.center_focus_strong_rounded,
            label: 'Heritage Lens',
            color: const Color(0xFF8C5A2B),
            onTap: onOpenScanner,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: QuickAction(
            icon: Icons.history_rounded,
            label: 'My Scans',
            color: const Color(0xFF3E6B7C),
            onTap: () => showComingSoon(context, 'Scan history'),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolCard(BuildContext context) {
    final school = profile.schoolNameRaw ?? 'Your school';

    return Container(
      padding: const EdgeInsets.all(15),
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
            child: const Icon(
              Icons.account_balance_outlined,
              size: 20,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.studentNumber == null
                      ? 'Student'
                      : 'Student No. ${profile.studentNumber}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomIdSheet(BuildContext context) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
              const Text(
                'Enter Room ID',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ask your teacher for the six-character code shown on the '
                'lobby screen.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'ABC123',
                  hintStyle: TextStyle(
                    color: AppColors.textGrey.withValues(alpha: 0.4),
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAF9),
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
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    showComingSoon(context, 'Field trip lobby');
                  },
                  child: const Text(
                    'Join Trip',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinTripCard extends StatelessWidget {
  const _JoinTripCard({required this.onScan, required this.onEnterCode});

  final VoidCallback onScan;
  final VoidCallback onEnterCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C4A46).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join a field trip',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text(
                    'Scan QR',
                    style: TextStyle(fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: Color(0xFFCBDDD9)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: onEnterCode,
                  icon: const Icon(Icons.keyboard_rounded, size: 18),
                  label: const Text(
                    'Room ID',
                    style: TextStyle(fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}