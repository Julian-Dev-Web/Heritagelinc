import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/heritage_backdrop.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _accent = Color(0xFFE3B75E);
  static const _logoAsset = 'assets/images/logo.png';

  /// Width of the logo mark. Bigger number = bigger logo.
  static const _logoWidth = 410.0;

  /// Portion of the PNG kept from the top, cropping off the wordmark below.
  /// Lower = tighter crop. Tune between 0.50 and 0.80.
  static const _logoCrop = 0.62;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeritageBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildLogo(),
                          const SizedBox(height: 18),
                          const Text(
                            'HeritageLinc',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Navigate your city, discover its stories.\n'
                            'Transit and heritage, guided by AI.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.80),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const _FeatureRow(),
                          const SizedBox(height: 34),
                          const _Ornament(accent: _accent),

                          // Pushes everything below to the bottom of the screen.
                          const Spacer(),

                          _buildActions(context),
                          const SizedBox(height: 18),
                          Text(
                            '© 2026 HeritageLinc. All rights reserved.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 6),
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

  Widget _buildLogo() {
    return SizedBox(
      width: _logoWidth,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: _logoCrop,
          child: Image.asset(
            _logoAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 120,
              child: Icon(
                Icons.broken_image_rounded,
                color: Colors.white54,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0C4A46),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Log In'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
            child: const Text('Create Account'),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _FeatureChip(icon: Icons.directions_bus_rounded, label: 'Transit'),
        _FeatureChip(icon: Icons.camera_alt_rounded, label: 'AI Scan'),
        _FeatureChip(icon: Icons.groups_rounded, label: 'Field Trips'),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }
}

/// Hairline rule with a centred diamond — breaks up the middle of the screen.
class _Ornament extends StatelessWidget {
  const _Ornament({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _rule(toRight: true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
        Expanded(child: _rule(toRight: false)),
      ],
    );
  }

  Widget _rule({required bool toRight}) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: toRight ? Alignment.centerLeft : Alignment.centerRight,
          end: toRight ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.30),
          ],
        ),
      ),
    );
  }
}