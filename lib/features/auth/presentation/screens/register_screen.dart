import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/heritage_backdrop.dart';
import '../../../../core/widgets/password_strength_meter.dart';
import '../../../../core/widgets/soft_input_decoration.dart';
import '../../data/auth_service.dart';
import '../../data/school_service.dart';
import '../../data/models/auth_models.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _accent = Color(0xFFE3B75E);
  static const _gutter = 24.0;

  static const _gradeLevels = <String>[
    'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6',
    'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12',
    '1st Year College', '2nd Year College', '3rd Year College',
    '4th Year College', '5th Year College',
  ];

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _schoolService = SchoolService();

  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _studentNumberCtrl = TextEditingController();
  final _schoolOtherCtrl = TextEditingController();
  final _prcCtrl = TextEditingController();
  final _employeeIdCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  UserRole _role = UserRole.commuter;
  School? _selectedSchool;
  bool _schoolNotListed = false;
  String? _gradeLevel;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToPrivacy = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  SignUpResult? _result;

  bool get _needsSchool =>
      _role == UserRole.student || _role == UserRole.teacher;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _middleNameCtrl, _lastNameCtrl, _emailCtrl,
      _passwordCtrl, _confirmCtrl, _studentNumberCtrl, _schoolOtherCtrl,
      _prcCtrl, _employeeIdCtrl, _designationCtrl, _subjectCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_needsSchool && _selectedSchool == null && !_schoolNotListed) {
      setState(() => _errorMessage = 'Please select your school.');
      return;
    }
    if (!_agreedToPrivacy) {
      setState(
        () => _errorMessage = 'Please agree to the data privacy notice.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final result = await _authService.signUp(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        role: _role,
        firstName: _firstNameCtrl.text,
        middleName: _middleNameCtrl.text,
        lastName: _lastNameCtrl.text,
        schoolId: _selectedSchool?.id,
        schoolNameRaw: _schoolNotListed ? _schoolOtherCtrl.text : null,
        studentNumber: _studentNumberCtrl.text,
        gradeLevel: _gradeLevel,
        prcLicenseNo: _prcCtrl.text,
        employeeId: _employeeIdCtrl.text,
        designation: _designationCtrl.text,
        subjectTaught: _subjectCtrl.text,
      );

      if (!mounted) return;
      setState(() => _result = result);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openSchoolPicker() async {
    final picked = await showModalBottomSheet<_SchoolPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SchoolPickerSheet(service: _schoolService),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (picked.notListed) {
        _schoolNotListed = true;
        _selectedSchool = null;
      } else {
        _schoolNotListed = false;
        _selectedSchool = picked.school;
        _schoolOtherCtrl.clear();
      }
      _errorMessage = null;
    });
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C4A46),
      resizeToAvoidBottomInset: true,
      body: HeritageBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: _result == null
                    ? _buildFormSheet()
                    : _buildSuccessSheet(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDone = _result != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, 6, _gutter, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDone) _buildBackButton(),
          if (!isDone) const SizedBox(height: 14),
          Text(
            isDone ? 'Almost there' : 'Create account',
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 46,
            height: 3,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isDone
                ? 'One more step before you can sign in.'
                : 'Tell us how you will be using HeritageLinc.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetShell({required Widget child}) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(_gutter, 18, _gutter, 26 + bottomInset),
          child: child,
        ),
      ),
    );
  }

  // ------------------------------------------------------------- form sheet

  Widget _buildFormSheet() {
    return _sheetShell(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _dragHandle()),
            const SizedBox(height: 22),

            if (_errorMessage != null) ...[
              _errorBanner(_errorMessage!),
              const SizedBox(height: 18),
            ],

            _sectionLabel('I am a'),
            const SizedBox(height: 10),
            _buildRoleSelector(),
            const SizedBox(height: 24),

            _sectionLabel('Your name'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: softInputDecoration(
                      hint: 'First name',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (v) => Validators.name(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: softInputDecoration(
                      hint: 'Last name',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (v) => Validators.name(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _middleNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: softInputDecoration(
                hint: 'Middle name (optional)',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return Validators.name(v);
              },
            ),
            const SizedBox(height: 24),

            _sectionLabel('Account'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: softInputDecoration(
                hint: 'Email address',
                icon: Icons.mail_outline_rounded,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
              decoration: softInputDecoration(
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: Validators.password,
            ),
            PasswordStrengthMeter(password: _passwordCtrl.text),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: softInputDecoration(
                hint: 'Confirm password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) =>
                  Validators.confirmPassword(v, _passwordCtrl.text),
            ),

            if (_needsSchool) ...[
              const SizedBox(height: 24),
              _sectionLabel('School'),
              const SizedBox(height: 10),
              _buildSchoolField(),
              if (_schoolNotListed) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _schoolOtherCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: softInputDecoration(
                    hint: 'Type your school name',
                    icon: Icons.edit_outlined,
                  ),
                  validator: (v) {
                    if (!_schoolNotListed) return null;
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your school name';
                    }
                    if (v.trim().length < 4) return 'Enter the full name';
                    return null;
                  },
                ),
              ],
            ],

            if (_role == UserRole.student) ...[
              const SizedBox(height: 24),
              _sectionLabel('Student details'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _studentNumberCtrl,
                decoration: softInputDecoration(
                  hint: 'Student number',
                  icon: Icons.badge_outlined,
                ),
                validator: (v) {
                  if (_role != UserRole.student) return null;
                  return Validators.requiredField(
                    v,
                    label: 'Student number',
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gradeLevel,
                isExpanded: true,
                decoration: softInputDecoration(
                  hint: 'Grade / year level',
                  icon: Icons.school_outlined,
                ),
                items: _gradeLevels
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gradeLevel = v),
                validator: (v) {
                  if (_role != UserRole.student) return null;
                  return v == null ? 'Select your level' : null;
                },
              ),
            ],

            if (_role == UserRole.teacher) ...[
              const SizedBox(height: 24),
              _sectionLabel('Teaching credentials'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _employeeIdCtrl,
                decoration: softInputDecoration(
                  hint: 'Employee / faculty ID',
                  icon: Icons.badge_outlined,
                ),
                validator: (v) {
                  if (_role != UserRole.teacher) return null;
                  return Validators.requiredField(v, label: 'Faculty ID');
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prcCtrl,
                keyboardType: TextInputType.number,
                decoration: softInputDecoration(
                  hint: 'PRC license number (optional)',
                  icon: Icons.verified_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(r'^[0-9]{6,10}$').hasMatch(v.trim())) {
                    return 'PRC numbers are 6 to 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _designationCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: softInputDecoration(
                  hint: 'Designation, e.g. Teacher III',
                  icon: Icons.work_outline_rounded,
                ),
                validator: (v) {
                  if (_role != UserRole.teacher) return null;
                  return Validators.requiredField(v, label: 'Designation');
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: softInputDecoration(
                  hint: 'Subject or grade taught',
                  icon: Icons.menu_book_outlined,
                ),
              ),
              const SizedBox(height: 14),
              _teacherNotice(),
            ],

            const SizedBox(height: 22),
            _buildPrivacyConsent(),
            const SizedBox(height: 20),

            GradientButton(
              label: 'Create Account',
              onPressed: _handleRegister,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 24),
            _divider(),
            const SizedBox(height: 18),
            _buildLoginPrompt(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------- form pieces

  Widget _buildRoleSelector() {
    return Column(
      children: UserRole.values.map((role) {
        final selected = _role == role;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              _role = role;
              _errorMessage = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryTeal.withValues(alpha: 0.07)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryTeal
                      : const Color(0xFFE1E8E6),
                  width: selected ? 1.6 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    switch (role) {
                      UserRole.commuter => Icons.directions_bus_rounded,
                      UserRole.student => Icons.school_rounded,
                      UserRole.teacher => Icons.groups_rounded,
                    },
                    size: 22,
                    color: selected
                        ? AppColors.primaryTeal
                        : AppColors.textGrey,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primaryTeal
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.description,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: selected
                        ? AppColors.primaryTeal
                        : const Color(0xFFCBD5D2),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSchoolField() {
    final hasSelection = _selectedSchool != null || _schoolNotListed;
    final title =
        _selectedSchool?.name ??
        (_schoolNotListed ? 'My school is not listed' : 'Select your school');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _openSchoolPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelection
                ? AppColors.primaryTeal.withValues(alpha: 0.45)
                : const Color(0xFFE1E8E6),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 20,
              color: AppColors.textGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasSelection
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: hasSelection
                          ? AppColors.textDark
                          : AppColors.textGrey,
                    ),
                  ),
                  if (_selectedSchool != null &&
                      _selectedSchool!.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _selectedSchool!.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _teacherNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF9A7418)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Teacher accounts are reviewed before field trip hosting is '
              'enabled. Signing up with your official @deped.gov.ph address '
              'approves you automatically.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF7A5C12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyConsent() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() {
        _agreedToPrivacy = !_agreedToPrivacy;
        _errorMessage = null;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agreedToPrivacy,
                activeColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (v) => setState(() {
                  _agreedToPrivacy = v ?? false;
                  _errorMessage = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'I agree to HeritageLinc collecting the details above to verify '
                'my account, as described in the Data Privacy Notice. Learners '
                'under 18 should register with a parent or guardian present.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------- success sheet

  Widget _buildSuccessSheet() {
    final result = _result!;
    return _sheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _dragHandle()),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTeal.withValues(alpha: 0.10),
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 34,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Check your inbox',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a confirmation link to ${_emailCtrl.text.trim()}. '
            'Open it to activate your account, then come back and log in. '
            'Check your spam folder if it has not arrived in a few minutes.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textGrey,
            ),
          ),

          if (result.awaitsAdminApproval) ...[
            const SizedBox(height: 22),
            _teacherPendingNotice(),
          ],

          const SizedBox(height: 30),
          GradientButton(
            label: 'Go to Log In',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (route) => false,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () async {
                try {
                  await _authService.resendConfirmationEmail(_emailCtrl.text);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Confirmation email resent.')),
                  );
                } on AuthFailure catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
              child: const Text(
                'Resend confirmation email',
                style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherPendingNotice() {
    final isDeped = _emailCtrl.text.trim().toLowerCase().endsWith(
      '@deped.gov.ph',
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 19,
            color: Color(0xFF9A7418),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              isDeped
                  ? 'Your DepEd address will be verified the moment you confirm '
                        'your email, and field trip hosting unlocks right away.'
                  : 'Your teaching credentials are queued for review. You can '
                        'sign in and use the app now; field trip hosting unlocks '
                        'once an administrator approves your account.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Color(0xFF7A5C12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- small parts

  Widget _dragHandle() => Container(
    width: 42,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFFDDE5E3),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
    ),
  );

  Widget _divider() => Row(
    children: [
      const Expanded(child: Divider(color: Color(0xFFE8EEEC), thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
      const Expanded(child: Divider(color: Color(0xFFE8EEEC), thickness: 1)),
    ],
  );

  Widget _buildLoginPrompt() => Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          child: const Text(
            'Log in',
            style: TextStyle(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _errorBanner(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.20)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.danger,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

// =====================================================================
// School picker bottom sheet
// =====================================================================

class _SchoolPickResult {
  const _SchoolPickResult({this.school, this.notListed = false});
  final School? school;
  final bool notListed;
}

class _SchoolPickerSheet extends StatefulWidget {
  const _SchoolPickerSheet({required this.service});
  final SchoolService service;

  @override
  State<_SchoolPickerSheet> createState() => _SchoolPickerSheetState();
}

class _SchoolPickerSheetState extends State<_SchoolPickerSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<School> _results = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () => _run(value));
  }

  Future<void> _run(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await widget.service.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
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
                        'Select your school',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchCtrl,
                        autofocus: false,
                        onChanged: _onChanged,
                        decoration: softInputDecoration(
                          hint: 'Search by name',
                          icon: Icons.search_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEDF2F1)),
                Expanded(child: _buildBody(scrollController)),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(
                          context,
                          const _SchoolPickResult(notListed: true),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryTeal,
                          side: const BorderSide(color: Color(0xFFCBDDD9)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: const Text(
                          'My school is not listed',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ScrollController controller) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'No schools matched that search.\n'
            'Try a shorter word, or add yours below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, height: 1.5),
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
        final school = _results[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: const Icon(
            Icons.account_balance_outlined,
            color: AppColors.textGrey,
          ),
          title: Text(
            school.name,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: school.subtitle.isEmpty
              ? null
              : Text(
                  school.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
          onTap: () =>
              Navigator.pop(context, _SchoolPickResult(school: school)),
        );
      },
    );
  }
}