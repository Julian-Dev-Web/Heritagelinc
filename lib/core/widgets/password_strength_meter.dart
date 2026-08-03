// lib/core/widgets/password_strength_meter.dart

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/validators.dart';

/// Live strength bar plus a tick-list of the password requirements.
/// Pass the current password text; it rebuilds itself as the user types.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.showChecklist = true,
  });

  final String password;
  final bool showChecklist;

  static const _weak = Color(0xFFD64545);
  static const _fair = Color(0xFFE0912F);
  static const _good = Color(0xFF4A9D5F);
  static const _strong = Color(0xFF17806B);

  Color get _color {
    final s = PasswordPolicy.strength(password);
    if (s < 0.35) return _weak;
    if (s < 0.65) return _fair;
    if (s < 0.9) return _good;
    return _strong;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final results = PasswordPolicy.evaluate(password);
    final strength = PasswordPolicy.strength(password);
    final label = PasswordPolicy.strengthLabel(password);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildBar(strength)),
              const SizedBox(width: 12),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
                child: Text(label),
              ),
            ],
          ),
          if (showChecklist) ...[
            const SizedBox(height: 12),
            ...List.generate(
              PasswordPolicy.rules.length,
              (i) => _ChecklistRow(
                label: PasswordPolicy.rules[i].label,
                met: results[i],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBar(double strength) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EFED),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: 6,
              width: constraints.maxWidth * strength,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    const done = Color(0xFF17806B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 17,
            height: 17,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? done : Colors.transparent,
              border: Border.all(
                color: met ? done : const Color(0xFFCBD5D2),
                width: 1.4,
              ),
            ),
            child: met
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: met ? FontWeight.w600 : FontWeight.w400,
                color: met ? done : AppColors.textGrey,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}