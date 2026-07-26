import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/gradient_button.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryTeal, Color(0xFF115E59), AppColors.deepTeal],
          ),
        ),
        child: SafeArea(
          // Wrapped in a scroll view + minHeight constraint instead of
          // Spacer()s, so a big logo never causes an overflow error on
          // smaller phones — it just scrolls slightly instead of crashing.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 8),

                              // Logo — large, using the pre-cropped square
                              // logo.png (just the icon badge).
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 300,
                                  height: 300,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 14),

                              const Text(
                                'HeritageLinc',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Navigate your city, discover its stories.\nTransit and heritage, guided by AI.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 15.5,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Quick feature highlights
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: const [
                                  _FeatureChip(icon: Icons.directions_bus_filled_rounded, label: 'Transit'),
                                  _FeatureChip(icon: Icons.camera_alt_rounded, label: 'AI Scan'),
                                  _FeatureChip(icon: Icons.groups_rounded, label: 'Field Trips'),
                                ],
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              // Subtle fade divider before the actions
                              Container(
                                height: 1,
                                margin: const EdgeInsets.only(bottom: 22, top: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.2),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),

                              LandingPrimaryButton(
                                label: 'Log In',
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                              ),
                              const SizedBox(height: 14),
                              LandingSecondaryButton(
                                label: 'Create Account',
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                              ),

                              const SizedBox(height: 20),
                              Text(
                                'SDG 4 · Quality Education      SDG 11 · Sustainable Cities',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Small pill showing one of the app's core features, used on the landing
/// screen to hint at what the app does beyond just the logo + tagline.
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}