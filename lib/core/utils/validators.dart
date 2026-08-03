// lib/core/utils/validators.dart

/// A single requirement in the password policy.
class PasswordRule {
  const PasswordRule({required this.label, required this.test});

  final String label;
  final bool Function(String) test;
}

/// Central password policy. Change it here and both the checklist widget
/// and the form validator follow automatically.
class PasswordPolicy {
  const PasswordPolicy._();

  static const int minLength = 8;
  static const int maxLength = 72; // bcrypt truncates beyond this

  static final List<PasswordRule> rules = [
    PasswordRule(
      label: 'At least $minLength characters',
      test: (p) => p.length >= minLength,
    ),
    PasswordRule(
      label: 'One uppercase letter (A–Z)',
      test: (p) => RegExp(r'[A-Z]').hasMatch(p),
    ),
    PasswordRule(
      label: 'One lowercase letter (a–z)',
      test: (p) => RegExp(r'[a-z]').hasMatch(p),
    ),
    PasswordRule(
      label: 'One number (0–9)',
      test: (p) => RegExp(r'[0-9]').hasMatch(p),
    ),
    PasswordRule(
      label: 'One special character (!@#\$&*…)',
      test: (p) => RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/~`';]''').hasMatch(p),
    ),
  ];

  /// Which rules the given password satisfies, in the same order as [rules].
  static List<bool> evaluate(String password) =>
      rules.map((r) => r.test(password)).toList();

  static int satisfiedCount(String password) =>
      evaluate(password).where((met) => met).length;

  static bool isValid(String password) =>
      satisfiedCount(password) == rules.length &&
      password.length <= maxLength;

  /// 0.0 – 1.0, used to draw the strength bar.
  static double strength(String password) {
    if (password.isEmpty) return 0;
    var score = satisfiedCount(password) / rules.length;

    // Reward genuine length beyond the minimum.
    if (password.length >= 12) score += 0.08;
    if (password.length >= 16) score += 0.07;

    // Penalise obvious patterns even when the boxes are ticked.
    if (_hasRun(password)) score -= 0.15;
    if (_isCommon(password)) score = 0.15;

    return score.clamp(0.0, 1.0);
  }

  static String strengthLabel(String password) {
    if (password.isEmpty) return '';
    final s = strength(password);
    if (s < 0.35) return 'Weak';
    if (s < 0.65) return 'Fair';
    if (s < 0.9) return 'Good';
    return 'Strong';
  }

  /// Four or more sequential or repeated characters: 1234, aaaa, abcd.
  static bool _hasRun(String p) {
    if (p.length < 4) return false;
    final lower = p.toLowerCase();
    for (var i = 0; i + 3 < lower.length; i++) {
      final a = lower.codeUnitAt(i);
      final b = lower.codeUnitAt(i + 1);
      final c = lower.codeUnitAt(i + 2);
      final d = lower.codeUnitAt(i + 3);
      final ascending = b == a + 1 && c == b + 1 && d == c + 1;
      final descending = b == a - 1 && c == b - 1 && d == c - 1;
      final repeated = a == b && b == c && c == d;
      if (ascending || descending || repeated) return true;
    }
    return false;
  }

  static const _commonPasswords = {
    'password', 'password1', 'password123', 'qwerty', 'qwerty123',
    '12345678', '123456789', 'iloveyou', 'admin123', 'letmein',
    'welcome1', 'abc12345', 'p@ssw0rd', 'passw0rd', 'pilipinas',
  };

  static bool _isCommon(String p) => _commonPasswords.contains(p.toLowerCase());
}

class Validators {
  const Validators._();

  // Practical address grammar: local part, @, labelled domain, TLD of 2+.
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
    r'@'
    r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*'
    r'\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address';
    if (v.contains(' ')) return 'Email cannot contain spaces';
    if (v.contains('..')) return 'Email cannot contain two dots in a row';
    if (v.startsWith('.') || v.startsWith('@')) {
      return 'Enter a valid email address';
    }
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    if (v.length > 254) return 'That email address is too long';
    return null;
  }

  /// Full policy check, for sign-up.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length > PasswordPolicy.maxLength) {
      return 'Password must be ${PasswordPolicy.maxLength} characters or fewer';
    }

    final results = PasswordPolicy.evaluate(v);
    final firstUnmet = results.indexOf(false);
    if (firstUnmet != -1) {
      return 'Password needs: ${PasswordPolicy.rules[firstUnmet].label.toLowerCase()}';
    }
    if (PasswordPolicy._isCommon(v)) {
      return 'That password is too common. Please choose another.';
    }
    return null;
  }

  /// Presence check only, for sign-in. Existing accounts may predate the
  /// policy, so the login form must not lock them out.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Re-enter your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? name(String? value, {String label = 'Name'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (v.length < 2) return 'Too short';
    if (!RegExp(r"^[a-zA-ZÀ-ÿñÑ .'\-]+$").hasMatch(v)) {
      return 'Letters only';
    }
    return null;
  }
}