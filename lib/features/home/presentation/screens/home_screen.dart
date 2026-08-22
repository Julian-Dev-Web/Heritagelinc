// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../trips/presentation/screens/saved_trips_screen.dart';
import '../widgets/commuter_dashboard.dart';
import '../widgets/dashboard_common.dart';
import '../widgets/student_dashboard.dart';
import '../widgets/teacher_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  int _tabIndex = 0;
  AppProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) setState(() => _error = null);

    try {
      final profile = await _authService.fetchMyProfile();
      if (!mounted) return;

      if (profile == null) {
        setState(() {
          _error = 'We could not find your profile. Please sign in again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your profile. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landing,
      (route) => false,
    );
  }

  void _openScanner() => setState(() => _tabIndex = 2);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F6),
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: AppColors.primaryTeal,
          ),
        ),
      );
    }

    if (_error != null || _profile == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      extendBody: true,
      body: IndexedStack(index: _tabIndex, children: _buildTabs()),
      floatingActionButton: _buildScanFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  List<Widget> _buildTabs() {
    final profile = _profile!;

    return [
      _buildDashboard(profile),
      const _PlaceholderTab(
        icon: Icons.alt_route_rounded,
        title: 'Transit Guide',
        message:
            'Route search, the fare calculator, and geofenced site alerts '
            'live here. This module is scheduled for Weeks 4 to 6.',
      ),
      const _PlaceholderTab(
        icon: Icons.center_focus_strong_rounded,
        title: 'Heritage Lens',
        message:
            'Point the camera at a marker or painting to generate a digital '
            'capsule. This module is scheduled for Weeks 5 to 7.',
      ),
      const SavedTripsScreen(embedded: true),
      _ProfileTab(profile: profile, onSignOut: _confirmSignOut),
    ];
  }

  Widget _buildDashboard(AppProfile profile) {
    switch (profile.role) {
      case UserRole.commuter:
        return CommuterDashboard(
          profile: profile,
          onOpenScanner: _openScanner,
          onRefresh: _loadProfile,
        );
      case UserRole.student:
        return StudentDashboard(
          profile: profile,
          onOpenScanner: _openScanner,
          onRefresh: _loadProfile,
        );
      case UserRole.teacher:
        return TeacherDashboard(
          profile: profile,
          onOpenScanner: _openScanner,
          onRefresh: _loadProfile,
        );
    }
  }

  Widget _buildScanFab() {
    final active = _tabIndex == 2;
    return SizedBox(
      width: 58,
      height: 58,
      child: FloatingActionButton(
        onPressed: () => setState(() => _tabIndex = 2),
        backgroundColor: active
            ? const Color(0xFF0C4A46)
            : AppColors.primaryTeal,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.center_focus_strong_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 62,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_rounded, 'Home'),
          _navItem(1, Icons.alt_route_rounded, 'Transit'),
          const SizedBox(width: 58), // notch
          _navItem(3, Icons.bookmark_rounded, 'Trips'),
          _navItem(4, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _tabIndex == index;
    final color = selected ? AppColors.primaryTeal : const Color(0xFF9AA8A5);

    return Expanded(
      child: InkResponse(
        onTap: () => setState(() => _tabIndex = index),
        radius: 34,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: Color(0xFFB9C6C2),
              ),
              const SizedBox(height: 18),
              Text(
                _error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadProfile();
                },
                child: const Text('Try again'),
              ),
              TextButton(
                onPressed: _signOut,
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Sign out?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will need to log in again to access your trips and scan history.',
          style: TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) await _signOut();
  }
}

// ---------------------------------------------------------------- sub-tabs

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryTeal.withValues(alpha: 0.09),
                ),
                child: Icon(icon, size: 34, color: AppColors.primaryTeal),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.profile, required this.onSignOut});

  final AppProfile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DashboardHeader(profile: profile, subtitle: profile.email),
        Padding(
          padding: const EdgeInsets.fromLTRB(kGutter, 22, kGutter, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Account'),
              _tile(
                context,
                Icons.person_outline_rounded,
                'Full name',
                profile.fullName,
              ),
              _tile(
                context,
                Icons.mail_outline_rounded,
                'Email',
                profile.email,
              ),
              if (profile.schoolNameRaw != null)
                _tile(
                  context,
                  Icons.account_balance_outlined,
                  'School',
                  profile.schoolNameRaw!,
                ),
              if (profile.studentNumber != null)
                _tile(
                  context,
                  Icons.badge_outlined,
                  'Student number',
                  profile.studentNumber!,
                ),
              if (profile.gradeLevel != null)
                _tile(
                  context,
                  Icons.school_outlined,
                  'Level',
                  profile.gradeLevel!,
                ),

              const SizedBox(height: 26),
              const SectionHeader(title: 'Settings'),
              _actionTile(
                context,
                Icons.edit_outlined,
                'Edit profile',
                () => showComingSoon(context, 'Profile editing'),
              ),
              _actionTile(
                context,
                Icons.download_outlined,
                'Offline downloads',
                () => showComingSoon(context, 'Offline downloads'),
              ),
              _actionTile(
                context,
                Icons.privacy_tip_outlined,
                'Data privacy notice',
                () => showComingSoon(context, 'Privacy notice'),
              ),

              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECEA)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.textGrey),
          const SizedBox(width: 13),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
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
    );
  }

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6ECEA)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.primaryTeal),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
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