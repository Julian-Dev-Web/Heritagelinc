// lib/features/home/presentation/widgets/teacher_dashboard.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../weather/presentation/widgets/weather_card.dart';
import 'dashboard_common.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({
    super.key,
    required this.profile,
    required this.onOpenScanner,
    required this.onRefresh,
  });

  final AppProfile profile;
  final VoidCallback onOpenScanner;
  final Future<void> Function() onRefresh;

  bool get _approved => profile.teacherStatus.isApproved;

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
            subtitle: profile.designation ?? 'Handa nang mag-field trip?',
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGutter),
              child: _CreateTripCard(
                enabled: _approved,
                onTap: () => _approved
                    ? showComingSoon(context, 'Field trip builder')
                    : _explainLock(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Open-Meteo integration — a four-day outlook is a real
                // decision input when a trip commits thirty students.
                const WeatherCard(),
                const SizedBox(height: 24),

                if (!_approved) ...[
                  _buildVerificationBanner(context),
                  const SizedBox(height: 24),
                ],

                const SectionHeader(title: 'Active lobbies'),
                const EmptyState(
                  icon: Icons.meeting_room_outlined,
                  title: 'No open lobbies',
                  message:
                      'Create a field trip to generate a Room ID and QR code '
                      'that your class can scan to join.',
                ),
                const SizedBox(height: 26),

                _buildQuickActions(context),
                const SizedBox(height: 26),

                const SectionHeader(title: 'Your teaching profile'),
                _buildCredentialsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context) {
    if (profile.teacherStatus.isRejected) {
      return InfoBanner(
        icon: Icons.gpp_bad_outlined,
        color: AppColors.danger,
        message:
            'Your teaching credentials could not be verified. Field trip '
            'hosting stays locked until this is resolved. You can resubmit '
            'a clearer photo of your faculty ID.',
        actionLabel: 'Resubmit ID',
        onAction: () => showComingSoon(context, 'ID resubmission'),
      );
    }

    return InfoBanner(
      icon: Icons.hourglass_top_rounded,
      color: const Color(0xFF9A7418),
      message:
          'Your account is awaiting administrator approval. You can use the '
          'transit guide and Heritage Lens now; hosting field trips unlocks '
          'once your credentials are verified.',
      actionLabel: 'Upload faculty ID',
      onAction: () => showComingSoon(context, 'ID upload'),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickAction(
            icon: Icons.playlist_add_check_rounded,
            label: 'Attendance',
            color: AppColors.primaryTeal,
            onTap: () => _approved
                ? showComingSoon(context, 'Attendance roster')
                : _explainLock(context),
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
            icon: Icons.alt_route_rounded,
            label: 'Plan Route',
            color: const Color(0xFF3E6B7C),
            onTap: () => showComingSoon(context, 'Trip planner'),
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialsCard() {
    final rows = <(IconData, String, String?)>[
      (Icons.account_balance_outlined, 'School', profile.schoolNameRaw),
      (Icons.badge_outlined, 'Faculty ID', profile.employeeId),
      (Icons.work_outline_rounded, 'Designation', profile.designation),
      (Icons.menu_book_outlined, 'Subject', profile.subjectTaught),
      (Icons.verified_outlined, 'PRC License', profile.prcLicenseNo),
    ].where((r) => r.$3 != null && r.$3!.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECEA)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 18, color: AppColors.textGrey),
                  const SizedBox(width: 12),
                  Text(
                    rows[i].$2,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      rows[i].$3!,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, color: Color(0xFFF0F5F4)),
          ],
        ],
      ),
    );
  }

  void _explainLock(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Field trip hosting unlocks once your account is approved.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}

class _CreateTripCard extends StatelessWidget {
  const _CreateTripCard({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.62,
        child: Container(
          padding: const EdgeInsets.all(17),
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
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  enabled ? Icons.add_location_alt_outlined : Icons.lock_outline,
                  color: AppColors.primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a field trip',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      enabled
                          ? 'Open a lobby and share the QR code with your class.'
                          : 'Locked until your account is approved.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}